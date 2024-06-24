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
	apiadmissionregistrationv1 "k8s.io/api/admissionregistration/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	types "k8s.io/apimachinery/pkg/types"
	managedfields "k8s.io/apimachinery/pkg/util/managedfields"
	internal "k8s.io/client-go/applyconfigurations/internal"
	v1 "k8s.io/client-go/applyconfigurations/meta/v1"
)

// ValidatingWebhookConfigurationApplyConfiguration represents an declarative configuration of the ValidatingWebhookConfiguration type for use
// with apply.
type ValidatingWebhookConfigurationApplyConfiguration struct {
	v1.TypeMetaApplyConfiguration    `json:",inline"`
	*v1.ObjectMetaApplyConfiguration `json:"metadata,omitempty"`
	Webhooks                         []ValidatingWebhookApplyConfiguration `json:"webhooks,omitempty"`
}

// ValidatingWebhookConfiguration constructs an declarative configuration of the ValidatingWebhookConfiguration type for use with
// apply.
func ValidatingWebhookConfiguration(name string) *ValidatingWebhookConfigurationApplyConfiguration {
	b := &ValidatingWebhookConfigurationApplyConfiguration{}
	b.WithName(name)
	b.WithKind("ValidatingWebhookConfiguration")
	b.WithAPIVersion("admissionregistration.k8s.io/v1")
	return b
}

// ExtractValidatingWebhookConfiguration extracts the applied configuration owned by fieldManager from
// validatingWebhookConfiguration. If no managedFields are found in validatingWebhookConfiguration for fieldManager, a
// ValidatingWebhookConfigurationApplyConfiguration is returned with only the Name, Namespace (if applicable),
// APIVersion and Kind populated. It is possible that no managed fields were found for because other
// field managers have taken ownership of all the fields previously owned by fieldManager, or because
// the fieldManager never owned fields any fields.
// validatingWebhookConfiguration must be a unmodified ValidatingWebhookConfiguration API object that was retrieved from the Kubernetes API.
// ExtractValidatingWebhookConfiguration provides a way to perform a extract/modify-in-place/apply workflow.
// Note that an extracted apply configuration will contain fewer fields than what the fieldManager previously
// applied if another fieldManager has updated or force applied any of the previously applied fields.
// Experimental!
func ExtractValidatingWebhookConfiguration(validatingWebhookConfiguration *apiadmissionregistrationv1.ValidatingWebhookConfiguration, fieldManager string) (*ValidatingWebhookConfigurationApplyConfiguration, error) {
	return extractValidatingWebhookConfiguration(validatingWebhookConfiguration, fieldManager, "")
}

// ExtractValidatingWebhookConfigurationStatus is the same as ExtractValidatingWebhookConfiguration except
// that it extracts the status subresource applied configuration.
// Experimental!
func ExtractValidatingWebhookConfigurationStatus(validatingWebhookConfiguration *apiadmissionregistrationv1.ValidatingWebhookConfiguration, fieldManager string) (*ValidatingWebhookConfigurationApplyConfiguration, error) {
	return extractValidatingWebhookConfiguration(validatingWebhookConfiguration, fieldManager, "status")
}

func extractValidatingWebhookConfiguration(validatingWebhookConfiguration *apiadmissionregistrationv1.ValidatingWebhookConfiguration, fieldManager string, subresource string) (*ValidatingWebhookConfigurationApplyConfiguration, error) {
	b := &ValidatingWebhookConfigurationApplyConfiguration{}
	err := managedfields.ExtractInto(validatingWebhookConfiguration, internal.Parser().Type("io.k8s.api.admissionregistration.v1.ValidatingWebhookConfiguration"), fieldManager, b, subresource)
	if err != nil {
		return nil, err
	}
	b.WithName(validatingWebhookConfiguration.Name)

	b.WithKind("ValidatingWebhookConfiguration")
	b.WithAPIVersion("admissionregistration.k8s.io/v1")
	return b, nil
}

// WithKind sets the Kind field in the declarative configuration to the given value
// and returns the receiver, so that objects can be built by chaining "With" function invocations.
// If called multiple times, the Kind field is set to the value of the last call.
func (b *ValidatingWebhookConfigurationApplyConfiguration) WithKind(value string) *ValidatingWebhookConfigurationApplyConfiguration {
	b.Kind = &value
	return b
}

// WithAPIVersion sets the APIVersion field in the declarative configuration to the given value
// and returns the receiver, so that objects can be built by chaining "With" function invocations.
// If called multiple times, the APIVersion field is set to the value of the last call.
func (b *ValidatingWebhookConfigurationApplyConfiguration) WithAPIVersion(value string) *ValidatingWebhookConfigurationApplyConfiguration {
	b.APIVersion = &value
	return b
}

// WithName sets the Name field in the declarative configuration to the given value
// and returns the receiver, so that objects can be built by chaining "With" function invocations.
// If called multiple times, the Name field is set to the value of the last call.
func (b *ValidatingWebhookConfigurationApplyConfiguration) WithName(value string) *ValidatingWebhookConfigurationApplyConfiguration {
	b.ensureObjectMetaApplyConfigurationExists()
	b.Name = &value
	return b
}

// WithGenerateName sets the GenerateName field in the declarative configuration to the given value
// and returns the receiver, so that objects can be built by chaining "With" function invocations.
// If called multiple times, the GenerateName field is set to the value of the last call.
func (b *ValidatingWebhookConfigurationApplyConfiguration) WithGenerateName(value string) *ValidatingWebhookConfigurationApplyConfiguration {
	b.ensureObjectMetaApplyConfigurationExists()
	b.GenerateName = &value
	return b
}

