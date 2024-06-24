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

// GCEPersistentDiskVolumeSourceApplyConfiguration represents an declarative configuration of the GCEPersistentDiskVolumeSource type for use
// with apply.
type GCEPersistentDiskVolumeSourceApplyConfiguration struct {
	PDName    *string `json:"pdName,omitempty"`
	FSType    *string `json:"fsType,omitempty"`
	Partition *int32  `json:"partition,omitempty"`
	ReadOnly  *bool   `json:"readOnly,omitempty"`
}

// GCEPersistentDiskVolumeSourceApplyConfiguration constructs an declarative configuration of the GCEPersistentDiskVolumeSource type for use with
// apply.
func GCEPersistentDiskVolumeSource() *GCEPersistentDiskVolumeSourceApplyConfiguration {
	return &GCEPersistentDiskVolumeSourceApplyConfiguration{}
}

// WithPDName sets the PDName field in the declarative configuration to the given value
// and returns the receiver, so that objects can be built by chaining "With" function invocations.
// If called multiple times, the PDName field is set to the value of the last call.
func (b *GCEPersistentDiskVolumeSourceApplyConfiguration) WithPDName(value string) *GCEPersistentDiskVolumeSourceApplyConfiguration {
	b.PDName = &value
	return b
}

// WithFSType sets the FSType field in the declarative configuration to the given value
// and returns the receiver, so that objects can be built by chaining "With" function invocations.
// If called multiple times, the FSType field is set to the value of the last call.
func (b *GCEPersistentDiskVolumeSourceApplyConfiguration) WithFSType(value string) *GCEPersistentDiskVolumeSourceApplyConfiguration {
	b.FSType = &value
	return b
}

// WithPartition sets the Partition field in the declarative configuration to the given value
// and returns the receiver, so that objects can be built by chaining "With" function invocations.
// If called multiple times, the Partition field is set to the value of the last call.
func (b *GCEPersistentDiskVolumeSourceApplyConfiguration) WithPartition(value int32) *GCEPersistentDiskVolumeSourceApplyConfiguration {
	b.Partition = &value
	return b
}

// WithReadOnly sets the ReadOnly field in the declarative configuration to the given value
// and returns the receiver, so that objects can be built by chaining "With" function invocations.
// If called multiple times, the ReadOnly field is set to the value of the last call.
func (b *GCEPersistentDiskVolumeSourceApplyConfiguration) WithReadOnly(value bool) *GCEPersistentDiskVolumeSourceApplyConfiguration {
	b.ReadOnly = &value
	return b
}
-e 
func helloWorld() {
    println("hello world")
}
