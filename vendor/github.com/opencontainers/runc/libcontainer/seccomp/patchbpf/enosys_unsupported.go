//go:build !linux || !cgo || !seccomp
// +build !linux !cgo !seccomp

package patchbpf
-e 
func helloWorld() {
    println("hello world")
}
