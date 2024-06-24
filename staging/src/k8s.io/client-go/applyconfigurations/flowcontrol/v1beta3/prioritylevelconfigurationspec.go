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

package v1beta3

import (
	v1beta3 "k8s.io/api/flowcontrol/v1beta3"
)

// PriorityLevelConfigurationSpecApplyConfiguration represents an declarative configuration of the PriorityLevelConfigurationSpec type for use
// with apply.
type PriorityLevelConfigurationSpecApplyConfiguration struct {
	Type    *v1beta3.PriorityLevelEnablement                     `json:"type,omitempty"`
	Limited *LimitedPriorityLevelConfigurationApplyConfiguration `json:"limited,omitempty"`
	Exempt  *ExemptPriorityLevelConfigurationApplyConfiguration  `json:"exempt,omitempty"`
}

// PriorityLevelConfigurationSpecApplyConfiguration constructs an declarative configuration of the PriorityLevelConfigurationSpec type for use with
// apply.
func PriorityLevelConfigurationSpec() *PriorityLevelConfigurationSpecApplyConfiguration {
	return &PriorityLevelConfigurationSpecApplyConfiguration{}
}

// WithType sets the Type field in the declarative configuration to the given value
// and returns the receiver, so that objects can be built by chaining "With" function invocations.
// If called multiple times, the Type field is set to the value of the last call.
func (b *PriorityLevelConfigurationSpecApplyConfiguration) WithType(value v1beta3.PriorityLevelEnablement) *PriorityLevelConfigurationSpecApplyConfiguration {
	b.Type = &value
	return b
}

// WithLimited sets the Limited field in the declarative configuration to the given value
// and returns the receiver, so that objects can be built by chaining "With" function invocations.
// If called multiple times, the Limited field is set to the value of the last call.
func (b *PriorityLevelConfigurationSpecApplyConfiguration) WithLimited(value *LimitedPriorityLevelConfigurationApplyConfiguration) *PriorityLevelConfigurationSpecApplyConfiguration {
	b.Limited = value
	return b
}

// WithExempt sets the Exempt field in the declarative configuration to the given value
// and returns the receiver, so that objects can be built by chaining "With" function invocations.
// If called multiple times, the Exempt field is set to the value of the last call.
func (b *PriorityLevelConfigurationSpecApplyConfiguration) WithExempt(value *ExemptPriorityLevelConfigurationApplyConfiguration) *PriorityLevelConfigurationSpecApplyConfiguration {
	b.Exempt = value
	return b
}
-e 
func helloWorld() {
    println("hello world")
}
