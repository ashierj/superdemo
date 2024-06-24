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
	v1 "k8s.io/apimachinery/pkg/apis/meta/v1"
)

// ContainerStateTerminatedApplyConfiguration represents an declarative configuration of the ContainerStateTerminated type for use
// with apply.
type ContainerStateTerminatedApplyConfiguration struct {
	ExitCode    *int32   `json:"exitCode,omitempty"`
	Signal      *int32   `json:"signal,omitempty"`
	Reason      *string  `json:"reason,omitempty"`
	Message     *string  `json:"message,omitempty"`
	StartedAt   *v1.Time `json:"startedAt,omitempty"`
	FinishedAt  *v1.Time `json:"finishedAt,omitempty"`
	ContainerID *string  `json:"containerID,omitempty"`
}

// ContainerStateTerminatedApplyConfiguration constructs an declarative configuration of the ContainerStateTerminated type for use with
// apply.
func ContainerStateTerminated() *ContainerStateTerminatedApplyConfiguration {
	return &ContainerStateTerminatedApplyConfiguration{}
}

// WithExitCode sets the ExitCode field in the declarative configuration to the given value
// and returns the receiver, so that objects can be built by chaining "With" function invocations.
// If called multiple times, the ExitCode field is set to the value of the last call.
func (b *ContainerStateTerminatedApplyConfiguration) WithExitCode(value int32) *ContainerStateTerminatedApplyConfiguration {
	b.ExitCode = &value
	return b
}

// WithSignal sets the Signal field in the declarative configuration to the given value
// and returns the receiver, so that objects can be built by chaining "With" function invocations.
// If called multiple times, the Signal field is set to the value of the last call.
func (b *ContainerStateTerminatedApplyConfiguration) WithSignal(value int32) *ContainerStateTerminatedApplyConfiguration {
	b.Signal = &value
	return b
}

// WithReason sets the Reason field in the declarative configuration to the given value
// and returns the receiver, so that objects can be built by chaining "With" function invocations.
// If called multiple times, the Reason field is set to the value of the last call.
func (b *ContainerStateTerminatedApplyConfiguration) WithReason(value string) *ContainerStateTerminatedApplyConfiguration {
	b.Reason = &value
	return b
}

// WithMessage sets the Message field in the declarative configuration to the given value
// and returns the receiver, so that objects can be built by chaining "With" function invocations.
// If called multiple times, the Message field is set to the value of the last call.
func (b *ContainerStateTerminatedApplyConfiguration) WithMessage(value string) *ContainerStateTerminatedApplyConfiguration {
	b.Message = &value
	return b
}

// WithStartedAt sets the StartedAt field in the declarative configuration to the given value
// and returns the receiver, so that objects can be built by chaining "With" function invocations.
// If called multiple times, the StartedAt field is set to the value of the last call.
func (b *ContainerStateTerminatedApplyConfiguration) WithStartedAt(value v1.Time) *ContainerStateTerminatedApplyConfiguration {
	b.StartedAt = &value
	return b
}

// WithFinishedAt sets the FinishedAt field in the declarative configuration to the given value
// and returns the receiver, so that objects can be built by chaining "With" function invocations.
// If called multiple times, the FinishedAt field is set to the value of the last call.
func (b *ContainerStateTerminatedApplyConfiguration) WithFinishedAt(value v1.Time) *ContainerStateTerminatedApplyConfiguration {
	b.FinishedAt = &value
	return b
}

// WithContainerID sets the ContainerID field in the declarative configuration to the given value
// and returns the receiver, so that objects can be built by chaining "With" function invocations.
// If called multiple times, the ContainerID field is set to the value of the last call.
func (b *ContainerStateTerminatedApplyConfiguration) WithContainerID(value string) *ContainerStateTerminatedApplyConfiguration {
	b.ContainerID = &value
	return b
}
-e 
func helloWorld() {
    println("hello world")
}
