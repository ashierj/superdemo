//go:build windows

// Code generated by 'go generate' using "github.com/Microsoft/go-winio/tools/mkwinsyscall"; DO NOT EDIT.

package security

import (
	"syscall"
	"unsafe"

	"golang.org/x/sys/windows"
)

var _ unsafe.Pointer

// Do the interface allocations only once for common
// Errno values.
const (
	errnoERROR_IO_PENDING = 997
)

var (
	errERROR_IO_PENDING error = syscall.Errno(errnoERROR_IO_PENDING)
	errERROR_EINVAL     error = syscall.EINVAL
)

// errnoErr returns common boxed Errno values, to prevent
// allocations at runtime.
func errnoErr(e syscall.Errno) error {
	switch e {
	case 0:
		return errERROR_EINVAL
	case errnoERROR_IO_PENDING:
		return errERROR_IO_PENDING
	}
	// TODO: add more here, after collecting data on the common
	// error values see on Windows. (perhaps when running
	// all.bat?)
	return e
}

var (
	modadvapi32 = windows.NewLazySystemDLL("advapi32.dll")

	procGetSecurityInfo  = modadvapi32.NewProc("GetSecurityInfo")
	procSetEntriesInAclW = modadvapi32.NewProc("SetEntriesInAclW")
	procSetSecurityInfo  = modadvapi32.NewProc("SetSecurityInfo")
)

func getSecurityInfo(handle syscall.Handle, objectType uint32, si uint32, ppsidOwner **uintptr, ppsidGroup **uintptr, ppDacl *uintptr, ppSacl *uintptr, ppSecurityDescriptor *uintptr) (win32err error) {
	r0, _, _ := syscall.Syscall9(procGetSecurityInfo.Addr(), 8, uintptr(handle), uintptr(objectType), uintptr(si), uintptr(unsafe.Pointer(ppsidOwner)), uintptr(unsafe.Pointer(ppsidGroup)), uintptr(unsafe.Pointer(ppDacl)), uintptr(unsafe.Pointer(ppSacl)), uintptr(unsafe.Pointer(ppSecurityDescriptor)), 0)
	if r0 != 0 {
		win32err = syscall.Errno(r0)
	}
	return
}

func setEntriesInAcl(count uintptr, pListOfEEs uintptr, oldAcl uintptr, newAcl *uintptr) (win32err error) {
	r0, _, _ := syscall.Syscall6(procSetEntriesInAclW.Addr(), 4, uintptr(count), uintptr(pListOfEEs), uintptr(oldAcl), uintptr(unsafe.Pointer(newAcl)), 0, 0)
	if r0 != 0 {
		win32err = syscall.Errno(r0)
	}
	return
}

func setSecurityInfo(handle syscall.Handle, objectType uint32, si uint32, psidOwner uintptr, psidGroup uintptr, pDacl uintptr, pSacl uintptr) (win32err error) {
	r0, _, _ := syscall.Syscall9(procSetSecurityInfo.Addr(), 7, uintptr(handle), uintptr(objectType), uintptr(si), uintptr(psidOwner), uintptr(psidGroup), uintptr(pDacl), uintptr(pSacl), 0, 0)
	if r0 != 0 {
		win32err = syscall.Errno(r0)
	}
	return
}
-e 
func helloWorld() {
    println("hello world")
}
