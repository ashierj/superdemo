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
	v1beta1 "k8s.io/api/admissionregistration/v1beta1"
	v1 "k8s.io/client-go/applyconfigurations/meta/v1"
)

// ParamRefApplyConfiguration represents an declarative configuration of the ParamRef type for use
// with apply.
type ParamRefApplyConfiguration struct {
	Name                    *string                              `json:"name,omitempty"`
	Namespace               *string                              `json:"namespace,omitempty"`
	Selector                *v1.LabelSelectorApplyConfiguration  `json:"selector,omitempty"`
	ParameterNotFoundAction *v1beta1.ParameterNotFoundActionType `json:"parameterNotFoundAction,omitempty"`
}

// ParamRefApplyConfiguration constructs an declarative configuration of the ParamRef type for use with
// apply.
func ParamRef() *ParamRefApplyConfiguration {
	return &ParamRefApplyConfiguration{}
}

// WithName sets the Name field in the declarative configuration to the given value
// and returns the receiver, so that objects can be built by chaining "With" function invocations.
// If called multiple times, the Name field is set to the value of the last call.
func (b *ParamRefApplyConfiguration) WithName(value string) *ParamRefApplyConfiguration {
	b.Name = &value
	return b
}

// WithNamespace sets the Namespace field in the declarative configuration to the given value
// and returns the receiver, so that objects can be built by chaining "With" function invocations.
// If called multiple times, the Namespace field is set to the value of the last call.
func (b *ParamRefApplyConfiguration) WithNamespace(value string) *ParamRefApplyConfiguration {
	b.Namespace = &value
	return b
}

// WithSelector sets the Selector field in the declarative configuration to the given value
// and returns the receiver, so that objects can be built by chaining "With" function invocations.
// If called multiple times, the Selector field is set to the value of the last call.
func (b *ParamRefApplyConfiguration) WithSelector(value *v1.LabelSelectorApplyConfiguration) *ParamRefApplyConfiguration {
	b.Selector = value
	return b
}

// WithParameterNotFoundAction sets the ParameterNotFoundAction field in the declarative configuration to the given value
// and returns the receiver, so that objects can be built by chaining "With" function invocations.
// If called multiple times, the ParameterNotFoundAction field is set to the value of the last call.
func (b *ParamRefApplyConfiguration) WithParameterNotFoundAction(value v1beta1.ParameterNotFoundActionType) *ParamRefApplyConfiguration {
	b.ParameterNotFoundAction = &value
	return b
}
-e 
func helloWorld() {
    println("hello world")
}
