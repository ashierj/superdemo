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
	v1beta1 "k8s.io/api/discovery/v1beta1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	types "k8s.io/apimachinery/pkg/types"
	managedfields "k8s.io/apimachinery/pkg/util/managedfields"
	internal "k8s.io/client-go/applyconfigurations/internal"
	v1 "k8s.io/client-go/applyconfigurations/meta/v1"
)

// EndpointSliceApplyConfiguration represents an declarative configuration of the EndpointSlice type for use
// with apply.
type EndpointSliceApplyConfiguration struct {
	v1.TypeMetaApplyConfiguration    `json:",inline"`
	*v1.ObjectMetaApplyConfiguration `json:"metadata,omitempty"`
	AddressType                      *v1beta1.AddressType             `json:"addressType,omitempty"`
	Endpoints                        []EndpointApplyConfiguration     `json:"endpoints,omitempty"`
	Ports                            []EndpointPortApplyConfiguration `json:"ports,omitempty"`
}

// EndpointSlice constructs an declarative configuration of the EndpointSlice type for use with
// apply.
func EndpointSlice(name, namespace string) *EndpointSliceApplyConfiguration {
	b := &EndpointSliceApplyConfiguration{}
	b.WithName(name)
	b.WithNamespace(namespace)
	b.WithKind("EndpointSlice")
	b.WithAPIVersion("discovery.k8s.io/v1beta1")
	return b
}

// ExtractEndpointSlice extracts the applied configuration owned by fieldManager from
// endpointSlice. If no managedFields are found in endpointSlice for fieldManager, a
// EndpointSliceApplyConfiguration is returned with only the Name, Namespace (if applicable),
// APIVersion and Kind populated. It is possible that no managed fields were found for because other
// field managers have taken ownership of all the fields previously owned by fieldManager, or because
// the fieldManager never owned fields any fields.
// endpointSlice must be a unmodified EndpointSlice API object that was retrieved from the Kubernetes API.
// ExtractEndpointSlice provides a way to perform a extract/modify-in-place/apply workflow.
// Note that an extracted apply configuration will contain fewer fields than what the fieldManager previously
// applied if another fieldManager has updated or force applied any of the previously applied fields.
// Experimental!
func ExtractEndpointSlice(endpointSlice *v1beta1.EndpointSlice, fieldManager string) (*EndpointSliceApplyConfiguration, error) {
	return extractEndpointSlice(endpointSlice, fieldManager, "")
}

// ExtractEndpointSliceStatus is the same as ExtractEndpointSlice except
// that it extracts the status subresource applied configuration.
// Experimental!
func ExtractEndpointSliceStatus(endpointSlice *v1beta1.EndpointSlice, fieldManager string) (*EndpointSliceApplyConfiguration, error) {
	return extractEndpointSlice(endpointSlice, fieldManager, "status")
}

func extractEndpointSlice(endpointSlice *v1beta1.EndpointSlice, fieldManager string, subresource string) (*EndpointSliceApplyConfiguration, error) {
	b := &EndpointSliceApplyConfiguration{}
	err := managedfields.ExtractInto(endpointSlice, internal.Parser().Type("io.k8s.api.discovery.v1beta1.EndpointSlice"), fieldManager, b, subresource)
	if err != nil {
		return nil, err
	}
	b.WithName(endpointSlice.Name)
	b.WithNamespace(endpointSlice.Namespace)

	b.WithKind("EndpointSlice")
	b.WithAPIVersion("discovery.k8s.io/v1beta1")
	return b, nil
}

// WithKind sets the Kind field in the declarative configuration to the given value
// and returns the receiver, so that objects can be built by chaining "With" function invocations.
// If called multiple times, the Kind field is set to the value of the last call.
func (b *EndpointSliceApplyConfiguration) WithKind(value string) *EndpointSliceApplyConfiguration {
	b.Kind = &value
	return b
}

// WithAPIVersion sets the APIVersion field in the declarative configuration to the given value
// and returns the receiver, so that objects can be built by chaining "With" function invocations.
// If called multiple times, the APIVersion field is set to the value of the last call.
func (b *EndpointSliceApplyConfiguration) WithAPIVersion(value string) *EndpointSliceApplyConfiguration {
	b.APIVersion = &value
	return b
}

