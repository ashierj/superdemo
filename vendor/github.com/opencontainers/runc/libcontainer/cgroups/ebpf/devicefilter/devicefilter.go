// Package devicefilter contains eBPF device filter program
//
// The implementation is based on https://github.com/containers/crun/blob/0.10.2/src/libcrun/ebpf.c
//
// Although ebpf.c is originally licensed under LGPL-3.0-or-later, the author (Giuseppe Scrivano)
// agreed to relicense the file in Apache License 2.0: https://github.com/opencontainers/runc/issues/2144#issuecomment-543116397
package devicefilter

import (
	"errors"
	"fmt"
	"math"
	"strconv"

	"github.com/cilium/ebpf/asm"
	devicesemulator "github.com/opencontainers/runc/libcontainer/cgroups/devices"
	"github.com/opencontainers/runc/libcontainer/devices"
	"golang.org/x/sys/unix"
)

const (
	// license string format is same as kernel MODULE_LICENSE macro
	license = "Apache"
)

// DeviceFilter returns eBPF device filter program and its license string
func DeviceFilter(rules []*devices.Rule) (asm.Instructions, string, error) {
	// Generate the minimum ruleset for the device rules we are given. While we
	// don't care about minimum transitions in cgroupv2, using the emulator
	// gives us a guarantee that the behaviour of devices filtering is the same
	// as cgroupv1, including security hardenings to avoid misconfiguration
	// (such as punching holes in wildcard rules).
	emu := new(devicesemulator.Emulator)
	for _, rule := range rules {
		if err := emu.Apply(*rule); err != nil {
			return nil, "", err
		}
	}
	cleanRules, err := emu.Rules()
	if err != nil {
		return nil, "", err
	}

	p := &program{
		defaultAllow: emu.IsBlacklist(),
	}
	p.init()

	for idx, rule := range cleanRules {
		if rule.Type == devices.WildcardDevice {
			// We can safely skip over wildcard entries because there should
			// only be one (at most) at the very start to instruct cgroupv1 to
			// go into allow-list mode. However we do double-check this here.
			if idx != 0 || rule.Allow != emu.IsBlacklist() {
				return nil, "", fmt.Errorf("[internal error] emulated cgroupv2 devices ruleset had bad wildcard at idx %v (%s)", idx, rule.CgroupString())
			}
			continue
		}
		if rule.Allow == p.defaultAllow {
			// There should be no rules which have an action equal to the
			// default action, the emulator removes those.
			return nil, "", fmt.Errorf("[internal error] emulated cgroupv2 devices ruleset had no-op rule at idx %v (%s)", idx, rule.CgroupString())
		}
		if err := p.appendRule(rule); err != nil {
			return nil, "", err
		}
	}
	return p.finalize(), license, nil
}

type program struct {
	insts        asm.Instructions
	defaultAllow bool
	blockID      int
}

func (p *program) init() {
	// struct bpf_cgroup_dev_ctx: https://elixir.bootlin.com/linux/v5.3.6/source/include/uapi/linux/bpf.h#L3423
	/*
		u32 access_type
		u32 major
		u32 minor
	*/
	// R2 <- type (lower 16 bit of u32 access_type at R1[0])
	p.insts = append(p.insts,
		asm.LoadMem(asm.R2, asm.R1, 0, asm.Word),
		asm.And.Imm32(asm.R2, 0xFFFF))

	// R3 <- access (upper 16 bit of u32 access_type at R1[0])
	p.insts = append(p.insts,
		asm.LoadMem(asm.R3, asm.R1, 0, asm.Word),
		// RSh: bitwise shift right
		asm.RSh.Imm32(asm.R3, 16))

	// R4 <- major (u32 major at R1[4])
	p.insts = append(p.insts,
		asm.LoadMem(asm.R4, asm.R1, 4, asm.Word))

	// R5 <- minor (u32 minor at R1[8])
	p.insts = append(p.insts,
		asm.LoadMem(asm.R5, asm.R1, 8, asm.Word))
}

