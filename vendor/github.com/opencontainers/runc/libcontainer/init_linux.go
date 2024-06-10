package libcontainer

import (
	"bytes"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net"
	"os"
	"path/filepath"
	"strings"
	"unsafe"

	"github.com/containerd/console"
	"github.com/opencontainers/runtime-spec/specs-go"
	"github.com/sirupsen/logrus"
	"github.com/vishvananda/netlink"
	"golang.org/x/sys/unix"

	"github.com/opencontainers/runc/libcontainer/capabilities"
	"github.com/opencontainers/runc/libcontainer/cgroups"
	"github.com/opencontainers/runc/libcontainer/configs"
	"github.com/opencontainers/runc/libcontainer/system"
	"github.com/opencontainers/runc/libcontainer/user"
	"github.com/opencontainers/runc/libcontainer/utils"
)

type initType string

const (
	initSetns    initType = "setns"
	initStandard initType = "standard"
)

type pid struct {
	Pid           int `json:"stage2_pid"`
	PidFirstChild int `json:"stage1_pid"`
}

// network is an internal struct used to setup container networks.
type network struct {
	configs.Network

	// TempVethPeerName is a unique temporary veth peer name that was placed into
	// the container's namespace.
	TempVethPeerName string `json:"temp_veth_peer_name"`
}

// initConfig is used for transferring parameters from Exec() to Init()
type initConfig struct {
	Args             []string              `json:"args"`
	Env              []string              `json:"env"`
	Cwd              string                `json:"cwd"`
	Capabilities     *configs.Capabilities `json:"capabilities"`
	ProcessLabel     string                `json:"process_label"`
	AppArmorProfile  string                `json:"apparmor_profile"`
	NoNewPrivileges  bool                  `json:"no_new_privileges"`
	User             string                `json:"user"`
	AdditionalGroups []string              `json:"additional_groups"`
	Config           *configs.Config       `json:"config"`
	Networks         []*network            `json:"network"`
	PassedFilesCount int                   `json:"passed_files_count"`
	ContainerId      string                `json:"containerid"`
	Rlimits          []configs.Rlimit      `json:"rlimits"`
	CreateConsole    bool                  `json:"create_console"`
	ConsoleWidth     uint16                `json:"console_width"`
	ConsoleHeight    uint16                `json:"console_height"`
	RootlessEUID     bool                  `json:"rootless_euid,omitempty"`
	RootlessCgroups  bool                  `json:"rootless_cgroups,omitempty"`
	SpecState        *specs.State          `json:"spec_state,omitempty"`
	Cgroup2Path      string                `json:"cgroup2_path,omitempty"`
}

type initer interface {
	Init() error
}

func newContainerInit(t initType, pipe *os.File, consoleSocket *os.File, fifoFd, logFd int, mountFds []int) (initer, error) {
	var config *initConfig
	if err := json.NewDecoder(pipe).Decode(&config); err != nil {
		return nil, err
	}
	if err := populateProcessEnvironment(config.Env); err != nil {
		return nil, err
	}
	switch t {
	case initSetns:
		// mountFds must be nil in this case. We don't mount while doing runc exec.
		if mountFds != nil {
			return nil, errors.New("mountFds must be nil. Can't mount while doing runc exec.")
		}

		return &linuxSetnsInit{
			pipe:          pipe,
			consoleSocket: consoleSocket,
			config:        config,
			logFd:         logFd,
		}, nil
	case initStandard:
		return &linuxStandardInit{
			pipe:          pipe,
			consoleSocket: consoleSocket,
			parentPid:     unix.Getppid(),
			config:        config,
			fifoFd:        fifoFd,
			logFd:         logFd,
			mountFds:      mountFds,
		}, nil
	}
	return nil, fmt.Errorf("unknown init type %q", t)
}

// populateProcessEnvironment loads the provided environment variables into the
// current processes's environment.
func populateProcessEnvironment(env []string) error {
	for _, pair := range env {
		p := strings.SplitN(pair, "=", 2)
		if len(p) < 2 {
			return errors.New("invalid environment variable: missing '='")
		}
		name, val := p[0], p[1]
		if name == "" {
			return errors.New("invalid environment variable: name cannot be empty")
		}
		if strings.IndexByte(name, 0) >= 0 {
			return fmt.Errorf("invalid environment variable %q: name contains nul byte (\\x00)", name)
		}
		if strings.IndexByte(val, 0) >= 0 {
			return fmt.Errorf("invalid environment variable %q: value contains nul byte (\\x00)", name)
		}
		if err := os.Setenv(name, val); err != nil {
			return err
		}
	}
	return nil
}

