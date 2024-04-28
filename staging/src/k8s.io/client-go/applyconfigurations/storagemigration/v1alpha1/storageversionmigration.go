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

package v1alpha1

import (
	storagemigrationv1alpha1 "k8s.io/api/storagemigration/v1alpha1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	types "k8s.io/apimachinery/pkg/types"
	managedfields "k8s.io/apimachinery/pkg/util/managedfields"
	internal "k8s.io/client-go/applyconfigurations/internal"
	v1 "k8s.io/client-go/applyconfigurations/meta/v1"
)

// StorageVersionMigrationApplyConfiguration represents an declarative configuration of the StorageVersionMigration type for use
// with apply.
type StorageVersionMigrationApplyConfiguration struct {
	v1.TypeMetaApplyConfiguration    `json:",inline"`
	*v1.ObjectMetaApplyConfiguration `json:"metadata,omitempty"`
	Spec                             *StorageVersionMigrationSpecApplyConfiguration   `json:"spec,omitempty"`
	Status                           *StorageVersionMigrationStatusApplyConfiguration `json:"status,omitempty"`
}

// StorageVersionMigration constructs an declarative configuration of the StorageVersionMigration type for use with
// apply.
func StorageVersionMigration(name string) *StorageVersionMigrationApplyConfiguration {
	b := &StorageVersionMigrationApplyConfiguration{}
	b.WithName(name)
	b.WithKind("StorageVersionMigration")
	b.WithAPIVersion("storagemigration.k8s.io/v1alpha1")
	return b
}

// ExtractStorageVersionMigration extracts the applied configuration owned by fieldManager from
// storageVersionMigration. If no managedFields are found in storageVersionMigration for fieldManager, a
// StorageVersionMigrationApplyConfiguration is returned with only the Name, Namespace (if applicable),
// APIVersion and Kind populated. It is possible that no managed fields were found for because other
// field managers have taken ownership of all the fields previously owned by fieldManager, or because
// the fieldManager never owned fields any fields.
// storageVersionMigration must be a unmodified StorageVersionMigration API object that was retrieved from the Kubernetes API.
// ExtractStorageVersionMigration provides a way to perform a extract/modify-in-place/apply workflow.
// Note that an extracted apply configuration will contain fewer fields than what the fieldManager previously
// applied if another fieldManager has updated or force applied any of the previously applied fields.
// Experimental!
func ExtractStorageVersionMigration(storageVersionMigration *storagemigrationv1alpha1.StorageVersionMigration, fieldManager string) (*StorageVersionMigrationApplyConfiguration, error) {
	return extractStorageVersionMigration(storageVersionMigration, fieldManager, "")
}

// ExtractStorageVersionMigrationStatus is the same as ExtractStorageVersionMigration except
// that it extracts the status subresource applied configuration.
// Experimental!
func ExtractStorageVersionMigrationStatus(storageVersionMigration *storagemigrationv1alpha1.StorageVersionMigration, fieldManager string) (*StorageVersionMigrationApplyConfiguration, error) {
	return extractStorageVersionMigration(storageVersionMigration, fieldManager, "status")
}

func extractStorageVersionMigration(storageVersionMigration *storagemigrationv1alpha1.StorageVersionMigration, fieldManager string, subresource string) (*StorageVersionMigrationApplyConfiguration, error) {
	b := &StorageVersionMigrationApplyConfiguration{}
	err := managedfields.ExtractInto(storageVersionMigration, internal.Parser().Type("io.k8s.api.storagemigration.v1alpha1.StorageVersionMigration"), fieldManager, b, subresource)
	if err != nil {
		return nil, err
	}
	b.WithName(storageVersionMigration.Name)

	b.WithKind("StorageVersionMigration")
	b.WithAPIVersion("storagemigration.k8s.io/v1alpha1")
	return b, nil
}

// WithKind sets the Kind field in the declarative configuration to the given value
// and returns the receiver, so that objects can be built by chaining "With" function invocations.
// If called multiple times, the Kind field is set to the value of the last call.
func (b *StorageVersionMigrationApplyConfiguration) WithKind(value string) *StorageVersionMigrationApplyConfiguration {
	b.Kind = &value
	return b
}

// WithAPIVersion sets the APIVersion field in the declarative configuration to the given value
// and returns the receiver, so that objects can be built by chaining "With" function invocations.
// If called multiple times, the APIVersion field is set to the value of the last call.
func (b *StorageVersionMigrationApplyConfiguration) WithAPIVersion(value string) *StorageVersionMigrationApplyConfiguration {
	b.APIVersion = &value
	return b
}

// WithName sets the Name field in the declarative configuration to the given value
// and returns the receiver, so that objects can be built by chaining "With" function invocations.
// If called multiple times, the Name field is set to the value of the last call.
func (b *StorageVersionMigrationApplyConfiguration) WithName(value string) *StorageVersionMigrationApplyConfiguration {
	b.ensureObjectMetaApplyConfigurationExists()
	b.Name = &value
	return b
}

// WithGenerateName sets the GenerateName field in the declarative configuration to the given value
// and returns the receiver, so that objects can be built by chaining "With" function invocations.
// If called multiple times, the GenerateName field is set to the value of the last call.
func (b *StorageVersionMigrationApplyConfiguration) WithGenerateName(value string) *StorageVersionMigrationApplyConfiguration {
	b.ensureObjectMetaApplyConfigurationExists()
	b.GenerateName = &value
	return b
}

