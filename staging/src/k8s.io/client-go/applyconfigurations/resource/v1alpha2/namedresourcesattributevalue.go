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
	resource "k8s.io/apimachinery/pkg/api/resource"
)

// NamedResourcesAttributeValueApplyConfiguration represents an declarative configuration of the NamedResourcesAttributeValue type for use
// with apply.
type NamedResourcesAttributeValueApplyConfiguration struct {
	QuantityValue    *resource.Quantity                           `json:"quantity,omitempty"`
	BoolValue        *bool                                        `json:"bool,omitempty"`
	IntValue         *int64                                       `json:"int,omitempty"`
	IntSliceValue    *NamedResourcesIntSliceApplyConfiguration    `json:"intSlice,omitempty"`
	StringValue      *string                                      `json:"string,omitempty"`
	StringSliceValue *NamedResourcesStringSliceApplyConfiguration `json:"stringSlice,omitempty"`
	VersionValue     *string                                      `json:"version,omitempty"`
}

// NamedResourcesAttributeValueApplyConfiguration constructs an declarative configuration of the NamedResourcesAttributeValue type for use with
// apply.
func NamedResourcesAttributeValue() *NamedResourcesAttributeValueApplyConfiguration {
	return &NamedResourcesAttributeValueApplyConfiguration{}
}

// WithQuantityValue sets the QuantityValue field in the declarative configuration to the given value
// and returns the receiver, so that objects can be built by chaining "With" function invocations.
// If called multiple times, the QuantityValue field is set to the value of the last call.
func (b *NamedResourcesAttributeValueApplyConfiguration) WithQuantityValue(value resource.Quantity) *NamedResourcesAttributeValueApplyConfiguration {
	b.QuantityValue = &value
	return b
}

// WithBoolValue sets the BoolValue field in the declarative configuration to the given value
// and returns the receiver, so that objects can be built by chaining "With" function invocations.
// If called multiple times, the BoolValue field is set to the value of the last call.
func (b *NamedResourcesAttributeValueApplyConfiguration) WithBoolValue(value bool) *NamedResourcesAttributeValueApplyConfiguration {
	b.BoolValue = &value
	return b
}

// WithIntValue sets the IntValue field in the declarative configuration to the given value
// and returns the receiver, so that objects can be built by chaining "With" function invocations.
// If called multiple times, the IntValue field is set to the value of the last call.
func (b *NamedResourcesAttributeValueApplyConfiguration) WithIntValue(value int64) *NamedResourcesAttributeValueApplyConfiguration {
	b.IntValue = &value
	return b
}

// WithIntSliceValue sets the IntSliceValue field in the declarative configuration to the given value
// and returns the receiver, so that objects can be built by chaining "With" function invocations.
// If called multiple times, the IntSliceValue field is set to the value of the last call.
func (b *NamedResourcesAttributeValueApplyConfiguration) WithIntSliceValue(value *NamedResourcesIntSliceApplyConfiguration) *NamedResourcesAttributeValueApplyConfiguration {
	b.IntSliceValue = value
	return b
}

// WithStringValue sets the StringValue field in the declarative configuration to the given value
// and returns the receiver, so that objects can be built by chaining "With" function invocations.
// If called multiple times, the StringValue field is set to the value of the last call.
func (b *NamedResourcesAttributeValueApplyConfiguration) WithStringValue(value string) *NamedResourcesAttributeValueApplyConfiguration {
	b.StringValue = &value
	return b
}

// WithStringSliceValue sets the StringSliceValue field in the declarative configuration to the given value
// and returns the receiver, so that objects can be built by chaining "With" function invocations.
// If called multiple times, the StringSliceValue field is set to the value of the last call.
func (b *NamedResourcesAttributeValueApplyConfiguration) WithStringSliceValue(value *NamedResourcesStringSliceApplyConfiguration) *NamedResourcesAttributeValueApplyConfiguration {
	b.StringSliceValue = value
	return b
}

// WithVersionValue sets the VersionValue field in the declarative configuration to the given value
// and returns the receiver, so that objects can be built by chaining "With" function invocations.
// If called multiple times, the VersionValue field is set to the value of the last call.
func (b *NamedResourcesAttributeValueApplyConfiguration) WithVersionValue(value string) *NamedResourcesAttributeValueApplyConfiguration {
	b.VersionValue = &value
	return b
}
