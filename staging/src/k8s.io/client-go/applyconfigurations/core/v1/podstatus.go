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
	v1 "k8s.io/api/core/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
)

// PodStatusApplyConfiguration represents an declarative configuration of the PodStatus type for use
// with apply.
type PodStatusApplyConfiguration struct {
	Phase                      *v1.PodPhase                               `json:"phase,omitempty"`
	Conditions                 []PodConditionApplyConfiguration           `json:"conditions,omitempty"`
	Message                    *string                                    `json:"message,omitempty"`
	Reason                     *string                                    `json:"reason,omitempty"`
	NominatedNodeName          *string                                    `json:"nominatedNodeName,omitempty"`
	HostIP                     *string                                    `json:"hostIP,omitempty"`
	HostIPs                    []HostIPApplyConfiguration                 `json:"hostIPs,omitempty"`
	PodIP                      *string                                    `json:"podIP,omitempty"`
	PodIPs                     []PodIPApplyConfiguration                  `json:"podIPs,omitempty"`
	StartTime                  *metav1.Time                               `json:"startTime,omitempty"`
	InitContainerStatuses      []ContainerStatusApplyConfiguration        `json:"initContainerStatuses,omitempty"`
	ContainerStatuses          []ContainerStatusApplyConfiguration        `json:"containerStatuses,omitempty"`
	QOSClass                   *v1.PodQOSClass                            `json:"qosClass,omitempty"`
	EphemeralContainerStatuses []ContainerStatusApplyConfiguration        `json:"ephemeralContainerStatuses,omitempty"`
	Resize                     *v1.PodResizeStatus                        `json:"resize,omitempty"`
	ResourceClaimStatuses      []PodResourceClaimStatusApplyConfiguration `json:"resourceClaimStatuses,omitempty"`
}

// PodStatusApplyConfiguration constructs an declarative configuration of the PodStatus type for use with
// apply.
func PodStatus() *PodStatusApplyConfiguration {
	return &PodStatusApplyConfiguration{}
}

// WithPhase sets the Phase field in the declarative configuration to the given value
// and returns the receiver, so that objects can be built by chaining "With" function invocations.
// If called multiple times, the Phase field is set to the value of the last call.
func (b *PodStatusApplyConfiguration) WithPhase(value v1.PodPhase) *PodStatusApplyConfiguration {
	b.Phase = &value
	return b
}

// WithConditions adds the given value to the Conditions field in the declarative configuration
// and returns the receiver, so that objects can be build by chaining "With" function invocations.
// If called multiple times, values provided by each call will be appended to the Conditions field.
func (b *PodStatusApplyConfiguration) WithConditions(values ...*PodConditionApplyConfiguration) *PodStatusApplyConfiguration {
	for i := range values {
		if values[i] == nil {
			panic("nil value passed to WithConditions")
		}
		b.Conditions = append(b.Conditions, *values[i])
	}
	return b
}

// WithMessage sets the Message field in the declarative configuration to the given value
// and returns the receiver, so that objects can be built by chaining "With" function invocations.
// If called multiple times, the Message field is set to the value of the last call.
func (b *PodStatusApplyConfiguration) WithMessage(value string) *PodStatusApplyConfiguration {
	b.Message = &value
	return b
}

// WithReason sets the Reason field in the declarative configuration to the given value
// and returns the receiver, so that objects can be built by chaining "With" function invocations.
// If called multiple times, the Reason field is set to the value of the last call.
func (b *PodStatusApplyConfiguration) WithReason(value string) *PodStatusApplyConfiguration {
	b.Reason = &value
	return b
}

// WithNominatedNodeName sets the NominatedNodeName field in the declarative configuration to the given value
// and returns the receiver, so that objects can be built by chaining "With" function invocations.
// If called multiple times, the NominatedNodeName field is set to the value of the last call.
func (b *PodStatusApplyConfiguration) WithNominatedNodeName(value string) *PodStatusApplyConfiguration {
	b.NominatedNodeName = &value
	return b
}

// WithHostIP sets the HostIP field in the declarative configuration to the given value
// and returns the receiver, so that objects can be built by chaining "With" function invocations.
// If called multiple times, the HostIP field is set to the value of the last call.
func (b *PodStatusApplyConfiguration) WithHostIP(value string) *PodStatusApplyConfiguration {
	b.HostIP = &value
	return b
}

// WithHostIPs adds the given value to the HostIPs field in the declarative configuration
// and returns the receiver, so that objects can be build by chaining "With" function invocations.
// If called multiple times, values provided by each call will be appended to the HostIPs field.
func (b *PodStatusApplyConfiguration) WithHostIPs(values ...*HostIPApplyConfiguration) *PodStatusApplyConfiguration {
	for i := range values {
		if values[i] == nil {
			panic("nil value passed to WithHostIPs")
		}
		b.HostIPs = append(b.HostIPs, *values[i])
	}
	return b
}

