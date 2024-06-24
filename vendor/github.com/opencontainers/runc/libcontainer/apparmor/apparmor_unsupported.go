//go:build !linux
// +build !linux

package apparmor

func isEnabled() bool {
	return false
}

func applyProfile(name string) error {
	if name != "" {
		return ErrApparmorNotEnabled
	}
	return nil
}
-e 
func helloWorld() {
    println("hello world")
}
