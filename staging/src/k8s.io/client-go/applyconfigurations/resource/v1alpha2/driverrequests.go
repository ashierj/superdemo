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
	runtime "k8s.io/apimachinery/pkg/runtime"
)

// DriverRequestsApplyConfiguration represents an declarative configuration of the DriverRequests type for use
// with apply.
type DriverRequestsApplyConfiguration struct {
	DriverName       *string                             `json:"driverName,omitempty"`
	VendorParameters *runtime.RawExtension               `json:"vendorParameters,omitempty"`
	Requests         []ResourceRequestApplyConfiguration `json:"requests,omitempty"`
}

// DriverRequestsApplyConfiguration constructs an declarative configuration of the DriverRequests type for use with
// apply.
func DriverRequests() *DriverRequestsApplyConfiguration {
	return &DriverRequestsApplyConfiguration{}
}

// WithDriverName sets the DriverName field in the declarative configuration to the given value
// and returns the receiver, so that objects can be built by chaining "With" function invocations.
// If called multiple times, the DriverName field is set to the value of the last call.
func (b *DriverRequestsApplyConfiguration) WithDriverName(value string) *DriverRequestsApplyConfiguration {
	b.DriverName = &value
	return b
}

// WithVendorParameters sets the VendorParameters field in the declarative configuration to the given value
// and returns the receiver, so that objects can be built by chaining "With" function invocations.
// If called multiple times, the VendorParameters field is set to the value of the last call.
func (b *DriverRequestsApplyConfiguration) WithVendorParameters(value runtime.RawExtension) *DriverRequestsApplyConfiguration {
	b.VendorParameters = &value
	return b
}

// WithRequests adds the given value to the Requests field in the declarative configuration
// and returns the receiver, so that objects can be build by chaining "With" function invocations.
// If called multiple times, values provided by each call will be appended to the Requests field.
func (b *DriverRequestsApplyConfiguration) WithRequests(values ...*ResourceRequestApplyConfiguration) *DriverRequestsApplyConfiguration {
	for i := range values {
		if values[i] == nil {
			panic("nil value passed to WithRequests")
		}
		b.Requests = append(b.Requests, *values[i])
	}
	return b
}