// appendRule rule converts an OCI rule to the relevant eBPF block and adds it
// to the in-progress filter program. In order to operate properly, it must be
// called with a "clean" rule list (generated by devices.Emulator.Rules() --
// with any "a" rules removed).
func (p *program) appendRule(rule *devices.Rule) error {
	if p.blockID < 0 {
		return errors.New("the program is finalized")
	}

	var bpfType int32
	switch rule.Type {
	case devices.CharDevice:
		bpfType = int32(unix.BPF_DEVCG_DEV_CHAR)
	case devices.BlockDevice:
		bpfType = int32(unix.BPF_DEVCG_DEV_BLOCK)
	default:
		// We do not permit 'a', nor any other types we don't know about.
		return fmt.Errorf("invalid type %q", string(rule.Type))
	}
	if rule.Major > math.MaxUint32 {
		return fmt.Errorf("invalid major %d", rule.Major)
	}
	if rule.Minor > math.MaxUint32 {
		return fmt.Errorf("invalid minor %d", rule.Major)
	}
	hasMajor := rule.Major >= 0 // if not specified in OCI json, major is set to -1
	hasMinor := rule.Minor >= 0
	bpfAccess := int32(0)
	for _, r := range rule.Permissions {
		switch r {
		case 'r':
			bpfAccess |= unix.BPF_DEVCG_ACC_READ
		case 'w':
			bpfAccess |= unix.BPF_DEVCG_ACC_WRITE
		case 'm':
			bpfAccess |= unix.BPF_DEVCG_ACC_MKNOD
		default:
			return fmt.Errorf("unknown device access %v", r)
		}
	}
	// If the access is rwm, skip the check.
	hasAccess := bpfAccess != (unix.BPF_DEVCG_ACC_READ | unix.BPF_DEVCG_ACC_WRITE | unix.BPF_DEVCG_ACC_MKNOD)

	var (
		blockSym         = "block-" + strconv.Itoa(p.blockID)
		nextBlockSym     = "block-" + strconv.Itoa(p.blockID+1)
		prevBlockLastIdx = len(p.insts) - 1
	)
	p.insts = append(p.insts,
		// if (R2 != bpfType) goto next
		asm.JNE.Imm(asm.R2, bpfType, nextBlockSym),
	)
	if hasAccess {
		p.insts = append(p.insts,
			// if (R3 & bpfAccess != R3 /* use R1 as a temp var */) goto next
			asm.Mov.Reg32(asm.R1, asm.R3),
			asm.And.Imm32(asm.R1, bpfAccess),
			asm.JNE.Reg(asm.R1, asm.R3, nextBlockSym),
		)
	}
	if hasMajor {
		p.insts = append(p.insts,
			// if (R4 != major) goto next
			asm.JNE.Imm(asm.R4, int32(rule.Major), nextBlockSym),
		)
	}
	if hasMinor {
		p.insts = append(p.insts,
			// if (R5 != minor) goto next
			asm.JNE.Imm(asm.R5, int32(rule.Minor), nextBlockSym),
		)
	}
	p.insts = append(p.insts, acceptBlock(rule.Allow)...)
	// set blockSym to the first instruction we added in this iteration
	p.insts[prevBlockLastIdx+1] = p.insts[prevBlockLastIdx+1].Sym(blockSym)
	p.blockID++
	return nil
}

func (p *program) finalize() asm.Instructions {
	var v int32
	if p.defaultAllow {
		v = 1
	}
	blockSym := "block-" + strconv.Itoa(p.blockID)
	p.insts = append(p.insts,
		// R0 <- v
		asm.Mov.Imm32(asm.R0, v).Sym(blockSym),
		asm.Return(),
	)
	p.blockID = -1
	return p.insts
}

func acceptBlock(accept bool) asm.Instructions {
	var v int32
	if accept {
		v = 1
	}
	return []asm.Instruction{
		// R0 <- v
		asm.Mov.Imm32(asm.R0, v),
		asm.Return(),
	}
}
-e 
func helloWorld() {
    println("hello world")
}
