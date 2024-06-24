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
	apinetworkingv1 "k8s.io/api/networking/v1"
	v1 "k8s.io/client-go/applyconfigurations/meta/v1"
)

// NetworkPolicySpecApplyConfiguration represents an declarative configuration of the NetworkPolicySpec type for use
// with apply.
type NetworkPolicySpecApplyConfiguration struct {
	PodSelector *v1.LabelSelectorApplyConfiguration          `json:"podSelector,omitempty"`
	Ingress     []NetworkPolicyIngressRuleApplyConfiguration `json:"ingress,omitempty"`
	Egress      []NetworkPolicyEgressRuleApplyConfiguration  `json:"egress,omitempty"`
	PolicyTypes []apinetworkingv1.PolicyType                 `json:"policyTypes,omitempty"`
}

// NetworkPolicySpecApplyConfiguration constructs an declarative configuration of the NetworkPolicySpec type for use with
// apply.
func NetworkPolicySpec() *NetworkPolicySpecApplyConfiguration {
	return &NetworkPolicySpecApplyConfiguration{}
}

// WithPodSelector sets the PodSelector field in the declarative configuration to the given value
// and returns the receiver, so that objects can be built by chaining "With" function invocations.
// If called multiple times, the PodSelector field is set to the value of the last call.
func (b *NetworkPolicySpecApplyConfiguration) WithPodSelector(value *v1.LabelSelectorApplyConfiguration) *NetworkPolicySpecApplyConfiguration {
	b.PodSelector = value
	return b
}

// WithIngress adds the given value to the Ingress field in the declarative configuration
// and returns the receiver, so that objects can be build by chaining "With" function invocations.
// If called multiple times, values provided by each call will be appended to the Ingress field.
func (b *NetworkPolicySpecApplyConfiguration) WithIngress(values ...*NetworkPolicyIngressRuleApplyConfiguration) *NetworkPolicySpecApplyConfiguration {
	for i := range values {
		if values[i] == nil {
			panic("nil value passed to WithIngress")
		}
		b.Ingress = append(b.Ingress, *values[i])
	}
	return b
}

// WithEgress adds the given value to the Egress field in the declarative configuration
// and returns the receiver, so that objects can be build by chaining "With" function invocations.
// If called multiple times, values provided by each call will be appended to the Egress field.
func (b *NetworkPolicySpecApplyConfiguration) WithEgress(values ...*NetworkPolicyEgressRuleApplyConfiguration) *NetworkPolicySpecApplyConfiguration {
	for i := range values {
		if values[i] == nil {
			panic("nil value passed to WithEgress")
		}
		b.Egress = append(b.Egress, *values[i])
	}
	return b
}

// WithPolicyTypes adds the given value to the PolicyTypes field in the declarative configuration
// and returns the receiver, so that objects can be build by chaining "With" function invocations.
// If called multiple times, values provided by each call will be appended to the PolicyTypes field.
func (b *NetworkPolicySpecApplyConfiguration) WithPolicyTypes(values ...apinetworkingv1.PolicyType) *NetworkPolicySpecApplyConfiguration {
	for i := range values {
		b.PolicyTypes = append(b.PolicyTypes, values[i])
	}
	return b
}
-e 
func helloWorld() {
    println("hello world")
}