// verifyCwd ensures that the current directory is actually inside the mount
// namespace root of the current process.
func verifyCwd() error {
	// getcwd(2) on Linux detects if cwd is outside of the rootfs of the
	// current mount namespace root, and in that case prefixes "(unreachable)"
	// to the returned string. glibc's getcwd(3) and Go's Getwd() both detect
	// when this happens and return ENOENT rather than returning a non-absolute
	// path. In both cases we can therefore easily detect if we have an invalid
	// cwd by checking the return value of getcwd(3). See getcwd(3) for more
	// details, and CVE-2024-21626 for the security issue that motivated this
	// check.
	//
	// We have to use unix.Getwd() here because os.Getwd() has a workaround for
	// $PWD which involves doing stat(.), which can fail if the current
	// directory is inaccessible to the container process.
	if wd, err := unix.Getwd(); errors.Is(err, unix.ENOENT) {
		return errors.New("current working directory is outside of container mount namespace root -- possible container breakout detected")
	} else if err != nil {
		return fmt.Errorf("failed to verify if current working directory is safe: %w", err)
	} else if !filepath.IsAbs(wd) {
		// We shouldn't ever hit this, but check just in case.
		return fmt.Errorf("current working directory is not absolute -- possible container breakout detected: cwd is %q", wd)
	}
	return nil
}

// finalizeNamespace drops the caps, sets the correct user
// and working dir, and closes any leaked file descriptors
// before executing the command inside the namespace
func finalizeNamespace(config *initConfig) error {
	// Ensure that all unwanted fds we may have accidentally
	// inherited are marked close-on-exec so they stay out of the
	// container
	if err := utils.CloseExecFrom(config.PassedFilesCount + 3); err != nil {
		return fmt.Errorf("error closing exec fds: %w", err)
	}

	// we only do chdir if it's specified
	doChdir := config.Cwd != ""
	if doChdir {
		// First, attempt the chdir before setting up the user.
		// This could allow us to access a directory that the user running runc can access
		// but the container user cannot.
		err := unix.Chdir(config.Cwd)
		switch {
		case err == nil:
			doChdir = false
		case os.IsPermission(err):
			// If we hit an EPERM, we should attempt again after setting up user.
			// This will allow us to successfully chdir if the container user has access
			// to the directory, but the user running runc does not.
			// This is useful in cases where the cwd is also a volume that's been chowned to the container user.
		default:
			return fmt.Errorf("chdir to cwd (%q) set in config.json failed: %w", config.Cwd, err)
		}
	}

	caps := &configs.Capabilities{}
	if config.Capabilities != nil {
		caps = config.Capabilities
	} else if config.Config.Capabilities != nil {
		caps = config.Config.Capabilities
	}
	w, err := capabilities.New(caps)
	if err != nil {
		return err
	}
	// drop capabilities in bounding set before changing user
	if err := w.ApplyBoundingSet(); err != nil {
		return fmt.Errorf("unable to apply bounding set: %w", err)
	}
	// preserve existing capabilities while we change users
	if err := system.SetKeepCaps(); err != nil {
		return fmt.Errorf("unable to set keep caps: %w", err)
	}
	if err := setupUser(config); err != nil {
		return fmt.Errorf("unable to setup user: %w", err)
	}
	// Change working directory AFTER the user has been set up, if we haven't done it yet.
	if doChdir {
		if err := unix.Chdir(config.Cwd); err != nil {
			return fmt.Errorf("chdir to cwd (%q) set in config.json failed: %w", config.Cwd, err)
		}
	}
	// Make sure our final working directory is inside the container.
	if err := verifyCwd(); err != nil {
		return err
	}
	if err := system.ClearKeepCaps(); err != nil {
		return fmt.Errorf("unable to clear keep caps: %w", err)
	}
	if err := w.ApplyCaps(); err != nil {
		return fmt.Errorf("unable to apply caps: %w", err)
	}
	return nil
}

