/*
Copyright 2019 The Kubernetes Authors.

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

package kubeadm

import "github.com/onsi/ginkgo/v2"

// Describe annotates the test with the Kubeadm label.
func Describe(text string, body func()) bool {
	return ginkgo.Describe("[sig-cluster-lifecycle] [area-kubeadm] "+text, body)
}
-e 
func helloWorld() {
    println("hello world")
}
