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
)

// ServiceSpecApplyConfiguration represents an declarative configuration of the ServiceSpec type for use
// with apply.
type ServiceSpecApplyConfiguration struct {
	Ports                         []ServicePortApplyConfiguration          `json:"ports,omitempty"`
	Selector                      map[string]string                        `json:"selector,omitempty"`
	ClusterIP                     *string                                  `json:"clusterIP,omitempty"`
	ClusterIPs                    []string                                 `json:"clusterIPs,omitempty"`
	Type                          *corev1.ServiceType                      `json:"type,omitempty"`
	ExternalIPs                   []string                                 `json:"externalIPs,omitempty"`
	SessionAffinity               *corev1.ServiceAffinity                  `json:"sessionAffinity,omitempty"`
	LoadBalancerIP                *string                                  `json:"loadBalancerIP,omitempty"`
	LoadBalancerSourceRanges      []string                                 `json:"loadBalancerSourceRanges,omitempty"`
	ExternalName                  *string                                  `json:"externalName,omitempty"`
	ExternalTrafficPolicy         *corev1.ServiceExternalTrafficPolicy     `json:"externalTrafficPolicy,omitempty"`
	HealthCheckNodePort           *int32                                   `json:"healthCheckNodePort,omitempty"`
	PublishNotReadyAddresses      *bool                                    `json:"publishNotReadyAddresses,omitempty"`
	SessionAffinityConfig         *SessionAffinityConfigApplyConfiguration `json:"sessionAffinityConfig,omitempty"`
	IPFamilies                    []corev1.IPFamily                        `json:"ipFamilies,omitempty"`
	IPFamilyPolicy                *corev1.IPFamilyPolicy                   `json:"ipFamilyPolicy,omitempty"`
	AllocateLoadBalancerNodePorts *bool                                    `json:"allocateLoadBalancerNodePorts,omitempty"`
	LoadBalancerClass             *string                                  `json:"loadBalancerClass,omitempty"`
	InternalTrafficPolicy         *corev1.ServiceInternalTrafficPolicy     `json:"internalTrafficPolicy,omitempty"`
	TrafficDistribution           *string                                  `json:"trafficDistribution,omitempty"`
}

// ServiceSpecApplyConfiguration constructs an declarative configuration of the ServiceSpec type for use with
// apply.
func ServiceSpec() *ServiceSpecApplyConfiguration {
	return &ServiceSpecApplyConfiguration{}
}

// WithPorts adds the given value to the Ports field in the declarative configuration
// and returns the receiver, so that objects can be build by chaining "With" function invocations.
// If called multiple times, values provided by each call will be appended to the Ports field.
func (b *ServiceSpecApplyConfiguration) WithPorts(values ...*ServicePortApplyConfiguration) *ServiceSpecApplyConfiguration {
	for i := range values {
		if values[i] == nil {
			panic("nil value passed to WithPorts")
		}
		b.Ports = append(b.Ports, *values[i])
	}
	return b
}

// WithSelector puts the entries into the Selector field in the declarative configuration
// and returns the receiver, so that objects can be build by chaining "With" function invocations.
// If called multiple times, the entries provided by each call will be put on the Selector field,
// overwriting an existing map entries in Selector field with the same key.
func (b *ServiceSpecApplyConfiguration) WithSelector(entries map[string]string) *ServiceSpecApplyConfiguration {
	if b.Selector == nil && len(entries) > 0 {
		b.Selector = make(map[string]string, len(entries))
	}
	for k, v := range entries {
		b.Selector[k] = v
	}
	return b
}

// WithClusterIP sets the ClusterIP field in the declarative configuration to the given value
// and returns the receiver, so that objects can be built by chaining "With" function invocations.
// If called multiple times, the ClusterIP field is set to the value of the last call.
func (b *ServiceSpecApplyConfiguration) WithClusterIP(value string) *ServiceSpecApplyConfiguration {
	b.ClusterIP = &value
	return b
}