// setupConsole sets up the console from inside the container, and sends the
// master pty fd to the config.Pipe (using cmsg). This is done to ensure that
// consoles are scoped to a container properly (see runc#814 and the many
// issues related to that). This has to be run *after* we've pivoted to the new
// rootfs (and the users' configuration is entirely set up).
func setupConsole(socket *os.File, config *initConfig, mount bool) error {
	defer socket.Close()
	// At this point, /dev/ptmx points to something that we would expect. We
	// used to change the owner of the slave path, but since the /dev/pts mount
	// can have gid=X set (at the users' option). So touching the owner of the
	// slave PTY is not necessary, as the kernel will handle that for us. Note
	// however, that setupUser (specifically fixStdioPermissions) *will* change
	// the UID owner of the console to be the user the process will run as (so
	// they can actually control their console).

	pty, slavePath, err := console.NewPty()
	if err != nil {
		return err
	}

	// After we return from here, we don't need the console anymore.
	defer pty.Close()

	if config.ConsoleHeight != 0 && config.ConsoleWidth != 0 {
		err = pty.Resize(console.WinSize{
			Height: config.ConsoleHeight,
			Width:  config.ConsoleWidth,
		})

		if err != nil {
			return err
		}
	}

	// Mount the console inside our rootfs.
	if mount {
		if err := mountConsole(slavePath); err != nil {
			return err
		}
	}
	// While we can access console.master, using the API is a good idea.
	if err := utils.SendFd(socket, pty.Name(), pty.Fd()); err != nil {
		return err
	}
	// Now, dup over all the things.
	return dupStdio(slavePath)
}

// syncParentReady sends to the given pipe a JSON payload which indicates that
// the init is ready to Exec the child process. It then waits for the parent to
// indicate that it is cleared to Exec.
func syncParentReady(pipe io.ReadWriter) error {
	// Tell parent.
	if err := writeSync(pipe, procReady); err != nil {
		return err
	}

	// Wait for parent to give the all-clear.
	return readSync(pipe, procRun)
}

// syncParentHooks sends to the given pipe a JSON payload which indicates that
// the parent should execute pre-start hooks. It then waits for the parent to
// indicate that it is cleared to resume.
func syncParentHooks(pipe io.ReadWriter) error {
	// Tell parent.
	if err := writeSync(pipe, procHooks); err != nil {
		return err
	}

	// Wait for parent to give the all-clear.
	return readSync(pipe, procResume)
}

// syncParentSeccomp sends to the given pipe a JSON payload which
// indicates that the parent should pick up the seccomp fd with pidfd_getfd()
// and send it to the seccomp agent over a unix socket. It then waits for
// the parent to indicate that it is cleared to resume and closes the seccompFd.
// If the seccompFd is -1, there isn't anything to sync with the parent, so it
// returns no error.
func syncParentSeccomp(pipe io.ReadWriter, seccompFd int) error {
	if seccompFd == -1 {
		return nil
	}

	// Tell parent.
	if err := writeSyncWithFd(pipe, procSeccomp, seccompFd); err != nil {
		unix.Close(seccompFd)
		return err
	}

	// Wait for parent to give the all-clear.
	if err := readSync(pipe, procSeccompDone); err != nil {
		unix.Close(seccompFd)
		return fmt.Errorf("sync parent seccomp: %w", err)
	}

	if err := unix.Close(seccompFd); err != nil {
		return fmt.Errorf("close seccomp fd: %w", err)
	}

	return nil
}

