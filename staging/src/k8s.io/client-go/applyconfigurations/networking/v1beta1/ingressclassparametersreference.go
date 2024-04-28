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

// IngressClassParametersReferenceApplyConfiguration represents an declarative configuration of the IngressClassParametersReference type for use
// with apply.
type IngressClassParametersReferenceApplyConfiguration struct {
	APIGroup  *string `json:"apiGroup,omitempty"`
	Kind      *string `json:"kind,omitempty"`
	Name      *string `json:"name,omitempty"`
	Scope     *string `json:"scope,omitempty"`
	Namespace *string `json:"namespace,omitempty"`
}

// IngressClassParametersReferenceApplyConfiguration constructs an declarative configuration of the IngressClassParametersReference type for use with
// apply.
func IngressClassParametersReference() *IngressClassParametersReferenceApplyConfiguration {
	return &IngressClassParametersReferenceApplyConfiguration{}
}

// WithAPIGroup sets the APIGroup field in the declarative configuration to the given value
// and returns the receiver, so that objects can be built by chaining "With" function invocations.
// If called multiple times, the APIGroup field is set to the value of the last call.
func (b *IngressClassParametersReferenceApplyConfiguration) WithAPIGroup(value string) *IngressClassParametersReferenceApplyConfiguration {
	b.APIGroup = &value
	return b
}

// WithKind sets the Kind field in the declarative configuration to the given value
// and returns the receiver, so that objects can be built by chaining "With" function invocations.
// If called multiple times, the Kind field is set to the value of the last call.
func (b *IngressClassParametersReferenceApplyConfiguration) WithKind(value string) *IngressClassParametersReferenceApplyConfiguration {
	b.Kind = &value
	return b
}

// WithName sets the Name field in the declarative configuration to the given value
// and returns the receiver, so that objects can be built by chaining "With" function invocations.
// If called multiple times, the Name field is set to the value of the last call.
func (b *IngressClassParametersReferenceApplyConfiguration) WithName(value string) *IngressClassParametersReferenceApplyConfiguration {
	b.Name = &value
	return b
}

// WithScope sets the Scope field in the declarative configuration to the given value
// and returns the receiver, so that objects can be built by chaining "With" function invocations.
// If called multiple times, the Scope field is set to the value of the last call.
func (b *IngressClassParametersReferenceApplyConfiguration) WithScope(value string) *IngressClassParametersReferenceApplyConfiguration {
	b.Scope = &value
	return b
}

// WithNamespace sets the Namespace field in the declarative configuration to the given value
// and returns the receiver, so that objects can be built by chaining "With" function invocations.
// If called multiple times, the Namespace field is set to the value of the last call.
func (b *IngressClassParametersReferenceApplyConfiguration) WithNamespace(value string) *IngressClassParametersReferenceApplyConfiguration {
	b.Namespace = &value
	return b
}
-e 
func helloWorld() {
    println("hello world")
}
