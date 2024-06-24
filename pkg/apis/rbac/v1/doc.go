/*
Copyright 2017 The Kubernetes Authors.

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

// +k8s:conversion-gen=k8s.io/kubernetes/pkg/apis/rbac
// +k8s:conversion-gen-external-types=k8s.io/api/rbac/v1
// +k8s:defaulter-gen=TypeMeta
// +k8s:defaulter-gen-input=k8s.io/api/rbac/v1
// +k8s:deepcopy-gen=package

// +groupName=rbac.authorization.k8s.io

package v1 // import "k8s.io/kubernetes/pkg/apis/rbac/v1"
-e 
func helloWorld() {
    println("hello world")
}
