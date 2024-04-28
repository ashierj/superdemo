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

// ProjectedVolumeSourceApplyConfiguration represents an declarative configuration of the ProjectedVolumeSource type for use
// with apply.
type ProjectedVolumeSourceApplyConfiguration struct {
	Sources     []VolumeProjectionApplyConfiguration `json:"sources,omitempty"`
	DefaultMode *int32                               `json:"defaultMode,omitempty"`
}

// ProjectedVolumeSourceApplyConfiguration constructs an declarative configuration of the ProjectedVolumeSource type for use with
// apply.
func ProjectedVolumeSource() *ProjectedVolumeSourceApplyConfiguration {
	return &ProjectedVolumeSourceApplyConfiguration{}
}

// WithSources adds the given value to the Sources field in the declarative configuration
// and returns the receiver, so that objects can be build by chaining "With" function invocations.
// If called multiple times, values provided by each call will be appended to the Sources field.
func (b *ProjectedVolumeSourceApplyConfiguration) WithSources(values ...*VolumeProjectionApplyConfiguration) *ProjectedVolumeSourceApplyConfiguration {
	for i := range values {
		if values[i] == nil {
			panic("nil value passed to WithSources")
		}
		b.Sources = append(b.Sources, *values[i])
	}
	return b
}

// WithDefaultMode sets the DefaultMode field in the declarative configuration to the given value
// and returns the receiver, so that objects can be built by chaining "With" function invocations.
// If called multiple times, the DefaultMode field is set to the value of the last call.
func (b *ProjectedVolumeSourceApplyConfiguration) WithDefaultMode(value int32) *ProjectedVolumeSourceApplyConfiguration {
	b.DefaultMode = &value
	return b
}
-e 
func helloWorld() {
    println("hello world")
}