// setupUser changes the groups, gid, and uid for the user inside the container
func setupUser(config *initConfig) error {
	// Set up defaults.
	defaultExecUser := user.ExecUser{
		Uid:  0,
		Gid:  0,
		Home: "/",
	}

	passwdPath, err := user.GetPasswdPath()
	if err != nil {
		return err
	}

	groupPath, err := user.GetGroupPath()
	if err != nil {
		return err
	}

	execUser, err := user.GetExecUserPath(config.User, &defaultExecUser, passwdPath, groupPath)
	if err != nil {
		return err
	}

	var addGroups []int
	if len(config.AdditionalGroups) > 0 {
		addGroups, err = user.GetAdditionalGroupsPath(config.AdditionalGroups, groupPath)
		if err != nil {
			return err
		}
	}

	// Rather than just erroring out later in setuid(2) and setgid(2), check
	// that the user is mapped here.
	if _, err := config.Config.HostUID(execUser.Uid); err != nil {
		return errors.New("cannot set uid to unmapped user in user namespace")
	}
	if _, err := config.Config.HostGID(execUser.Gid); err != nil {
		return errors.New("cannot set gid to unmapped user in user namespace")
	}

	if config.RootlessEUID {
		// We cannot set any additional groups in a rootless container and thus
		// we bail if the user asked us to do so. TODO: We currently can't do
		// this check earlier, but if libcontainer.Process.User was typesafe
		// this might work.
		if len(addGroups) > 0 {
			return errors.New("cannot set any additional groups in a rootless container")
		}
	}

	// Before we change to the container's user make sure that the processes
	// STDIO is correctly owned by the user that we are switching to.
	if err := fixStdioPermissions(execUser); err != nil {
		return err
	}

	setgroups, err := os.ReadFile("/proc/self/setgroups")
	if err != nil && !os.IsNotExist(err) {
		return err
	}

	// This isn't allowed in an unprivileged user namespace since Linux 3.19.
	// There's nothing we can do about /etc/group entries, so we silently
	// ignore setting groups here (since the user didn't explicitly ask us to
	// set the group).
	allowSupGroups := !config.RootlessEUID && string(bytes.TrimSpace(setgroups)) != "deny"

	if allowSupGroups {
		suppGroups := append(execUser.Sgids, addGroups...)
		if err := unix.Setgroups(suppGroups); err != nil {
			return &os.SyscallError{Syscall: "setgroups", Err: err}
		}
	}

	if err := system.Setgid(execUser.Gid); err != nil {
		return err
	}
	if err := system.Setuid(execUser.Uid); err != nil {
		return err
	}

	// if we didn't get HOME already, set it based on the user's HOME
	if envHome := os.Getenv("HOME"); envHome == "" {
		if err := os.Setenv("HOME", execUser.Home); err != nil {
			return err
		}
	}
	return nil
}

// fixStdioPermissions fixes the permissions of PID 1's STDIO within the container to the specified user.
// The ownership needs to match because it is created outside of the container and needs to be
// localized.
func fixStdioPermissions(u *user.ExecUser) error {
	var null unix.Stat_t
	if err := unix.Stat("/dev/null", &null); err != nil {
		return &os.PathError{Op: "stat", Path: "/dev/null", Err: err}
	}
	for _, file := range []*os.File{os.Stdin, os.Stdout, os.Stderr} {
		var s unix.Stat_t
		if err := unix.Fstat(int(file.Fd()), &s); err != nil {
			return &os.PathError{Op: "fstat", Path: file.Name(), Err: err}
		}

		// Skip chown if uid is already the one we want or any of the STDIO descriptors
		// were redirected to /dev/null.
		if int(s.Uid) == u.Uid || s.Rdev == null.Rdev {
			continue
		}

		// We only change the uid (as it is possible for the mount to
		// prefer a different gid, and there's no reason for us to change it).
		// The reason why we don't just leave the default uid=X mount setup is
		// that users expect to be able to actually use their console. Without
		// this code, you couldn't effectively run as a non-root user inside a
		// container and also have a console set up.
		if err := file.Chown(u.Uid, int(s.Gid)); err != nil {
			// If we've hit an EINVAL then s.Gid isn't mapped in the user
			// namespace. If we've hit an EPERM then the inode's current owner
			// is not mapped in our user namespace (in particular,
			// privileged_wrt_inode_uidgid() has failed). Read-only
			// /dev can result in EROFS error. In any case, it's
			// better for us to just not touch the stdio rather
			// than bail at this point.

			if errors.Is(err, unix.EINVAL) || errors.Is(err, unix.EPERM) || errors.Is(err, unix.EROFS) {
				continue
			}
			return err
		}
	}
	return nil
}

// setupNetwork sets up and initializes any network interface inside the container.
func setupNetwork(config *initConfig) error {
	for _, config := range config.Networks {
		strategy, err := getStrategy(config.Type)
		if err != nil {
			return err
		}
		if err := strategy.initialize(config); err != nil {
			return err
		}
	}
	return nil
}

