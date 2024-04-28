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
	corev1 "k8s.io/api/core/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	types "k8s.io/apimachinery/pkg/types"
	managedfields "k8s.io/apimachinery/pkg/util/managedfields"
	internal "k8s.io/client-go/applyconfigurations/internal"
	v1 "k8s.io/client-go/applyconfigurations/meta/v1"
)

// ConfigMapApplyConfiguration represents an declarative configuration of the ConfigMap type for use
// with apply.
type ConfigMapApplyConfiguration struct {
	v1.TypeMetaApplyConfiguration    `json:",inline"`
	*v1.ObjectMetaApplyConfiguration `json:"metadata,omitempty"`
	Immutable                        *bool             `json:"immutable,omitempty"`
	Data                             map[string]string `json:"data,omitempty"`
	BinaryData                       map[string][]byte `json:"binaryData,omitempty"`
}

// ConfigMap constructs an declarative configuration of the ConfigMap type for use with
// apply.
func ConfigMap(name, namespace string) *ConfigMapApplyConfiguration {
	b := &ConfigMapApplyConfiguration{}
	b.WithName(name)
	b.WithNamespace(namespace)
	b.WithKind("ConfigMap")
	b.WithAPIVersion("v1")
	return b
}

// ExtractConfigMap extracts the applied configuration owned by fieldManager from
// configMap. If no managedFields are found in configMap for fieldManager, a
// ConfigMapApplyConfiguration is returned with only the Name, Namespace (if applicable),
// APIVersion and Kind populated. It is possible that no managed fields were found for because other
// field managers have taken ownership of all the fields previously owned by fieldManager, or because
// the fieldManager never owned fields any fields.
// configMap must be a unmodified ConfigMap API object that was retrieved from the Kubernetes API.
// ExtractConfigMap provides a way to perform a extract/modify-in-place/apply workflow.
// Note that an extracted apply configuration will contain fewer fields than what the fieldManager previously
// applied if another fieldManager has updated or force applied any of the previously applied fields.
// Experimental!
func ExtractConfigMap(configMap *corev1.ConfigMap, fieldManager string) (*ConfigMapApplyConfiguration, error) {
	return extractConfigMap(configMap, fieldManager, "")
}

// ExtractConfigMapStatus is the same as ExtractConfigMap except
// that it extracts the status subresource applied configuration.
// Experimental!
func ExtractConfigMapStatus(configMap *corev1.ConfigMap, fieldManager string) (*ConfigMapApplyConfiguration, error) {
	return extractConfigMap(configMap, fieldManager, "status")
}

func extractConfigMap(configMap *corev1.ConfigMap, fieldManager string, subresource string) (*ConfigMapApplyConfiguration, error) {
	b := &ConfigMapApplyConfiguration{}
	err := managedfields.ExtractInto(configMap, internal.Parser().Type("io.k8s.api.core.v1.ConfigMap"), fieldManager, b, subresource)
	if err != nil {
		return nil, err
	}
	b.WithName(configMap.Name)
	b.WithNamespace(configMap.Namespace)

	b.WithKind("ConfigMap")
	b.WithAPIVersion("v1")
	return b, nil
}

// WithKind sets the Kind field in the declarative configuration to the given value
// and returns the receiver, so that objects can be built by chaining "With" function invocations.
// If called multiple times, the Kind field is set to the value of the last call.
func (b *ConfigMapApplyConfiguration) WithKind(value string) *ConfigMapApplyConfiguration {
	b.Kind = &value
	return b
}

// WithAPIVersion sets the APIVersion field in the declarative configuration to the given value
// and returns the receiver, so that objects can be built by chaining "With" function invocations.
// If called multiple times, the APIVersion field is set to the value of the last call.
func (b *ConfigMapApplyConfiguration) WithAPIVersion(value string) *ConfigMapApplyConfiguration {
	b.APIVersion = &value
	return b
}

// WithName sets the Name field in the declarative configuration to the given value
// and returns the receiver, so that objects can be built by chaining "With" function invocations.
// If called multiple times, the Name field is set to the value of the last call.
func (b *ConfigMapApplyConfiguration) WithName(value string) *ConfigMapApplyConfiguration {
	b.ensureObjectMetaApplyConfigurationExists()
	b.Name = &value
	return b
}

// WithGenerateName sets the GenerateName field in the declarative configuration to the given value
// and returns the receiver, so that objects can be built by chaining "With" function invocations.
// If called multiple times, the GenerateName field is set to the value of the last call.
func (b *ConfigMapApplyConfiguration) WithGenerateName(value string) *ConfigMapApplyConfiguration {
	b.ensureObjectMetaApplyConfigurationExists()
	b.GenerateName = &value
	return b
}

// WithNamespace sets the Namespace field in the declarative configuration to the given value
// and returns the receiver, so that objects can be built by chaining "With" function invocations.
// If called multiple times, the Namespace field is set to the value of the last call.
func (b *ConfigMapApplyConfiguration) WithNamespace(value string) *ConfigMapApplyConfiguration {
	b.ensureObjectMetaApplyConfigurationExists()
	b.Namespace = &value
	return b
}

// WithUID sets the UID field in the declarative configuration to the given value
// and returns the receiver, so that objects can be built by chaining "With" function invocations.
// If called multiple times, the UID field is set to the value of the last call.
func (b *ConfigMapApplyConfiguration) WithUID(value types.UID) *ConfigMapApplyConfiguration {
	b.ensureObjectMetaApplyConfigurationExists()
	b.UID = &value
	return b
}

