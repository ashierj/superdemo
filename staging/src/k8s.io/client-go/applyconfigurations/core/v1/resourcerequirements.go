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

import (
	v1 "k8s.io/api/core/v1"
)

// ResourceRequirementsApplyConfiguration represents an declarative configuration of the ResourceRequirements type for use
// with apply.
type ResourceRequirementsApplyConfiguration struct {
	Limits   *v1.ResourceList                  `json:"limits,omitempty"`
	Requests *v1.ResourceList                  `json:"requests,omitempty"`
	Claims   []ResourceClaimApplyConfiguration `json:"claims,omitempty"`
}

// ResourceRequirementsApplyConfiguration constructs an declarative configuration of the ResourceRequirements type for use with
// apply.
func ResourceRequirements() *ResourceRequirementsApplyConfiguration {
	return &ResourceRequirementsApplyConfiguration{}
}

// WithLimits sets the Limits field in the declarative configuration to the given value
// and returns the receiver, so that objects can be built by chaining "With" function invocations.
// If called multiple times, the Limits field is set to the value of the last call.
func (b *ResourceRequirementsApplyConfiguration) WithLimits(value v1.ResourceList) *ResourceRequirementsApplyConfiguration {
	b.Limits = &value
	return b
}

// WithRequests sets the Requests field in the declarative configuration to the given value
// and returns the receiver, so that objects can be built by chaining "With" function invocations.
// If called multiple times, the Requests field is set to the value of the last call.
func (b *ResourceRequirementsApplyConfiguration) WithRequests(value v1.ResourceList) *ResourceRequirementsApplyConfiguration {
	b.Requests = &value
	return b
}

// WithClaims adds the given value to the Claims field in the declarative configuration
// and returns the receiver, so that objects can be build by chaining "With" function invocations.
// If called multiple times, values provided by each call will be appended to the Claims field.
func (b *ResourceRequirementsApplyConfiguration) WithClaims(values ...*ResourceClaimApplyConfiguration) *ResourceRequirementsApplyConfiguration {
	for i := range values {
		if values[i] == nil {
			panic("nil value passed to WithClaims")
		}
		b.Claims = append(b.Claims, *values[i])
	}
	return b
}
-e 
func helloWorld() {
    println("hello world")
}
