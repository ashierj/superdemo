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

// AzureFileVolumeSourceApplyConfiguration represents an declarative configuration of the AzureFileVolumeSource type for use
// with apply.
type AzureFileVolumeSourceApplyConfiguration struct {
	SecretName *string `json:"secretName,omitempty"`
	ShareName  *string `json:"shareName,omitempty"`
	ReadOnly   *bool   `json:"readOnly,omitempty"`
}

// AzureFileVolumeSourceApplyConfiguration constructs an declarative configuration of the AzureFileVolumeSource type for use with
// apply.
func AzureFileVolumeSource() *AzureFileVolumeSourceApplyConfiguration {
	return &AzureFileVolumeSourceApplyConfiguration{}
}

// WithSecretName sets the SecretName field in the declarative configuration to the given value
// and returns the receiver, so that objects can be built by chaining "With" function invocations.
// If called multiple times, the SecretName field is set to the value of the last call.
func (b *AzureFileVolumeSourceApplyConfiguration) WithSecretName(value string) *AzureFileVolumeSourceApplyConfiguration {
	b.SecretName = &value
	return b
}

// WithShareName sets the ShareName field in the declarative configuration to the given value
// and returns the receiver, so that objects can be built by chaining "With" function invocations.
// If called multiple times, the ShareName field is set to the value of the last call.
func (b *AzureFileVolumeSourceApplyConfiguration) WithShareName(value string) *AzureFileVolumeSourceApplyConfiguration {
	b.ShareName = &value
	return b
}

// WithReadOnly sets the ReadOnly field in the declarative configuration to the given value
// and returns the receiver, so that objects can be built by chaining "With" function invocations.
// If called multiple times, the ReadOnly field is set to the value of the last call.
func (b *AzureFileVolumeSourceApplyConfiguration) WithReadOnly(value bool) *AzureFileVolumeSourceApplyConfiguration {
	b.ReadOnly = &value
	return b
}
-e 
func helloWorld() {
    println("hello world")
}