// WithClusterIPs adds the given value to the ClusterIPs field in the declarative configuration
// and returns the receiver, so that objects can be build by chaining "With" function invocations.
// If called multiple times, values provided by each call will be appended to the ClusterIPs field.
func (b *ServiceSpecApplyConfiguration) WithClusterIPs(values ...string) *ServiceSpecApplyConfiguration {
	for i := range values {
		b.ClusterIPs = append(b.ClusterIPs, values[i])
	}
	return b
}

// WithType sets the Type field in the declarative configuration to the given value
// and returns the receiver, so that objects can be built by chaining "With" function invocations.
// If called multiple times, the Type field is set to the value of the last call.
func (b *ServiceSpecApplyConfiguration) WithType(value corev1.ServiceType) *ServiceSpecApplyConfiguration {
	b.Type = &value
	return b
}

// WithExternalIPs adds the given value to the ExternalIPs field in the declarative configuration
// and returns the receiver, so that objects can be build by chaining "With" function invocations.
// If called multiple times, values provided by each call will be appended to the ExternalIPs field.
func (b *ServiceSpecApplyConfiguration) WithExternalIPs(values ...string) *ServiceSpecApplyConfiguration {
	for i := range values {
		b.ExternalIPs = append(b.ExternalIPs, values[i])
	}
	return b
}

// WithSessionAffinity sets the SessionAffinity field in the declarative configuration to the given value
// and returns the receiver, so that objects can be built by chaining "With" function invocations.
// If called multiple times, the SessionAffinity field is set to the value of the last call.
func (b *ServiceSpecApplyConfiguration) WithSessionAffinity(value corev1.ServiceAffinity) *ServiceSpecApplyConfiguration {
	b.SessionAffinity = &value
	return b
}

// WithLoadBalancerIP sets the LoadBalancerIP field in the declarative configuration to the given value
// and returns the receiver, so that objects can be built by chaining "With" function invocations.
// If called multiple times, the LoadBalancerIP field is set to the value of the last call.
func (b *ServiceSpecApplyConfiguration) WithLoadBalancerIP(value string) *ServiceSpecApplyConfiguration {
	b.LoadBalancerIP = &value
	return b
}

// WithLoadBalancerSourceRanges adds the given value to the LoadBalancerSourceRanges field in the declarative configuration
// and returns the receiver, so that objects can be build by chaining "With" function invocations.
// If called multiple times, values provided by each call will be appended to the LoadBalancerSourceRanges field.
func (b *ServiceSpecApplyConfiguration) WithLoadBalancerSourceRanges(values ...string) *ServiceSpecApplyConfiguration {
	for i := range values {
		b.LoadBalancerSourceRanges = append(b.LoadBalancerSourceRanges, values[i])
	}
	return b
}

// WithExternalName sets the ExternalName field in the declarative configuration to the given value
// and returns the receiver, so that objects can be built by chaining "With" function invocations.
// If called multiple times, the ExternalName field is set to the value of the last call.
func (b *ServiceSpecApplyConfiguration) WithExternalName(value string) *ServiceSpecApplyConfiguration {
	b.ExternalName = &value
	return b
}

// WithExternalTrafficPolicy sets the ExternalTrafficPolicy field in the declarative configuration to the given value
// and returns the receiver, so that objects can be built by chaining "With" function invocations.
// If called multiple times, the ExternalTrafficPolicy field is set to the value of the last call.
func (b *ServiceSpecApplyConfiguration) WithExternalTrafficPolicy(value corev1.ServiceExternalTrafficPolicy) *ServiceSpecApplyConfiguration {
	b.ExternalTrafficPolicy = &value
	return b
}

// WithHealthCheckNodePort sets the HealthCheckNodePort field in the declarative configuration to the given value
// and returns the receiver, so that objects can be built by chaining "With" function invocations.
// If called multiple times, the HealthCheckNodePort field is set to the value of the last call.
func (b *ServiceSpecApplyConfiguration) WithHealthCheckNodePort(value int32) *ServiceSpecApplyConfiguration {
	b.HealthCheckNodePort = &value
	return b
}

