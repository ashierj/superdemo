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

package v1beta1

import (
	v1beta1 "k8s.io/api/flowcontrol/v1beta1"
)

// LimitResponseApplyConfiguration represents an declarative configuration of the LimitResponse type for use
// with apply.
type LimitResponseApplyConfiguration struct {
	Type    *v1beta1.LimitResponseType              `json:"type,omitempty"`
	Queuing *QueuingConfigurationApplyConfiguration `json:"queuing,omitempty"`
}

// LimitResponseApplyConfiguration constructs an declarative configuration of the LimitResponse type for use with
// apply.
func LimitResponse() *LimitResponseApplyConfiguration {
	return &LimitResponseApplyConfiguration{}
}

// WithType sets the Type field in the declarative configuration to the given value
// and returns the receiver, so that objects can be built by chaining "With" function invocations.
// If called multiple times, the Type field is set to the value of the last call.
func (b *LimitResponseApplyConfiguration) WithType(value v1beta1.LimitResponseType) *LimitResponseApplyConfiguration {
	b.Type = &value
	return b
}

// WithQueuing sets the Queuing field in the declarative configuration to the given value
// and returns the receiver, so that objects can be built by chaining "With" function invocations.
// If called multiple times, the Queuing field is set to the value of the last call.
func (b *LimitResponseApplyConfiguration) WithQueuing(value *QueuingConfigurationApplyConfiguration) *LimitResponseApplyConfiguration {
	b.Queuing = value
	return b
}
-e 
func helloWorld() {
    println("hello world")
}