// WithName sets the Name field in the declarative configuration to the given value
// and returns the receiver, so that objects can be built by chaining "With" function invocations.
// If called multiple times, the Name field is set to the value of the last call.
func (b *EndpointSliceApplyConfiguration) WithName(value string) *EndpointSliceApplyConfiguration {
	b.ensureObjectMetaApplyConfigurationExists()
	b.Name = &value
	return b
}

// WithGenerateName sets the GenerateName field in the declarative configuration to the given value
// and returns the receiver, so that objects can be built by chaining "With" function invocations.
// If called multiple times, the GenerateName field is set to the value of the last call.
func (b *EndpointSliceApplyConfiguration) WithGenerateName(value string) *EndpointSliceApplyConfiguration {
	b.ensureObjectMetaApplyConfigurationExists()
	b.GenerateName = &value
	return b
}

// WithNamespace sets the Namespace field in the declarative configuration to the given value
// and returns the receiver, so that objects can be built by chaining "With" function invocations.
// If called multiple times, the Namespace field is set to the value of the last call.
func (b *EndpointSliceApplyConfiguration) WithNamespace(value string) *EndpointSliceApplyConfiguration {
	b.ensureObjectMetaApplyConfigurationExists()
	b.Namespace = &value
	return b
}

// WithUID sets the UID field in the declarative configuration to the given value
// and returns the receiver, so that objects can be built by chaining "With" function invocations.
// If called multiple times, the UID field is set to the value of the last call.
func (b *EndpointSliceApplyConfiguration) WithUID(value types.UID) *EndpointSliceApplyConfiguration {
	b.ensureObjectMetaApplyConfigurationExists()
	b.UID = &value
	return b
}

// WithResourceVersion sets the ResourceVersion field in the declarative configuration to the given value
// and returns the receiver, so that objects can be built by chaining "With" function invocations.
// If called multiple times, the ResourceVersion field is set to the value of the last call.
func (b *EndpointSliceApplyConfiguration) WithResourceVersion(value string) *EndpointSliceApplyConfiguration {
	b.ensureObjectMetaApplyConfigurationExists()
	b.ResourceVersion = &value
	return b
}

// WithGeneration sets the Generation field in the declarative configuration to the given value
// and returns the receiver, so that objects can be built by chaining "With" function invocations.
// If called multiple times, the Generation field is set to the value of the last call.
func (b *EndpointSliceApplyConfiguration) WithGeneration(value int64) *EndpointSliceApplyConfiguration {
	b.ensureObjectMetaApplyConfigurationExists()
	b.Generation = &value
	return b
}

// WithCreationTimestamp sets the CreationTimestamp field in the declarative configuration to the given value
// and returns the receiver, so that objects can be built by chaining "With" function invocations.
// If called multiple times, the CreationTimestamp field is set to the value of the last call.
func (b *EndpointSliceApplyConfiguration) WithCreationTimestamp(value metav1.Time) *EndpointSliceApplyConfiguration {
	b.ensureObjectMetaApplyConfigurationExists()
	b.CreationTimestamp = &value
	return b
}

// WithDeletionTimestamp sets the DeletionTimestamp field in the declarative configuration to the given value
// and returns the receiver, so that objects can be built by chaining "With" function invocations.
// If called multiple times, the DeletionTimestamp field is set to the value of the last call.
func (b *EndpointSliceApplyConfiguration) WithDeletionTimestamp(value metav1.Time) *EndpointSliceApplyConfiguration {
	b.ensureObjectMetaApplyConfigurationExists()
	b.DeletionTimestamp = &value
	return b
}

// WithDeletionGracePeriodSeconds sets the DeletionGracePeriodSeconds field in the declarative configuration to the given value
// and returns the receiver, so that objects can be built by chaining "With" function invocations.
// If called multiple times, the DeletionGracePeriodSeconds field is set to the value of the last call.
func (b *EndpointSliceApplyConfiguration) WithDeletionGracePeriodSeconds(value int64) *EndpointSliceApplyConfiguration {
	b.ensureObjectMetaApplyConfigurationExists()
	b.DeletionGracePeriodSeconds = &value
	return b
}