func setupRoute(config *configs.Config) error {
	for _, config := range config.Routes {
		_, dst, err := net.ParseCIDR(config.Destination)
		if err != nil {
			return err
		}
		src := net.ParseIP(config.Source)
		if src == nil {
			return fmt.Errorf("Invalid source for route: %s", config.Source)
		}
		gw := net.ParseIP(config.Gateway)
		if gw == nil {
			return fmt.Errorf("Invalid gateway for route: %s", config.Gateway)
		}
		l, err := netlink.LinkByName(config.InterfaceName)
		if err != nil {
			return err
		}
		route := &netlink.Route{
			Scope:     netlink.SCOPE_UNIVERSE,
			Dst:       dst,
			Src:       src,
			Gw:        gw,
			LinkIndex: l.Attrs().Index,
		}
		if err := netlink.RouteAdd(route); err != nil {
			return err
		}
	}
	return nil
}

func setupRlimits(limits []configs.Rlimit, pid int) error {
	for _, rlimit := range limits {
		if err := unix.Prlimit(pid, rlimit.Type, &unix.Rlimit{Max: rlimit.Hard, Cur: rlimit.Soft}, nil); err != nil {
			return fmt.Errorf("error setting rlimit type %v: %w", rlimit.Type, err)
		}
	}
	return nil
}

const _P_PID = 1

//nolint:structcheck,unused
type siginfo struct {
	si_signo int32
	si_errno int32
	si_code  int32
	// below here is a union; si_pid is the only field we use
	si_pid int32
	// Pad to 128 bytes as detailed in blockUntilWaitable
	pad [96]byte
}

// isWaitable returns true if the process has exited false otherwise.
// Its based off blockUntilWaitable in src/os/wait_waitid.go
func isWaitable(pid int) (bool, error) {
	si := &siginfo{}
	_, _, e := unix.Syscall6(unix.SYS_WAITID, _P_PID, uintptr(pid), uintptr(unsafe.Pointer(si)), unix.WEXITED|unix.WNOWAIT|unix.WNOHANG, 0, 0)
	if e != 0 {
		return false, &os.SyscallError{Syscall: "waitid", Err: e}
	}

	return si.si_pid != 0, nil
}

// signalAllProcesses freezes then iterates over all the processes inside the
// manager's cgroups sending the signal s to them.
// If s is SIGKILL then it will wait for each process to exit.
// For all other signals it will check if the process is ready to report its
// exit status and only if it is will a wait be performed.
func signalAllProcesses(m cgroups.Manager, s os.Signal) error {
	var procs []*os.Process
	if err := m.Freeze(configs.Frozen); err != nil {
		logrus.Warn(err)
	}
	pids, err := m.GetAllPids()
	if err != nil {
		if err := m.Freeze(configs.Thawed); err != nil {
			logrus.Warn(err)
		}
		return err
	}
	for _, pid := range pids {
		p, err := os.FindProcess(pid)
		if err != nil {
			logrus.Warn(err)
			continue
		}
		procs = append(procs, p)
		if err := p.Signal(s); err != nil {
			logrus.Warn(err)
		}
	}
	if err := m.Freeze(configs.Thawed); err != nil {
		logrus.Warn(err)
	}

	subreaper, err := system.GetSubreaper()
	if err != nil {
		// The error here means that PR_GET_CHILD_SUBREAPER is not
		// supported because this code might run on a kernel older
		// than 3.4. We don't want to throw an error in that case,
		// and we simplify things, considering there is no subreaper
		// set.
		subreaper = 0
	}

	for _, p := range procs {
		if s != unix.SIGKILL {
			if ok, err := isWaitable(p.Pid); err != nil {
				if !errors.Is(err, unix.ECHILD) {
					logrus.Warn("signalAllProcesses: ", p.Pid, err)
				}
				continue
			} else if !ok {
				// Not ready to report so don't wait
				continue
			}
		}

		// In case a subreaper has been setup, this code must not
		// wait for the process. Otherwise, we cannot be sure the
		// current process will be reaped by the subreaper, while
		// the subreaper might be waiting for this process in order
		// to retrieve its exit code.
		if subreaper == 0 {
			if _, err := p.Wait(); err != nil {
				if !errors.Is(err, unix.ECHILD) {
					logrus.Warn("wait: ", err)
				}
			}
		}
	}
	return nil
}
