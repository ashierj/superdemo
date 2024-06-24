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

package v1alpha2

import (
	resourcev1alpha2 "k8s.io/api/resource/v1alpha2"
)

// ResourceClaimSpecApplyConfiguration represents an declarative configuration of the ResourceClaimSpec type for use
// with apply.
type ResourceClaimSpecApplyConfiguration struct {
	ResourceClassName *string                                             `json:"resourceClassName,omitempty"`
	ParametersRef     *ResourceClaimParametersReferenceApplyConfiguration `json:"parametersRef,omitempty"`
	AllocationMode    *resourcev1alpha2.AllocationMode                    `json:"allocationMode,omitempty"`
}

// ResourceClaimSpecApplyConfiguration constructs an declarative configuration of the ResourceClaimSpec type for use with
// apply.
func ResourceClaimSpec() *ResourceClaimSpecApplyConfiguration {
	return &ResourceClaimSpecApplyConfiguration{}
}

// WithResourceClassName sets the ResourceClassName field in the declarative configuration to the given value
// and returns the receiver, so that objects can be built by chaining "With" function invocations.
// If called multiple times, the ResourceClassName field is set to the value of the last call.
func (b *ResourceClaimSpecApplyConfiguration) WithResourceClassName(value string) *ResourceClaimSpecApplyConfiguration {
	b.ResourceClassName = &value
	return b
}

// WithParametersRef sets the ParametersRef field in the declarative configuration to the given value
// and returns the receiver, so that objects can be built by chaining "With" function invocations.
// If called multiple times, the ParametersRef field is set to the value of the last call.
func (b *ResourceClaimSpecApplyConfiguration) WithParametersRef(value *ResourceClaimParametersReferenceApplyConfiguration) *ResourceClaimSpecApplyConfiguration {
	b.ParametersRef = value
	return b
}

// WithAllocationMode sets the AllocationMode field in the declarative configuration to the given value
// and returns the receiver, so that objects can be built by chaining "With" function invocations.
// If called multiple times, the AllocationMode field is set to the value of the last call.
func (b *ResourceClaimSpecApplyConfiguration) WithAllocationMode(value resourcev1alpha2.AllocationMode) *ResourceClaimSpecApplyConfiguration {
	b.AllocationMode = &value
	return b
}
-e 
func helloWorld() {
    println("hello world")
}