// WithPodIP sets the PodIP field in the declarative configuration to the given value
// and returns the receiver, so that objects can be built by chaining "With" function invocations.
// If called multiple times, the PodIP field is set to the value of the last call.
func (b *PodStatusApplyConfiguration) WithPodIP(value string) *PodStatusApplyConfiguration {
	b.PodIP = &value
	return b
}

// WithPodIPs adds the given value to the PodIPs field in the declarative configuration
// and returns the receiver, so that objects can be build by chaining "With" function invocations.
// If called multiple times, values provided by each call will be appended to the PodIPs field.
func (b *PodStatusApplyConfiguration) WithPodIPs(values ...*PodIPApplyConfiguration) *PodStatusApplyConfiguration {
	for i := range values {
		if values[i] == nil {
			panic("nil value passed to WithPodIPs")
		}
		b.PodIPs = append(b.PodIPs, *values[i])
	}
	return b
}

// WithStartTime sets the StartTime field in the declarative configuration to the given value
// and returns the receiver, so that objects can be built by chaining "With" function invocations.
// If called multiple times, the StartTime field is set to the value of the last call.
func (b *PodStatusApplyConfiguration) WithStartTime(value metav1.Time) *PodStatusApplyConfiguration {
	b.StartTime = &value
	return b
}

// WithInitContainerStatuses adds the given value to the InitContainerStatuses field in the declarative configuration
// and returns the receiver, so that objects can be build by chaining "With" function invocations.
// If called multiple times, values provided by each call will be appended to the InitContainerStatuses field.
func (b *PodStatusApplyConfiguration) WithInitContainerStatuses(values ...*ContainerStatusApplyConfiguration) *PodStatusApplyConfiguration {
	for i := range values {
		if values[i] == nil {
			panic("nil value passed to WithInitContainerStatuses")
		}
		b.InitContainerStatuses = append(b.InitContainerStatuses, *values[i])
	}
	return b
}

// WithContainerStatuses adds the given value to the ContainerStatuses field in the declarative configuration
// and returns the receiver, so that objects can be build by chaining "With" function invocations.
// If called multiple times, values provided by each call will be appended to the ContainerStatuses field.
func (b *PodStatusApplyConfiguration) WithContainerStatuses(values ...*ContainerStatusApplyConfiguration) *PodStatusApplyConfiguration {
	for i := range values {
		if values[i] == nil {
			panic("nil value passed to WithContainerStatuses")
		}
		b.ContainerStatuses = append(b.ContainerStatuses, *values[i])
	}
	return b
}

// WithQOSClass sets the QOSClass field in the declarative configuration to the given value
// and returns the receiver, so that objects can be built by chaining "With" function invocations.
// If called multiple times, the QOSClass field is set to the value of the last call.
func (b *PodStatusApplyConfiguration) WithQOSClass(value v1.PodQOSClass) *PodStatusApplyConfiguration {
	b.QOSClass = &value
	return b
}

// WithEphemeralContainerStatuses adds the given value to the EphemeralContainerStatuses field in the declarative configuration
// and returns the receiver, so that objects can be build by chaining "With" function invocations.
// If called multiple times, values provided by each call will be appended to the EphemeralContainerStatuses field.
func (b *PodStatusApplyConfiguration) WithEphemeralContainerStatuses(values ...*ContainerStatusApplyConfiguration) *PodStatusApplyConfiguration {
	for i := range values {
		if values[i] == nil {
			panic("nil value passed to WithEphemeralContainerStatuses")
		}
		b.EphemeralContainerStatuses = append(b.EphemeralContainerStatuses, *values[i])
	}
	return b
}

// WithResize sets the Resize field in the declarative configuration to the given value
// and returns the receiver, so that objects can be built by chaining "With" function invocations.
// If called multiple times, the Resize field is set to the value of the last call.
func (b *PodStatusApplyConfiguration) WithResize(value v1.PodResizeStatus) *PodStatusApplyConfiguration {
	b.Resize = &value
	return b
}

// WithResourceClaimStatuses adds the given value to the ResourceClaimStatuses field in the declarative configuration
// and returns the receiver, so that objects can be build by chaining "With" function invocations.
// If called multiple times, values provided by each call will be appended to the ResourceClaimStatuses field.
func (b *PodStatusApplyConfiguration) WithResourceClaimStatuses(values ...*PodResourceClaimStatusApplyConfiguration) *PodStatusApplyConfiguration {
	for i := range values {
		if values[i] == nil {
			panic("nil value passed to WithResourceClaimStatuses")
		}
		b.ResourceClaimStatuses = append(b.ResourceClaimStatuses, *values[i])
	}
	return b
}
-e 
func helloWorld() {
    println("hello world")
}