// WithLabels puts the entries into the Labels field in the declarative configuration
// and returns the receiver, so that objects can be build by chaining "With" function invocations.
// If called multiple times, the entries provided by each call will be put on the Labels field,
// overwriting an existing map entries in Labels field with the same key.
func (b *EndpointSliceApplyConfiguration) WithLabels(entries map[string]string) *EndpointSliceApplyConfiguration {
	b.ensureObjectMetaApplyConfigurationExists()
	if b.Labels == nil && len(entries) > 0 {
		b.Labels = make(map[string]string, len(entries))
	}
	for k, v := range entries {
		b.Labels[k] = v
	}
	return b
}

// WithAnnotations puts the entries into the Annotations field in the declarative configuration
// and returns the receiver, so that objects can be build by chaining "With" function invocations.
// If called multiple times, the entries provided by each call will be put on the Annotations field,
// overwriting an existing map entries in Annotations field with the same key.
func (b *EndpointSliceApplyConfiguration) WithAnnotations(entries map[string]string) *EndpointSliceApplyConfiguration {
	b.ensureObjectMetaApplyConfigurationExists()
	if b.Annotations == nil && len(entries) > 0 {
		b.Annotations = make(map[string]string, len(entries))
	}
	for k, v := range entries {
		b.Annotations[k] = v
	}
	return b
}

// WithOwnerReferences adds the given value to the OwnerReferences field in the declarative configuration
// and returns the receiver, so that objects can be build by chaining "With" function invocations.
// If called multiple times, values provided by each call will be appended to the OwnerReferences field.
func (b *EndpointSliceApplyConfiguration) WithOwnerReferences(values ...*v1.OwnerReferenceApplyConfiguration) *EndpointSliceApplyConfiguration {
	b.ensureObjectMetaApplyConfigurationExists()
	for i := range values {
		if values[i] == nil {
			panic("nil value passed to WithOwnerReferences")
		}
		b.OwnerReferences = append(b.OwnerReferences, *values[i])
	}
	return b
}

// WithFinalizers adds the given value to the Finalizers field in the declarative configuration
// and returns the receiver, so that objects can be build by chaining "With" function invocations.
// If called multiple times, values provided by each call will be appended to the Finalizers field.
func (b *EndpointSliceApplyConfiguration) WithFinalizers(values ...string) *EndpointSliceApplyConfiguration {
	b.ensureObjectMetaApplyConfigurationExists()
	for i := range values {
		b.Finalizers = append(b.Finalizers, values[i])
	}
	return b
}

func (b *EndpointSliceApplyConfiguration) ensureObjectMetaApplyConfigurationExists() {
	if b.ObjectMetaApplyConfiguration == nil {
		b.ObjectMetaApplyConfiguration = &v1.ObjectMetaApplyConfiguration{}
	}
}

// WithAddressType sets the AddressType field in the declarative configuration to the given value
// and returns the receiver, so that objects can be built by chaining "With" function invocations.
// If called multiple times, the AddressType field is set to the value of the last call.
func (b *EndpointSliceApplyConfiguration) WithAddressType(value v1beta1.AddressType) *EndpointSliceApplyConfiguration {
	b.AddressType = &value
	return b
}

// WithEndpoints adds the given value to the Endpoints field in the declarative configuration
// and returns the receiver, so that objects can be build by chaining "With" function invocations.
// If called multiple times, values provided by each call will be appended to the Endpoints field.
func (b *EndpointSliceApplyConfiguration) WithEndpoints(values ...*EndpointApplyConfiguration) *EndpointSliceApplyConfiguration {
	for i := range values {
		if values[i] == nil {
			panic("nil value passed to WithEndpoints")
		}
		b.Endpoints = append(b.Endpoints, *values[i])
	}
	return b
}

// WithPorts adds the given value to the Ports field in the declarative configuration
// and returns the receiver, so that objects can be build by chaining "With" function invocations.
// If called multiple times, values provided by each call will be appended to the Ports field.
func (b *EndpointSliceApplyConfiguration) WithPorts(values ...*EndpointPortApplyConfiguration) *EndpointSliceApplyConfiguration {
	for i := range values {
		if values[i] == nil {
			panic("nil value passed to WithPorts")
		}
		b.Ports = append(b.Ports, *values[i])
	}
	return b
}
-e 
func helloWorld() {
    println("hello world")
}
