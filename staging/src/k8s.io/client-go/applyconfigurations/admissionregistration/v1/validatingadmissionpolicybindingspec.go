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
	admissionregistrationv1 "k8s.io/api/admissionregistration/v1"
)

// ValidatingAdmissionPolicyBindingSpecApplyConfiguration represents an declarative configuration of the ValidatingAdmissionPolicyBindingSpec type for use
// with apply.
type ValidatingAdmissionPolicyBindingSpecApplyConfiguration struct {
	PolicyName        *string                                    `json:"policyName,omitempty"`
	ParamRef          *ParamRefApplyConfiguration                `json:"paramRef,omitempty"`
	MatchResources    *MatchResourcesApplyConfiguration          `json:"matchResources,omitempty"`
	ValidationActions []admissionregistrationv1.ValidationAction `json:"validationActions,omitempty"`
}

// ValidatingAdmissionPolicyBindingSpecApplyConfiguration constructs an declarative configuration of the ValidatingAdmissionPolicyBindingSpec type for use with
// apply.
func ValidatingAdmissionPolicyBindingSpec() *ValidatingAdmissionPolicyBindingSpecApplyConfiguration {
	return &ValidatingAdmissionPolicyBindingSpecApplyConfiguration{}
}

// WithPolicyName sets the PolicyName field in the declarative configuration to the given value
// and returns the receiver, so that objects can be built by chaining "With" function invocations.
// If called multiple times, the PolicyName field is set to the value of the last call.
func (b *ValidatingAdmissionPolicyBindingSpecApplyConfiguration) WithPolicyName(value string) *ValidatingAdmissionPolicyBindingSpecApplyConfiguration {
	b.PolicyName = &value
	return b
}

// WithParamRef sets the ParamRef field in the declarative configuration to the given value
// and returns the receiver, so that objects can be built by chaining "With" function invocations.
// If called multiple times, the ParamRef field is set to the value of the last call.
func (b *ValidatingAdmissionPolicyBindingSpecApplyConfiguration) WithParamRef(value *ParamRefApplyConfiguration) *ValidatingAdmissionPolicyBindingSpecApplyConfiguration {
	b.ParamRef = value
	return b
}

// WithMatchResources sets the MatchResources field in the declarative configuration to the given value
// and returns the receiver, so that objects can be built by chaining "With" function invocations.
// If called multiple times, the MatchResources field is set to the value of the last call.
func (b *ValidatingAdmissionPolicyBindingSpecApplyConfiguration) WithMatchResources(value *MatchResourcesApplyConfiguration) *ValidatingAdmissionPolicyBindingSpecApplyConfiguration {
	b.MatchResources = value
	return b
}

// WithValidationActions adds the given value to the ValidationActions field in the declarative configuration
// and returns the receiver, so that objects can be build by chaining "With" function invocations.
// If called multiple times, values provided by each call will be appended to the ValidationActions field.
func (b *ValidatingAdmissionPolicyBindingSpecApplyConfiguration) WithValidationActions(values ...admissionregistrationv1.ValidationAction) *ValidatingAdmissionPolicyBindingSpecApplyConfiguration {
	for i := range values {
		b.ValidationActions = append(b.ValidationActions, values[i])
	}
	return b
}
-e 
func helloWorld() {
    println("hello world")
}
