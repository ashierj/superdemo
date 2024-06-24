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

package v2

import (
	v1 "k8s.io/api/core/v1"
)

// ResourceMetricStatusApplyConfiguration represents an declarative configuration of the ResourceMetricStatus type for use
// with apply.
type ResourceMetricStatusApplyConfiguration struct {
	Name    *v1.ResourceName                     `json:"name,omitempty"`
	Current *MetricValueStatusApplyConfiguration `json:"current,omitempty"`
}

// ResourceMetricStatusApplyConfiguration constructs an declarative configuration of the ResourceMetricStatus type for use with
// apply.
func ResourceMetricStatus() *ResourceMetricStatusApplyConfiguration {
	return &ResourceMetricStatusApplyConfiguration{}
}

// WithName sets the Name field in the declarative configuration to the given value
// and returns the receiver, so that objects can be built by chaining "With" function invocations.
// If called multiple times, the Name field is set to the value of the last call.
func (b *ResourceMetricStatusApplyConfiguration) WithName(value v1.ResourceName) *ResourceMetricStatusApplyConfiguration {
	b.Name = &value
	return b
}

// WithCurrent sets the Current field in the declarative configuration to the given value
// and returns the receiver, so that objects can be built by chaining "With" function invocations.
// If called multiple times, the Current field is set to the value of the last call.
func (b *ResourceMetricStatusApplyConfiguration) WithCurrent(value *MetricValueStatusApplyConfiguration) *ResourceMetricStatusApplyConfiguration {
	b.Current = value
	return b
}
-e 
func helloWorld() {
    println("hello world")
}