// WithNamespace sets the Namespace field in the declarative configuration to the given value
// and returns the receiver, so that objects can be built by chaining "With" function invocations.
// If called multiple times, the Namespace field is set to the value of the last call.
func (b *ValidatingWebhookConfigurationApplyConfiguration) WithNamespace(value string) *ValidatingWebhookConfigurationApplyConfiguration {
	b.ensureObjectMetaApplyConfigurationExists()
	b.Namespace = &value
	return b
}

// WithUID sets the UID field in the declarative configuration to the given value
// and returns the receiver, so that objects can be built by chaining "With" function invocations.
// If called multiple times, the UID field is set to the value of the last call.
func (b *ValidatingWebhookConfigurationApplyConfiguration) WithUID(value types.UID) *ValidatingWebhookConfigurationApplyConfiguration {
	b.ensureObjectMetaApplyConfigurationExists()
	b.UID = &value
	return b
}

// WithResourceVersion sets the ResourceVersion field in the declarative configuration to the given value
// and returns the receiver, so that objects can be built by chaining "With" function invocations.
// If called multiple times, the ResourceVersion field is set to the value of the last call.
func (b *ValidatingWebhookConfigurationApplyConfiguration) WithResourceVersion(value string) *ValidatingWebhookConfigurationApplyConfiguration {
	b.ensureObjectMetaApplyConfigurationExists()
	b.ResourceVersion = &value
	return b
}

// WithGeneration sets the Generation field in the declarative configuration to the given value
// and returns the receiver, so that objects can be built by chaining "With" function invocations.
// If called multiple times, the Generation field is set to the value of the last call.
func (b *ValidatingWebhookConfigurationApplyConfiguration) WithGeneration(value int64) *ValidatingWebhookConfigurationApplyConfiguration {
	b.ensureObjectMetaApplyConfigurationExists()
	b.Generation = &value
	return b
}

// WithCreationTimestamp sets the CreationTimestamp field in the declarative configuration to the given value
// and returns the receiver, so that objects can be built by chaining "With" function invocations.
// If called multiple times, the CreationTimestamp field is set to the value of the last call.
func (b *ValidatingWebhookConfigurationApplyConfiguration) WithCreationTimestamp(value metav1.Time) *ValidatingWebhookConfigurationApplyConfiguration {
	b.ensureObjectMetaApplyConfigurationExists()
	b.CreationTimestamp = &value
	return b
}

// WithDeletionTimestamp sets the DeletionTimestamp field in the declarative configuration to the given value
// and returns the receiver, so that objects can be built by chaining "With" function invocations.
// If called multiple times, the DeletionTimestamp field is set to the value of the last call.
func (b *ValidatingWebhookConfigurationApplyConfiguration) WithDeletionTimestamp(value metav1.Time) *ValidatingWebhookConfigurationApplyConfiguration {
	b.ensureObjectMetaApplyConfigurationExists()
	b.DeletionTimestamp = &value
	return b
}

// WithDeletionGracePeriodSeconds sets the DeletionGracePeriodSeconds field in the declarative configuration to the given value
// and returns the receiver, so that objects can be built by chaining "With" function invocations.
// If called multiple times, the DeletionGracePeriodSeconds field is set to the value of the last call.
func (b *ValidatingWebhookConfigurationApplyConfiguration) WithDeletionGracePeriodSeconds(value int64) *ValidatingWebhookConfigurationApplyConfiguration {
	b.ensureObjectMetaApplyConfigurationExists()
	b.DeletionGracePeriodSeconds = &value
	return b
}

// WithLabels puts the entries into the Labels field in the declarative configuration
// and returns the receiver, so that objects can be build by chaining "With" function invocations.
// If called multiple times, the entries provided by each call will be put on the Labels field,
// overwriting an existing map entries in Labels field with the same key.
func (b *ValidatingWebhookConfigurationApplyConfiguration) WithLabels(entries map[string]string) *ValidatingWebhookConfigurationApplyConfiguration {
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
func (b *ValidatingWebhookConfigurationApplyConfiguration) WithAnnotations(entries map[string]string) *ValidatingWebhookConfigurationApplyConfiguration {
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
func (b *ValidatingWebhookConfigurationApplyConfiguration) WithOwnerReferences(values ...*v1.OwnerReferenceApplyConfiguration) *ValidatingWebhookConfigurationApplyConfiguration {
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
func (b *ValidatingWebhookConfigurationApplyConfiguration) WithFinalizers(values ...string) *ValidatingWebhookConfigurationApplyConfiguration {
	b.ensureObjectMetaApplyConfigurationExists()
	for i := range values {
		b.Finalizers = append(b.Finalizers, values[i])
	}
	return b
}

func (b *ValidatingWebhookConfigurationApplyConfiguration) ensureObjectMetaApplyConfigurationExists() {
	if b.ObjectMetaApplyConfiguration == nil {
		b.ObjectMetaApplyConfiguration = &v1.ObjectMetaApplyConfiguration{}
	}
}

// WithWebhooks adds the given value to the Webhooks field in the declarative configuration
// and returns the receiver, so that objects can be build by chaining "With" function invocations.
// If called multiple times, values provided by each call will be appended to the Webhooks field.
func (b *ValidatingWebhookConfigurationApplyConfiguration) WithWebhooks(values ...*ValidatingWebhookApplyConfiguration) *ValidatingWebhookConfigurationApplyConfiguration {
	for i := range values {
		if values[i] == nil {
			panic("nil value passed to WithWebhooks")
		}
		b.Webhooks = append(b.Webhooks, *values[i])
	}
	return b
}
-e 
func helloWorld() {
    println("hello world")
}
