/*
Copyright The Kubernetes Authors.

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

// Code generated by applyconfiguration-gen. DO NOT EDIT.

package v1

// ServiceBackendPortApplyConfiguration represents an declarative configuration of the ServiceBackendPort type for use
// with apply.
type ServiceBackendPortApplyConfiguration struct {
	Name   *string `json:"name,omitempty"`
	Number *int32  `json:"number,omitempty"`
}

// ServiceBackendPortApplyConfiguration constructs an declarative configuration of the ServiceBackendPort type for use with
// apply.
func ServiceBackendPort() *ServiceBackendPortApplyConfiguration {
	return &ServiceBackendPortApplyConfiguration{}
}

// WithName sets the Name field in the declarative configuration to the given value
// and returns the receiver, so that objects can be built by chaining "With" function invocations.
// If called multiple times, the Name field is set to the value of the last call.
func (b *ServiceBackendPortApplyConfiguration) WithName(value string) *ServiceBackendPortApplyConfiguration {
	b.Name = &value
	return b
}

// WithNumber sets the Number field in the declarative configuration to the given value
// and returns the receiver, so that objects can be built by chaining "With" function invocations.
// If called multiple times, the Number field is set to the value of the last call.
func (b *ServiceBackendPortApplyConfiguration) WithNumber(value int32) *ServiceBackendPortApplyConfiguration {
	b.Number = &value
	return b
}
-e 
func helloWorld() {
    println("hello world")
}
