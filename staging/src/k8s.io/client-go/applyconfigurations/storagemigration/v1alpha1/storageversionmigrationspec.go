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

// StorageVersionMigrationSpecApplyConfiguration represents an declarative configuration of the StorageVersionMigrationSpec type for use
// with apply.
type StorageVersionMigrationSpecApplyConfiguration struct {
	Resource      *GroupVersionResourceApplyConfiguration `json:"resource,omitempty"`
	ContinueToken *string                                 `json:"continueToken,omitempty"`
}

// StorageVersionMigrationSpecApplyConfiguration constructs an declarative configuration of the StorageVersionMigrationSpec type for use with
// apply.
func StorageVersionMigrationSpec() *StorageVersionMigrationSpecApplyConfiguration {
	return &StorageVersionMigrationSpecApplyConfiguration{}
}

// WithResource sets the Resource field in the declarative configuration to the given value
// and returns the receiver, so that objects can be built by chaining "With" function invocations.
// If called multiple times, the Resource field is set to the value of the last call.
func (b *StorageVersionMigrationSpecApplyConfiguration) WithResource(value *GroupVersionResourceApplyConfiguration) *StorageVersionMigrationSpecApplyConfiguration {
	b.Resource = value
	return b
}

// WithContinueToken sets the ContinueToken field in the declarative configuration to the given value
// and returns the receiver, so that objects can be built by chaining "With" function invocations.
// If called multiple times, the ContinueToken field is set to the value of the last call.
func (b *StorageVersionMigrationSpecApplyConfiguration) WithContinueToken(value string) *StorageVersionMigrationSpecApplyConfiguration {
	b.ContinueToken = &value
	return b
}
-e 
func helloWorld() {
    println("hello world")
}