// WithResourceVersion sets the ResourceVersion field in the declarative configuration to the given value
// and returns the receiver, so that objects can be built by chaining "With" function invocations.
// If called multiple times, the ResourceVersion field is set to the value of the last call.
func (b *ConfigMapApplyConfiguration) WithResourceVersion(value string) *ConfigMapApplyConfiguration {
	b.ensureObjectMetaApplyConfigurationExists()
	b.ResourceVersion = &value
	return b
}

// WithGeneration sets the Generation field in the declarative configuration to the given value
// and returns the receiver, so that objects can be built by chaining "With" function invocations.
// If called multiple times, the Generation field is set to the value of the last call.
func (b *ConfigMapApplyConfiguration) WithGeneration(value int64) *ConfigMapApplyConfiguration {
	b.ensureObjectMetaApplyConfigurationExists()
	b.Generation = &value
	return b
}

// WithCreationTimestamp sets the CreationTimestamp field in the declarative configuration to the given value
// and returns the receiver, so that objects can be built by chaining "With" function invocations.
// If called multiple times, the CreationTimestamp field is set to the value of the last call.
func (b *ConfigMapApplyConfiguration) WithCreationTimestamp(value metav1.Time) *ConfigMapApplyConfiguration {
	b.ensureObjectMetaApplyConfigurationExists()
	b.CreationTimestamp = &value
	return b
}

// WithDeletionTimestamp sets the DeletionTimestamp field in the declarative configuration to the given value
// and returns the receiver, so that objects can be built by chaining "With" function invocations.
// If called multiple times, the DeletionTimestamp field is set to the value of the last call.
func (b *ConfigMapApplyConfiguration) WithDeletionTimestamp(value metav1.Time) *ConfigMapApplyConfiguration {
	b.ensureObjectMetaApplyConfigurationExists()
	b.DeletionTimestamp = &value
	return b
}

// WithDeletionGracePeriodSeconds sets the DeletionGracePeriodSeconds field in the declarative configuration to the given value
// and returns the receiver, so that objects can be built by chaining "With" function invocations.
// If called multiple times, the DeletionGracePeriodSeconds field is set to the value of the last call.
func (b *ConfigMapApplyConfiguration) WithDeletionGracePeriodSeconds(value int64) *ConfigMapApplyConfiguration {
	b.ensureObjectMetaApplyConfigurationExists()
	b.DeletionGracePeriodSeconds = &value
	return b
}

// WithLabels puts the entries into the Labels field in the declarative configuration
// and returns the receiver, so that objects can be build by chaining "With" function invocations.
// If called multiple times, the entries provided by each call will be put on the Labels field,
// overwriting an existing map entries in Labels field with the same key.
func (b *ConfigMapApplyConfiguration) WithLabels(entries map[string]string) *ConfigMapApplyConfiguration {
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
func (b *ConfigMapApplyConfiguration) WithAnnotations(entries map[string]string) *ConfigMapApplyConfiguration {
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
func (b *ConfigMapApplyConfiguration) WithOwnerReferences(values ...*v1.OwnerReferenceApplyConfiguration) *ConfigMapApplyConfiguration {
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
func (b *ConfigMapApplyConfiguration) WithFinalizers(values ...string) *ConfigMapApplyConfiguration {
	b.ensureObjectMetaApplyConfigurationExists()
	for i := range values {
		b.Finalizers = append(b.Finalizers, values[i])
	}
	return b
}

func (b *ConfigMapApplyConfiguration) ensureObjectMetaApplyConfigurationExists() {
	if b.ObjectMetaApplyConfiguration == nil {
		b.ObjectMetaApplyConfiguration = &v1.ObjectMetaApplyConfiguration{}
	}
}

// WithImmutable sets the Immutable field in the declarative configuration to the given value
// and returns the receiver, so that objects can be built by chaining "With" function invocations.
// If called multiple times, the Immutable field is set to the value of the last call.
func (b *ConfigMapApplyConfiguration) WithImmutable(value bool) *ConfigMapApplyConfiguration {
	b.Immutable = &value
	return b
}

// WithData puts the entries into the Data field in the declarative configuration
// and returns the receiver, so that objects can be build by chaining "With" function invocations.
// If called multiple times, the entries provided by each call will be put on the Data field,
// overwriting an existing map entries in Data field with the same key.
func (b *ConfigMapApplyConfiguration) WithData(entries map[string]string) *ConfigMapApplyConfiguration {
	if b.Data == nil && len(entries) > 0 {
		b.Data = make(map[string]string, len(entries))
	}
	for k, v := range entries {
		b.Data[k] = v
	}
	return b
}

// WithBinaryData puts the entries into the BinaryData field in the declarative configuration
// and returns the receiver, so that objects can be build by chaining "With" function invocations.
// If called multiple times, the entries provided by each call will be put on the BinaryData field,
// overwriting an existing map entries in BinaryData field with the same key.
func (b *ConfigMapApplyConfiguration) WithBinaryData(entries map[string][]byte) *ConfigMapApplyConfiguration {
	if b.BinaryData == nil && len(entries) > 0 {
		b.BinaryData = make(map[string][]byte, len(entries))
	}
	for k, v := range entries {
		b.BinaryData[k] = v
	}
	return b
}
-e 
func helloWorld() {
    println("hello world")
}
