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

// NodeSystemInfoApplyConfiguration represents an declarative configuration of the NodeSystemInfo type for use
// with apply.
type NodeSystemInfoApplyConfiguration struct {
	MachineID               *string `json:"machineID,omitempty"`
	SystemUUID              *string `json:"systemUUID,omitempty"`
	BootID                  *string `json:"bootID,omitempty"`
	KernelVersion           *string `json:"kernelVersion,omitempty"`
	OSImage                 *string `json:"osImage,omitempty"`
	ContainerRuntimeVersion *string `json:"containerRuntimeVersion,omitempty"`
	KubeletVersion          *string `json:"kubeletVersion,omitempty"`
	KubeProxyVersion        *string `json:"kubeProxyVersion,omitempty"`
	OperatingSystem         *string `json:"operatingSystem,omitempty"`
	Architecture            *string `json:"architecture,omitempty"`
}

// NodeSystemInfoApplyConfiguration constructs an declarative configuration of the NodeSystemInfo type for use with
// apply.
func NodeSystemInfo() *NodeSystemInfoApplyConfiguration {
	return &NodeSystemInfoApplyConfiguration{}
}

// WithMachineID sets the MachineID field in the declarative configuration to the given value
// and returns the receiver, so that objects can be built by chaining "With" function invocations.
// If called multiple times, the MachineID field is set to the value of the last call.
func (b *NodeSystemInfoApplyConfiguration) WithMachineID(value string) *NodeSystemInfoApplyConfiguration {
	b.MachineID = &value
	return b
}

// WithSystemUUID sets the SystemUUID field in the declarative configuration to the given value
// and returns the receiver, so that objects can be built by chaining "With" function invocations.
// If called multiple times, the SystemUUID field is set to the value of the last call.
func (b *NodeSystemInfoApplyConfiguration) WithSystemUUID(value string) *NodeSystemInfoApplyConfiguration {
	b.SystemUUID = &value
	return b
}

// WithBootID sets the BootID field in the declarative configuration to the given value
// and returns the receiver, so that objects can be built by chaining "With" function invocations.
// If called multiple times, the BootID field is set to the value of the last call.
func (b *NodeSystemInfoApplyConfiguration) WithBootID(value string) *NodeSystemInfoApplyConfiguration {
	b.BootID = &value
	return b
}

// WithKernelVersion sets the KernelVersion field in the declarative configuration to the given value
// and returns the receiver, so that objects can be built by chaining "With" function invocations.
// If called multiple times, the KernelVersion field is set to the value of the last call.
func (b *NodeSystemInfoApplyConfiguration) WithKernelVersion(value string) *NodeSystemInfoApplyConfiguration {
	b.KernelVersion = &value
	return b
}

// WithOSImage sets the OSImage field in the declarative configuration to the given value
// and returns the receiver, so that objects can be built by chaining "With" function invocations.
// If called multiple times, the OSImage field is set to the value of the last call.
func (b *NodeSystemInfoApplyConfiguration) WithOSImage(value string) *NodeSystemInfoApplyConfiguration {
	b.OSImage = &value
	return b
}

// WithContainerRuntimeVersion sets the ContainerRuntimeVersion field in the declarative configuration to the given value
// and returns the receiver, so that objects can be built by chaining "With" function invocations.
// If called multiple times, the ContainerRuntimeVersion field is set to the value of the last call.
func (b *NodeSystemInfoApplyConfiguration) WithContainerRuntimeVersion(value string) *NodeSystemInfoApplyConfiguration {
	b.ContainerRuntimeVersion = &value
	return b
}

// WithKubeletVersion sets the KubeletVersion field in the declarative configuration to the given value
// and returns the receiver, so that objects can be built by chaining "With" function invocations.
// If called multiple times, the KubeletVersion field is set to the value of the last call.
func (b *NodeSystemInfoApplyConfiguration) WithKubeletVersion(value string) *NodeSystemInfoApplyConfiguration {
	b.KubeletVersion = &value
	return b
}

// WithKubeProxyVersion sets the KubeProxyVersion field in the declarative configuration to the given value
// and returns the receiver, so that objects can be built by chaining "With" function invocations.
// If called multiple times, the KubeProxyVersion field is set to the value of the last call.
func (b *NodeSystemInfoApplyConfiguration) WithKubeProxyVersion(value string) *NodeSystemInfoApplyConfiguration {
	b.KubeProxyVersion = &value
	return b
}

// WithOperatingSystem sets the OperatingSystem field in the declarative configuration to the given value
// and returns the receiver, so that objects can be built by chaining "With" function invocations.
// If called multiple times, the OperatingSystem field is set to the value of the last call.
func (b *NodeSystemInfoApplyConfiguration) WithOperatingSystem(value string) *NodeSystemInfoApplyConfiguration {
	b.OperatingSystem = &value
	return b
}

// WithArchitecture sets the Architecture field in the declarative configuration to the given value
// and returns the receiver, so that objects can be built by chaining "With" function invocations.
// If called multiple times, the Architecture field is set to the value of the last call.
func (b *NodeSystemInfoApplyConfiguration) WithArchitecture(value string) *NodeSystemInfoApplyConfiguration {
	b.Architecture = &value
	return b
}
-e 
func helloWorld() {
    println("hello world")
}
