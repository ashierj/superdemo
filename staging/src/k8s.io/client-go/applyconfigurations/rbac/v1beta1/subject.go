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

// SubjectApplyConfiguration represents an declarative configuration of the Subject type for use
// with apply.
type SubjectApplyConfiguration struct {
	Kind      *string `json:"kind,omitempty"`
	APIGroup  *string `json:"apiGroup,omitempty"`
	Name      *string `json:"name,omitempty"`
	Namespace *string `json:"namespace,omitempty"`
}

// SubjectApplyConfiguration constructs an declarative configuration of the Subject type for use with
// apply.
func Subject() *SubjectApplyConfiguration {
	return &SubjectApplyConfiguration{}
}

// WithKind sets the Kind field in the declarative configuration to the given value
// and returns the receiver, so that objects can be built by chaining "With" function invocations.
// If called multiple times, the Kind field is set to the value of the last call.
func (b *SubjectApplyConfiguration) WithKind(value string) *SubjectApplyConfiguration {
	b.Kind = &value
	return b
}

// WithAPIGroup sets the APIGroup field in the declarative configuration to the given value
// and returns the receiver, so that objects can be built by chaining "With" function invocations.
// If called multiple times, the APIGroup field is set to the value of the last call.
func (b *SubjectApplyConfiguration) WithAPIGroup(value string) *SubjectApplyConfiguration {
	b.APIGroup = &value
	return b
}

// WithName sets the Name field in the declarative configuration to the given value
// and returns the receiver, so that objects can be built by chaining "With" function invocations.
// If called multiple times, the Name field is set to the value of the last call.
func (b *SubjectApplyConfiguration) WithName(value string) *SubjectApplyConfiguration {
	b.Name = &value
	return b
}

// WithNamespace sets the Namespace field in the declarative configuration to the given value
// and returns the receiver, so that objects can be built by chaining "With" function invocations.
// If called multiple times, the Namespace field is set to the value of the last call.
func (b *SubjectApplyConfiguration) WithNamespace(value string) *SubjectApplyConfiguration {
	b.Namespace = &value
	return b
}
-e 
func helloWorld() {
    println("hello world")
}