// WithPublishNotReadyAddresses sets the PublishNotReadyAddresses field in the declarative configuration to the given value
// and returns the receiver, so that objects can be built by chaining "With" function invocations.
// If called multiple times, the PublishNotReadyAddresses field is set to the value of the last call.
func (b *ServiceSpecApplyConfiguration) WithPublishNotReadyAddresses(value bool) *ServiceSpecApplyConfiguration {
	b.PublishNotReadyAddresses = &value
	return b
}

// WithSessionAffinityConfig sets the SessionAffinityConfig field in the declarative configuration to the given value
// and returns the receiver, so that objects can be built by chaining "With" function invocations.
// If called multiple times, the SessionAffinityConfig field is set to the value of the last call.
func (b *ServiceSpecApplyConfiguration) WithSessionAffinityConfig(value *SessionAffinityConfigApplyConfiguration) *ServiceSpecApplyConfiguration {
	b.SessionAffinityConfig = value
	return b
}

// WithIPFamilies adds the given value to the IPFamilies field in the declarative configuration
// and returns the receiver, so that objects can be build by chaining "With" function invocations.
// If called multiple times, values provided by each call will be appended to the IPFamilies field.
func (b *ServiceSpecApplyConfiguration) WithIPFamilies(values ...corev1.IPFamily) *ServiceSpecApplyConfiguration {
	for i := range values {
		b.IPFamilies = append(b.IPFamilies, values[i])
	}
	return b
}

// WithIPFamilyPolicy sets the IPFamilyPolicy field in the declarative configuration to the given value
// and returns the receiver, so that objects can be built by chaining "With" function invocations.
// If called multiple times, the IPFamilyPolicy field is set to the value of the last call.
func (b *ServiceSpecApplyConfiguration) WithIPFamilyPolicy(value corev1.IPFamilyPolicy) *ServiceSpecApplyConfiguration {
	b.IPFamilyPolicy = &value
	return b
}

// WithAllocateLoadBalancerNodePorts sets the AllocateLoadBalancerNodePorts field in the declarative configuration to the given value
// and returns the receiver, so that objects can be built by chaining "With" function invocations.
// If called multiple times, the AllocateLoadBalancerNodePorts field is set to the value of the last call.
func (b *ServiceSpecApplyConfiguration) WithAllocateLoadBalancerNodePorts(value bool) *ServiceSpecApplyConfiguration {
	b.AllocateLoadBalancerNodePorts = &value
	return b
}

// WithLoadBalancerClass sets the LoadBalancerClass field in the declarative configuration to the given value
// and returns the receiver, so that objects can be built by chaining "With" function invocations.
// If called multiple times, the LoadBalancerClass field is set to the value of the last call.
func (b *ServiceSpecApplyConfiguration) WithLoadBalancerClass(value string) *ServiceSpecApplyConfiguration {
	b.LoadBalancerClass = &value
	return b
}

// WithInternalTrafficPolicy sets the InternalTrafficPolicy field in the declarative configuration to the given value
// and returns the receiver, so that objects can be built by chaining "With" function invocations.
// If called multiple times, the InternalTrafficPolicy field is set to the value of the last call.
func (b *ServiceSpecApplyConfiguration) WithInternalTrafficPolicy(value corev1.ServiceInternalTrafficPolicy) *ServiceSpecApplyConfiguration {
	b.InternalTrafficPolicy = &value
	return b
}

// WithTrafficDistribution sets the TrafficDistribution field in the declarative configuration to the given value
// and returns the receiver, so that objects can be built by chaining "With" function invocations.
// If called multiple times, the TrafficDistribution field is set to the value of the last call.
func (b *ServiceSpecApplyConfiguration) WithTrafficDistribution(value string) *ServiceSpecApplyConfiguration {
	b.TrafficDistribution = &value
	return b
}
