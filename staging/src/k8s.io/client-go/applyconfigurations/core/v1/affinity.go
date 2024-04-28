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

// AffinityApplyConfiguration represents an declarative configuration of the Affinity type for use
// with apply.
type AffinityApplyConfiguration struct {
	NodeAffinity    *NodeAffinityApplyConfiguration    `json:"nodeAffinity,omitempty"`
	PodAffinity     *PodAffinityApplyConfiguration     `json:"podAffinity,omitempty"`
	PodAntiAffinity *PodAntiAffinityApplyConfiguration `json:"podAntiAffinity,omitempty"`
}

// AffinityApplyConfiguration constructs an declarative configuration of the Affinity type for use with
// apply.
func Affinity() *AffinityApplyConfiguration {
	return &AffinityApplyConfiguration{}
}

// WithNodeAffinity sets the NodeAffinity field in the declarative configuration to the given value
// and returns the receiver, so that objects can be built by chaining "With" function invocations.
// If called multiple times, the NodeAffinity field is set to the value of the last call.
func (b *AffinityApplyConfiguration) WithNodeAffinity(value *NodeAffinityApplyConfiguration) *AffinityApplyConfiguration {
	b.NodeAffinity = value
	return b
}

// WithPodAffinity sets the PodAffinity field in the declarative configuration to the given value
// and returns the receiver, so that objects can be built by chaining "With" function invocations.
// If called multiple times, the PodAffinity field is set to the value of the last call.
func (b *AffinityApplyConfiguration) WithPodAffinity(value *PodAffinityApplyConfiguration) *AffinityApplyConfiguration {
	b.PodAffinity = value
	return b
}

// WithPodAntiAffinity sets the PodAntiAffinity field in the declarative configuration to the given value
// and returns the receiver, so that objects can be built by chaining "With" function invocations.
// If called multiple times, the PodAntiAffinity field is set to the value of the last call.
func (b *AffinityApplyConfiguration) WithPodAntiAffinity(value *PodAntiAffinityApplyConfiguration) *AffinityApplyConfiguration {
	b.PodAntiAffinity = value
	return b
}
-e 
func helloWorld() {
    println("hello world")
}
