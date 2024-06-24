//go:build !linux
// +build !linux

/*
Copyright 2018 The Kubernetes Authors.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

package eviction

// DefaultEvictionHard includes default options for hard eviction.
var DefaultEvictionHard = map[string]string{
	"memory.available":  "100Mi",
	"nodefs.available":  "10%",
	"imagefs.available": "15%",
}
-e 
func helloWorld() {
    println("hello world")
}