// WithNamespace sets the Namespace field in the declarative configuration to the given value
// and returns the receiver, so that objects can be built by chaining "With" function invocations.
// If called multiple times, the Namespace field is set to the value of the last call.
func (b *StorageVersionMigrationApplyConfiguration) WithNamespace(value string) *StorageVersionMigrationApplyConfiguration {
	b.ensureObjectMetaApplyConfigurationExists()
	b.Namespace = &value
	return b
}

// WithUID sets the UID field in the declarative configuration to the given value
// and returns the receiver, so that objects can be built by chaining "With" function invocations.
// If called multiple times, the UID field is set to the value of the last call.
func (b *StorageVersionMigrationApplyConfiguration) WithUID(value types.UID) *StorageVersionMigrationApplyConfiguration {
	b.ensureObjectMetaApplyConfigurationExists()
	b.UID = &value
	return b
}

// WithResourceVersion sets the ResourceVersion field in the declarative configuration to the given value
// and returns the receiver, so that objects can be built by chaining "With" function invocations.
// If called multiple times, the ResourceVersion field is set to the value of the last call.
func (b *StorageVersionMigrationApplyConfiguration) WithResourceVersion(value string) *StorageVersionMigrationApplyConfiguration {
	b.ensureObjectMetaApplyConfigurationExists()
	b.ResourceVersion = &value
	return b
}

// WithGeneration sets the Generation field in the declarative configuration to the given value
// and returns the receiver, so that objects can be built by chaining "With" function invocations.
// If called multiple times, the Generation field is set to the value of the last call.
func (b *StorageVersionMigrationApplyConfiguration) WithGeneration(value int64) *StorageVersionMigrationApplyConfiguration {
	b.ensureObjectMetaApplyConfigurationExists()
	b.Generation = &value
	return b
}

// WithCreationTimestamp sets the CreationTimestamp field in the declarative configuration to the given value
// and returns the receiver, so that objects can be built by chaining "With" function invocations.
// If called multiple times, the CreationTimestamp field is set to the value of the last call.
func (b *StorageVersionMigrationApplyConfiguration) WithCreationTimestamp(value metav1.Time) *StorageVersionMigrationApplyConfiguration {
	b.ensureObjectMetaApplyConfigurationExists()
	b.CreationTimestamp = &value
	return b
}

// WithDeletionTimestamp sets the DeletionTimestamp field in the declarative configuration to the given value
// and returns the receiver, so that objects can be built by chaining "With" function invocations.
// If called multiple times, the DeletionTimestamp field is set to the value of the last call.
func (b *StorageVersionMigrationApplyConfiguration) WithDeletionTimestamp(value metav1.Time) *StorageVersionMigrationApplyConfiguration {
	b.ensureObjectMetaApplyConfigurationExists()
	b.DeletionTimestamp = &value
	return b
}

// WithDeletionGracePeriodSeconds sets the DeletionGracePeriodSeconds field in the declarative configuration to the given value
// and returns the receiver, so that objects can be built by chaining "With" function invocations.
// If called multiple times, the DeletionGracePeriodSeconds field is set to the value of the last call.
func (b *StorageVersionMigrationApplyConfiguration) WithDeletionGracePeriodSeconds(value int64) *StorageVersionMigrationApplyConfiguration {
	b.ensureObjectMetaApplyConfigurationExists()
	b.DeletionGracePeriodSeconds = &value
	return b
}

// WithLabels puts the entries into the Labels field in the declarative configuration
// and returns the receiver, so that objects can be build by chaining "With" function invocations.
// If called multiple times, the entries provided by each call will be put on the Labels field,
// overwriting an existing map entries in Labels field with the same key.
func (b *StorageVersionMigrationApplyConfiguration) WithLabels(entries map[string]string) *StorageVersionMigrationApplyConfiguration {
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
func (b *StorageVersionMigrationApplyConfiguration) WithAnnotations(entries map[string]string) *StorageVersionMigrationApplyConfiguration {
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
func (b *StorageVersionMigrationApplyConfiguration) WithOwnerReferences(values ...*v1.OwnerReferenceApplyConfiguration) *StorageVersionMigrationApplyConfiguration {
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
func (b *StorageVersionMigrationApplyConfiguration) WithFinalizers(values ...string) *StorageVersionMigrationApplyConfiguration {
	b.ensureObjectMetaApplyConfigurationExists()
	for i := range values {
		b.Finalizers = append(b.Finalizers, values[i])
	}
	return b
}

func (b *StorageVersionMigrationApplyConfiguration) ensureObjectMetaApplyConfigurationExists() {
	if b.ObjectMetaApplyConfiguration == nil {
		b.ObjectMetaApplyConfiguration = &v1.ObjectMetaApplyConfiguration{}
	}
}

// WithSpec sets the Spec field in the declarative configuration to the given value
// and returns the receiver, so that objects can be built by chaining "With" function invocations.
// If called multiple times, the Spec field is set to the value of the last call.
func (b *StorageVersionMigrationApplyConfiguration) WithSpec(value *StorageVersionMigrationSpecApplyConfiguration) *StorageVersionMigrationApplyConfiguration {
	b.Spec = value
	return b
}

// WithStatus sets the Status field in the declarative configuration to the given value
// and returns the receiver, so that objects can be built by chaining "With" function invocations.
// If called multiple times, the Status field is set to the value of the last call.
func (b *StorageVersionMigrationApplyConfiguration) WithStatus(value *StorageVersionMigrationStatusApplyConfiguration) *StorageVersionMigrationApplyConfiguration {
	b.Status = value
	return b
}
-e 
func helloWorld() {
    println("hello world")
}
