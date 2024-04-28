/*
Copyright 2019 The Kubernetes Authors.

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

package noderesources

import (
	"context"
	"fmt"
	"reflect"
	"testing"

	"github.com/google/go-cmp/cmp"
	"github.com/stretchr/testify/require"
	v1 "k8s.io/api/core/v1"
	"k8s.io/apimachinery/pkg/api/resource"
	"k8s.io/klog/v2/ktesting"
	_ "k8s.io/klog/v2/ktesting/init"
	"k8s.io/kubernetes/pkg/scheduler/apis/config"
	"k8s.io/kubernetes/pkg/scheduler/framework"
	plfeature "k8s.io/kubernetes/pkg/scheduler/framework/plugins/feature"
	plugintesting "k8s.io/kubernetes/pkg/scheduler/framework/plugins/testing"
	"k8s.io/kubernetes/pkg/scheduler/framework/runtime"
	"k8s.io/kubernetes/pkg/scheduler/internal/cache"
	st "k8s.io/kubernetes/pkg/scheduler/testing"
	tf "k8s.io/kubernetes/pkg/scheduler/testing/framework"
)

var (
	extendedResourceA     = v1.ResourceName("example.com/aaa")
	extendedResourceB     = v1.ResourceName("example.com/bbb")
	kubernetesIOResourceA = v1.ResourceName("kubernetes.io/something")
	kubernetesIOResourceB = v1.ResourceName("subdomain.kubernetes.io/something")
	hugePageResourceA     = v1.ResourceName(v1.ResourceHugePagesPrefix + "2Mi")
)

func makeResources(milliCPU, memory, pods, extendedA, storage, hugePageA int64) v1.ResourceList {
	return v1.ResourceList{
		v1.ResourceCPU:              *resource.NewMilliQuantity(milliCPU, resource.DecimalSI),
		v1.ResourceMemory:           *resource.NewQuantity(memory, resource.BinarySI),
		v1.ResourcePods:             *resource.NewQuantity(pods, resource.DecimalSI),
		extendedResourceA:           *resource.NewQuantity(extendedA, resource.DecimalSI),
		v1.ResourceEphemeralStorage: *resource.NewQuantity(storage, resource.BinarySI),
		hugePageResourceA:           *resource.NewQuantity(hugePageA, resource.BinarySI),
	}
}

func makeAllocatableResources(milliCPU, memory, pods, extendedA, storage, hugePageA int64) v1.ResourceList {
	return v1.ResourceList{
		v1.ResourceCPU:              *resource.NewMilliQuantity(milliCPU, resource.DecimalSI),
		v1.ResourceMemory:           *resource.NewQuantity(memory, resource.BinarySI),
		v1.ResourcePods:             *resource.NewQuantity(pods, resource.DecimalSI),
		extendedResourceA:           *resource.NewQuantity(extendedA, resource.DecimalSI),
		v1.ResourceEphemeralStorage: *resource.NewQuantity(storage, resource.BinarySI),
		hugePageResourceA:           *resource.NewQuantity(hugePageA, resource.BinarySI),
	}
}

func newResourcePod(usage ...framework.Resource) *v1.Pod {
	var containers []v1.Container
	for _, req := range usage {
		rl := v1.ResourceList{
			v1.ResourceCPU:              *resource.NewMilliQuantity(req.MilliCPU, resource.DecimalSI),
			v1.ResourceMemory:           *resource.NewQuantity(req.Memory, resource.BinarySI),
			v1.ResourcePods:             *resource.NewQuantity(int64(req.AllowedPodNumber), resource.BinarySI),
			v1.ResourceEphemeralStorage: *resource.NewQuantity(req.EphemeralStorage, resource.BinarySI),
		}
		for rName, rQuant := range req.ScalarResources {
			if rName == hugePageResourceA {
				rl[rName] = *resource.NewQuantity(rQuant, resource.BinarySI)
			} else {
				rl[rName] = *resource.NewQuantity(rQuant, resource.DecimalSI)
			}
		}
		containers = append(containers, v1.Container{
			Resources: v1.ResourceRequirements{Requests: rl},
		})
	}
	return &v1.Pod{
		Spec: v1.PodSpec{
			Containers: containers,
		},
	}
}

func newResourceInitPod(pod *v1.Pod, usage ...framework.Resource) *v1.Pod {
	pod.Spec.InitContainers = newResourcePod(usage...).Spec.Containers
	return pod
}

func newResourceOverheadPod(pod *v1.Pod, overhead v1.ResourceList) *v1.Pod {
	pod.Spec.Overhead = overhead
	return pod
}

func getErrReason(rn v1.ResourceName) string {
	return fmt.Sprintf("Insufficient %v", rn)
}

var defaultScoringStrategy = &config.ScoringStrategy{
	Type: config.LeastAllocated,
	Resources: []config.ResourceSpec{
		{Name: "cpu", Weight: 1},
		{Name: "memory", Weight: 1},
	},
}

func TestEnoughRequests(t *testing.T) {
	enoughPodsTests := []struct {
		pod                       *v1.Pod
		nodeInfo                  *framework.NodeInfo
		name                      string
		args                      config.NodeResourcesFitArgs
		wantInsufficientResources []InsufficientResource
		wantStatus                *framework.Status
	}{
		{
			pod: &v1.Pod{},
			nodeInfo: framework.NewNodeInfo(
				newResourcePod(framework.Resource{MilliCPU: 10, Memory: 20})),
			name:                      "no resources requested always fits",
			wantInsufficientResources: []InsufficientResource{},
		},
		{
			pod: newResourcePod(framework.Resource{MilliCPU: 1, Memory: 1}),
			nodeInfo: framework.NewNodeInfo(
				newResourcePod(framework.Resource{MilliCPU: 10, Memory: 20})),
			name:       "too many resources fails",
			wantStatus: framework.NewStatus(framework.Unschedulable, getErrReason(v1.ResourceCPU), getErrReason(v1.ResourceMemory)),
			wantInsufficientResources: []InsufficientResource{
				{ResourceName: v1.ResourceCPU, Reason: getErrReason(v1.ResourceCPU), Requested: 1, Used: 10, Capacity: 10},
				{ResourceName: v1.ResourceMemory, Reason: getErrReason(v1.ResourceMemory), Requested: 1, Used: 20, Capacity: 20},
			},
		},
		{
			pod: newResourceInitPod(newResourcePod(framework.Resource{MilliCPU: 1, Memory: 1}), framework.Resource{MilliCPU: 3, Memory: 1}),
			nodeInfo: framework.NewNodeInfo(
				newResourcePod(framework.Resource{MilliCPU: 8, Memory: 19})),
			name:       "too many resources fails due to init container cpu",
			wantStatus: framework.NewStatus(framework.Unschedulable, getErrReason(v1.ResourceCPU)),
			wantInsufficientResources: []InsufficientResource{
				{ResourceName: v1.ResourceCPU, Reason: getErrReason(v1.ResourceCPU), Requested: 3, Used: 8, Capacity: 10},
			},
		},
		{
			pod: newResourceInitPod(newResourcePod(framework.Resource{MilliCPU: 1, Memory: 1}), framework.Resource{MilliCPU: 3, Memory: 1}, framework.Resource{MilliCPU: 2, Memory: 1}),
			nodeInfo: framework.NewNodeInfo(
				newResourcePod(framework.Resource{MilliCPU: 8, Memory: 19})),
			name:       "too many resources fails due to highest init container cpu",
			wantStatus: framework.NewStatus(framework.Unschedulable, getErrReason(v1.ResourceCPU)),
			wantInsufficientResources: []InsufficientResource{
				{ResourceName: v1.ResourceCPU, Reason: getErrReason(v1.ResourceCPU), Requested: 3, Used: 8, Capacity: 10},
			},
		},
		{
			pod: newResourceInitPod(newResourcePod(framework.Resource{MilliCPU: 1, Memory: 1}), framework.Resource{MilliCPU: 1, Memory: 3}),
			nodeInfo: framework.NewNodeInfo(
				newResourcePod(framework.Resource{MilliCPU: 9, Memory: 19})),
			name:       "too many resources fails due to init container memory",
			wantStatus: framework.NewStatus(framework.Unschedulable, getErrReason(v1.ResourceMemory)),
			wantInsufficientResources: []InsufficientResource{
				{ResourceName: v1.ResourceMemory, Reason: getErrReason(v1.ResourceMemory), Requested: 3, Used: 19, Capacity: 20},
			},
		},
		{
			pod: newResourceInitPod(newResourcePod(framework.Resource{MilliCPU: 1, Memory: 1}), framework.Resource{MilliCPU: 1, Memory: 3}, framework.Resource{MilliCPU: 1, Memory: 2}),
			nodeInfo: framework.NewNodeInfo(
				newResourcePod(framework.Resource{MilliCPU: 9, Memory: 19})),
			name:       "too many resources fails due to highest init container memory",
			wantStatus: framework.NewStatus(framework.Unschedulable, getErrReason(v1.ResourceMemory)),
			wantInsufficientResources: []InsufficientResource{
				{ResourceName: v1.ResourceMemory, Reason: getErrReason(v1.ResourceMemory), Requested: 3, Used: 19, Capacity: 20},
			},
		},
		{
			pod: newResourceInitPod(newResourcePod(framework.Resource{MilliCPU: 1, Memory: 1}), framework.Resource{MilliCPU: 1, Memory: 1}),
			nodeInfo: framework.NewNodeInfo(
				newResourcePod(framework.Resource{MilliCPU: 9, Memory: 19})),
			name:                      "init container fits because it's the max, not sum, of containers and init containers",
			wantInsufficientResources: []InsufficientResource{},
		},
		{
			pod: newResourceInitPod(newResourcePod(framework.Resource{MilliCPU: 1, Memory: 1}), framework.Resource{MilliCPU: 1, Memory: 1}, framework.Resource{MilliCPU: 1, Memory: 1}),
			nodeInfo: framework.NewNodeInfo(
				newResourcePod(framework.Resource{MilliCPU: 9, Memory: 19})),
			name:                      "multiple init containers fit because it's the max, not sum, of containers and init containers",
			wantInsufficientResources: []InsufficientResource{},
		},
		{
			pod: newResourcePod(framework.Resource{MilliCPU: 1, Memory: 1}),
			nodeInfo: framework.NewNodeInfo(
				newResourcePod(framework.Resource{MilliCPU: 5, Memory: 5})),
			name:                      "both resources fit",
			wantInsufficientResources: []InsufficientResource{},
		},
		{
			pod: newResourcePod(framework.Resource{MilliCPU: 2, Memory: 1}),
			nodeInfo: framework.NewNodeInfo(
				newResourcePod(framework.Resource{MilliCPU: 9, Memory: 5})),
			name:       "one resource memory fits",
			wantStatus: framework.NewStatus(framework.Unschedulable, getErrReason(v1.ResourceCPU)),
			wantInsufficientResources: []InsufficientResource{
				{ResourceName: v1.ResourceCPU, Reason: getErrReason(v1.ResourceCPU), Requested: 2, Used: 9, Capacity: 10},
			},
		},
		{
			pod: newResourcePod(framework.Resource{MilliCPU: 1, Memory: 2}),
			nodeInfo: framework.NewNodeInfo(
				newResourcePod(framework.Resource{MilliCPU: 5, Memory: 19})),
			name:       "one resource cpu fits",
			wantStatus: framework.NewStatus(framework.Unschedulable, getErrReason(v1.ResourceMemory)),
			wantInsufficientResources: []InsufficientResource{
				{ResourceName: v1.ResourceMemory, Reason: getErrReason(v1.ResourceMemory), Requested: 2, Used: 19, Capacity: 20},
			},
		},
		{
			pod: newResourcePod(framework.Resource{MilliCPU: 5, Memory: 1}),
			nodeInfo: framework.NewNodeInfo(
				newResourcePod(framework.Resource{MilliCPU: 5, Memory: 19})),
			name:                      "equal edge case",
			wantInsufficientResources: []InsufficientResource{},
		},
		{
			pod: newResourceInitPod(newResourcePod(framework.Resource{MilliCPU: 4, Memory: 1}), framework.Resource{MilliCPU: 5, Memory: 1}),
			nodeInfo: framework.NewNodeInfo(
				newResourcePod(framework.Resource{MilliCPU: 5, Memory: 19})),
			name:                      "equal edge case for init container",
			wantInsufficientResources: []InsufficientResource{},
		},
		{
			pod:                       newResourcePod(framework.Resource{ScalarResources: map[v1.ResourceName]int64{extendedResourceA: 1}}),
			nodeInfo:                  framework.NewNodeInfo(newResourcePod(framework.Resource{})),
			name:                      "extended resource fits",
			wantInsufficientResources: []InsufficientResource{},
		},
		{
			pod:                       newResourceInitPod(newResourcePod(framework.Resource{}), framework.Resource{ScalarResources: map[v1.ResourceName]int64{extendedResourceA: 1}}),
			nodeInfo:                  framework.NewNodeInfo(newResourcePod(framework.Resource{})),
			name:                      "extended resource fits for init container",
			wantInsufficientResources: []InsufficientResource{},
		},
		{
			pod: newResourcePod(
				framework.Resource{MilliCPU: 1, Memory: 1, ScalarResources: map[v1.ResourceName]int64{extendedResourceA: 10}}),
			nodeInfo: framework.NewNodeInfo(
				newResourcePod(framework.Resource{MilliCPU: 0, Memory: 0, ScalarResources: map[v1.ResourceName]int64{extendedResourceA: 0}})),
			name:       "extended resource capacity enforced",
			wantStatus: framework.NewStatus(framework.Unschedulable, getErrReason(extendedResourceA)),
			wantInsufficientResources: []InsufficientResource{
				{ResourceName: extendedResourceA, Reason: getErrReason(extendedResourceA), Requested: 10, Used: 0, Capacity: 5},
			},
		},
		{
			pod: newResourceInitPod(newResourcePod(framework.Resource{}),
				framework.Resource{MilliCPU: 1, Memory: 1, ScalarResources: map[v1.ResourceName]int64{extendedResourceA: 10}}),
			nodeInfo: framework.NewNodeInfo(
				newResourcePod(framework.Resource{MilliCPU: 0, Memory: 0, ScalarResources: map[v1.ResourceName]int64{extendedResourceA: 0}})),
			name:       "extended resource capacity enforced for init container",
			wantStatus: framework.NewStatus(framework.Unschedulable, getErrReason(extendedResourceA)),
			wantInsufficientResources: []InsufficientResource{
				{ResourceName: extendedResourceA, Reason: getErrReason(extendedResourceA), Requested: 10, Used: 0, Capacity: 5},
			},
		},
		{
			pod: newResourcePod(
				framework.Resource{MilliCPU: 1, Memory: 1, ScalarResources: map[v1.ResourceName]int64{extendedResourceA: 1}}),
			nodeInfo: framework.NewNodeInfo(
				newResourcePod(framework.Resource{MilliCPU: 0, Memory: 0, ScalarResources: map[v1.ResourceName]int64{extendedResourceA: 5}})),
			name:       "extended resource allocatable enforced",
			wantStatus: framework.NewStatus(framework.Unschedulable, getErrReason(extendedResourceA)),
			wantInsufficientResources: []InsufficientResource{
				{ResourceName: extendedResourceA, Reason: getErrReason(extendedResourceA), Requested: 1, Used: 5, Capacity: 5},
			},
		},
		{
			pod: newResourceInitPod(newResourcePod(framework.Resource{}),
				framework.Resource{MilliCPU: 1, Memory: 1, ScalarResources: map[v1.ResourceName]int64{extendedResourceA: 1}}),
			nodeInfo: framework.NewNodeInfo(
				newResourcePod(framework.Resource{MilliCPU: 0, Memory: 0, ScalarResources: map[v1.ResourceName]int64{extendedResourceA: 5}})),
			name:       "extended resource allocatable enforced for init container",
			wantStatus: framework.NewStatus(framework.Unschedulable, getErrReason(extendedResourceA)),
			wantInsufficientResources: []InsufficientResource{
				{ResourceName: extendedResourceA, Reason: getErrReason(extendedResourceA), Requested: 1, Used: 5, Capacity: 5},
			},
		},
		{
			pod: newResourcePod(
				framework.Resource{MilliCPU: 1, Memory: 1, ScalarResources: map[v1.ResourceName]int64{extendedResourceA: 3}},
				framework.Resource{MilliCPU: 1, Memory: 1, ScalarResources: map[v1.ResourceName]int64{extendedResourceA: 3}}),
			nodeInfo: framework.NewNodeInfo(
				newResourcePod(framework.Resource{MilliCPU: 0, Memory: 0, ScalarResources: map[v1.ResourceName]int64{extendedResourceA: 2}})),
			name:       "extended resource allocatable enforced for multiple containers",
			wantStatus: framework.NewStatus(framework.Unschedulable, getErrReason(extendedResourceA)),
			wantInsufficientResources: []InsufficientResource{
				{ResourceName: extendedResourceA, Reason: getErrReason(extendedResourceA), Requested: 6, Used: 2, Capacity: 5},
			},
		},
		{
			pod: newResourceInitPod(newResourcePod(framework.Resource{}),
				framework.Resource{MilliCPU: 1, Memory: 1, ScalarResources: map[v1.ResourceName]int64{extendedResourceA: 3}},
				framework.Resource{MilliCPU: 1, Memory: 1, ScalarResources: map[v1.ResourceName]int64{extendedResourceA: 3}}),
			nodeInfo: framework.NewNodeInfo(
				newResourcePod(framework.Resource{MilliCPU: 0, Memory: 0, ScalarResources: map[v1.ResourceName]int64{extendedResourceA: 2}})),
			name:                      "extended resource allocatable admits multiple init containers",
			wantInsufficientResources: []InsufficientResource{},
		},
		{
			pod: newResourceInitPod(newResourcePod(framework.Resource{}),
				framework.Resource{MilliCPU: 1, Memory: 1, ScalarResources: map[v1.ResourceName]int64{extendedResourceA: 6}},
				framework.Resource{MilliCPU: 1, Memory: 1, ScalarResources: map[v1.ResourceName]int64{extendedResourceA: 3}}),
			nodeInfo: framework.NewNodeInfo(
				newResourcePod(framework.Resource{MilliCPU: 0, Memory: 0, ScalarResources: map[v1.ResourceName]int64{extendedResourceA: 2}})),
			name:       "extended resource allocatable enforced for multiple init containers",
			wantStatus: framework.NewStatus(framework.Unschedulable, getErrReason(extendedResourceA)),
			wantInsufficientResources: []InsufficientResource{
				{ResourceName: extendedResourceA, Reason: getErrReason(extendedResourceA), Requested: 6, Used: 2, Capacity: 5},
			},
		},
		{
			pod: newResourcePod(
				framework.Resource{MilliCPU: 1, Memory: 1, ScalarResources: map[v1.ResourceName]int64{extendedResourceB: 1}}),
			nodeInfo: framework.NewNodeInfo(
				newResourcePod(framework.Resource{MilliCPU: 0, Memory: 0})),
			name:       "extended resource allocatable enforced for unknown resource",
			wantStatus: framework.NewStatus(framework.Unschedulable, getErrReason(extendedResourceB)),
			wantInsufficientResources: []InsufficientResource{
				{ResourceName: extendedResourceB, Reason: getErrReason(extendedResourceB), Requested: 1, Used: 0, Capacity: 0},
			},
		},
		{
			pod: newResourceInitPod(newResourcePod(framework.Resource{}),
				framework.Resource{MilliCPU: 1, Memory: 1, ScalarResources: map[v1.ResourceName]int64{extendedResourceB: 1}}),
			nodeInfo: framework.NewNodeInfo(
				newResourcePod(framework.Resource{MilliCPU: 0, Memory: 0})),
			name:       "extended resource allocatable enforced for unknown resource for init container",
			wantStatus: framework.NewStatus(framework.Unschedulable, getErrReason(extendedResourceB)),
			wantInsufficientResources: []InsufficientResource{
				{ResourceName: extendedResourceB, Reason: getErrReason(extendedResourceB), Requested: 1, Used: 0, Capacity: 0},
			},
		},
		{
			pod: newResourcePod(
				framework.Resource{MilliCPU: 1, Memory: 1, ScalarResources: map[v1.ResourceName]int64{kubernetesIOResourceA: 10}}),
			nodeInfo: framework.NewNodeInfo(
				newResourcePod(framework.Resource{MilliCPU: 0, Memory: 0})),
			name:       "kubernetes.io resource capacity enforced",
			wantStatus: framework.NewStatus(framework.Unschedulable, getErrReason(kubernetesIOResourceA)),
			wantInsufficientResources: []InsufficientResource{
				{ResourceName: kubernetesIOResourceA, Reason: getErrReason(kubernetesIOResourceA), Requested: 10, Used: 0, Capacity: 0},
			},
		},
		{
			pod: newResourceInitPod(newResourcePod(framework.Resource{}),
				framework.Resource{MilliCPU: 1, Memory: 1, ScalarResources: map[v1.ResourceName]int64{kubernetesIOResourceB: 10}}),
			nodeInfo: framework.NewNodeInfo(
				newResourcePod(framework.Resource{MilliCPU: 0, Memory: 0})),
			name:       "kubernetes.io resource capacity enforced for init container",
			wantStatus: framework.NewStatus(framework.Unschedulable, getErrReason(kubernetesIOResourceB)),
			wantInsufficientResources: []InsufficientResource{
				{ResourceName: kubernetesIOResourceB, Reason: getErrReason(kubernetesIOResourceB), Requested: 10, Used: 0, Capacity: 0},
			},
		},
		{
			pod: newResourcePod(
				framework.Resource{MilliCPU: 1, Memory: 1, ScalarResources: map[v1.ResourceName]int64{hugePageResourceA: 10}}),
			nodeInfo: framework.NewNodeInfo(
				newResourcePod(framework.Resource{MilliCPU: 0, Memory: 0, ScalarResources: map[v1.ResourceName]int64{hugePageResourceA: 0}})),
			name:       "hugepages resource capacity enforced",
			wantStatus: framework.NewStatus(framework.Unschedulable, getErrReason(hugePageResourceA)),
			wantInsufficientResources: []InsufficientResource{
				{ResourceName: hugePageResourceA, Reason: getErrReason(hugePageResourceA), Requested: 10, Used: 0, Capacity: 5},
			},
		},
		{
			pod: newResourceInitPod(newResourcePod(framework.Resource{}),
				framework.Resource{MilliCPU: 1, Memory: 1, ScalarResources: map[v1.ResourceName]int64{hugePageResourceA: 10}}),
			nodeInfo: framework.NewNodeInfo(
				newResourcePod(framework.Resource{MilliCPU: 0, Memory: 0, ScalarResources: map[v1.ResourceName]int64{hugePageResourceA: 0}})),
			name:       "hugepages resource capacity enforced for init container",
			wantStatus: framework.NewStatus(framework.Unschedulable, getErrReason(hugePageResourceA)),
			wantInsufficientResources: []InsufficientResource{
				{ResourceName: hugePageResourceA, Reason: getErrReason(hugePageResourceA), Requested: 10, Used: 0, Capacity: 5},
			},
		},
		{
			pod: newResourcePod(
				framework.Resource{MilliCPU: 1, Memory: 1, ScalarResources: map[v1.ResourceName]int64{hugePageResourceA: 3}},
				framework.Resource{MilliCPU: 1, Memory: 1, ScalarResources: map[v1.ResourceName]int64{hugePageResourceA: 3}}),
			nodeInfo: framework.NewNodeInfo(
				newResourcePod(framework.Resource{MilliCPU: 0, Memory: 0, ScalarResources: map[v1.ResourceName]int64{hugePageResourceA: 2}})),
			name:       "hugepages resource allocatable enforced for multiple containers",
			wantStatus: framework.NewStatus(framework.Unschedulable, getErrReason(hugePageResourceA)),
			wantInsufficientResources: []InsufficientResource{
				{ResourceName: hugePageResourceA, Reason: getErrReason(hugePageResourceA), Requested: 6, Used: 2, Capacity: 5},
			},
		},
		{
			pod: newResourcePod(
				framework.Resource{MilliCPU: 1, Memory: 1, ScalarResources: map[v1.ResourceName]int64{extendedResourceB: 1}}),
			nodeInfo: framework.NewNodeInfo(newResourcePod(framework.Resource{MilliCPU: 0, Memory: 0})),
			args: config.NodeResourcesFitArgs{
				IgnoredResources: []string{"example.com/bbb"},
			},
			name:                      "skip checking ignored extended resource",
			wantInsufficientResources: []InsufficientResource{},
		},
		{
			pod: newResourceOverheadPod(
				newResourcePod(framework.Resource{MilliCPU: 1, Memory: 1}),
				v1.ResourceList{v1.ResourceCPU: resource.MustParse("3m"), v1.ResourceMemory: resource.MustParse("13")},
			),
			nodeInfo:                  framework.NewNodeInfo(newResourcePod(framework.Resource{MilliCPU: 5, Memory: 5})),
			name:                      "resources + pod overhead fits",
			wantInsufficientResources: []InsufficientResource{},
		},
		{
			pod: newResourceOverheadPod(
				newResourcePod(framework.Resource{MilliCPU: 1, Memory: 1}),
				v1.ResourceList{v1.ResourceCPU: resource.MustParse("1m"), v1.ResourceMemory: resource.MustParse("15")},
			),
			nodeInfo:   framework.NewNodeInfo(newResourcePod(framework.Resource{MilliCPU: 5, Memory: 5})),
			name:       "requests + overhead does not fit for memory",
			wantStatus: framework.NewStatus(framework.Unschedulable, getErrReason(v1.ResourceMemory)),
			wantInsufficientResources: []InsufficientResource{
				{ResourceName: v1.ResourceMemory, Reason: getErrReason(v1.ResourceMemory), Requested: 16, Used: 5, Capacity: 20},
			},
		},
		{
			pod: newResourcePod(
				framework.Resource{
					MilliCPU: 1,
					Memory:   1,
					ScalarResources: map[v1.ResourceName]int64{
						extendedResourceB:     1,
						kubernetesIOResourceA: 1,
					}}),
			nodeInfo: framework.NewNodeInfo(newResourcePod(framework.Resource{MilliCPU: 0, Memory: 0})),
			args: config.NodeResourcesFitArgs{
				IgnoredResourceGroups: []string{"example.com"},
			},
			name:       "skip checking ignored extended resource via resource groups",
			wantStatus: framework.NewStatus(framework.Unschedulable, fmt.Sprintf("Insufficient %v", kubernetesIOResourceA)),
			wantInsufficientResources: []InsufficientResource{
				{
					ResourceName: kubernetesIOResourceA,
					Reason:       fmt.Sprintf("Insufficient %v", kubernetesIOResourceA),
					Requested:    1,
					Used:         0,
					Capacity:     0,
				},
			},
		},
		{
			pod: newResourcePod(
				framework.Resource{
					MilliCPU: 1,
					Memory:   1,
					ScalarResources: map[v1.ResourceName]int64{
						extendedResourceA: 0,
					}}),
			nodeInfo: framework.NewNodeInfo(newResourcePod(framework.Resource{
				MilliCPU: 0, Memory: 0, ScalarResources: map[v1.ResourceName]int64{extendedResourceA: 6}})),
			name:                      "skip checking extended resource request with quantity zero via resource groups",
			wantInsufficientResources: []InsufficientResource{},
		},
		{
			pod: newResourcePod(
				framework.Resource{
					ScalarResources: map[v1.ResourceName]int64{
						extendedResourceA: 1,
					}}),
			nodeInfo: framework.NewNodeInfo(newResourcePod(framework.Resource{
				MilliCPU: 20, Memory: 30, ScalarResources: map[v1.ResourceName]int64{extendedResourceA: 1}})),
			name:                      "skip checking resource request with quantity zero",
			wantInsufficientResources: []InsufficientResource{},
		},
	}

	for _, test := range enoughPodsTests {
		t.Run(test.name, func(t *testing.T) {
			node := v1.Node{Status: v1.NodeStatus{Capacity: makeResources(10, 20, 32, 5, 20, 5), Allocatable: makeAllocatableResources(10, 20, 32, 5, 20, 5)}}
			test.nodeInfo.SetNode(&node)

			if test.args.ScoringStrategy == nil {
				test.args.ScoringStrategy = defaultScoringStrategy
			}

			_, ctx := ktesting.NewTestContext(t)
			ctx, cancel := context.WithCancel(ctx)
			defer cancel()
			p, err := NewFit(ctx, &test.args, nil, plfeature.Features{})
			if err != nil {
				t.Fatal(err)
			}
			cycleState := framework.NewCycleState()
			_, preFilterStatus := p.(framework.PreFilterPlugin).PreFilter(ctx, cycleState, test.pod)
			if !preFilterStatus.IsSuccess() {
				t.Errorf("prefilter failed with status: %v", preFilterStatus)
			}

			gotStatus := p.(framework.FilterPlugin).Filter(ctx, cycleState, test.pod, test.nodeInfo)
			if !reflect.DeepEqual(gotStatus, test.wantStatus) {
				t.Errorf("status does not match: %v, want: %v", gotStatus, test.wantStatus)
			}

			gotInsufficientResources := fitsRequest(computePodResourceRequest(test.pod), test.nodeInfo, p.(*Fit).ignoredResources, p.(*Fit).ignoredResourceGroups)
			if !reflect.DeepEqual(gotInsufficientResources, test.wantInsufficientResources) {
				t.Errorf("insufficient resources do not match: %+v, want: %v", gotInsufficientResources, test.wantInsufficientResources)
			}
		})
	}
}

func TestPreFilterDisabled(t *testing.T) {
	_, ctx := ktesting.NewTestContext(t)
	ctx, cancel := context.WithCancel(ctx)
	defer cancel()
	pod := &v1.Pod{}
	nodeInfo := framework.NewNodeInfo()
	node := v1.Node{}
	nodeInfo.SetNode(&node)
	p, err := NewFit(ctx, &config.NodeResourcesFitArgs{ScoringStrategy: defaultScoringStrategy}, nil, plfeature.Features{})
	if err != nil {
		t.Fatal(err)
	}
	cycleState := framework.NewCycleState()
	gotStatus := p.(framework.FilterPlugin).Filter(ctx, cycleState, pod, nodeInfo)
	wantStatus := framework.AsStatus(fmt.Errorf(`error reading "PreFilterNodeResourcesFit" from cycleState: %w`, framework.ErrNotFound))
	if !reflect.DeepEqual(gotStatus, wantStatus) {
		t.Errorf("status does not match: %v, want: %v", gotStatus, wantStatus)
	}
}

func TestNotEnoughRequests(t *testing.T) {
	notEnoughPodsTests := []struct {
		pod        *v1.Pod
		nodeInfo   *framework.NodeInfo
		fits       bool
		name       string
		wantStatus *framework.Status
	}{
		{
			pod:        &v1.Pod{},
			nodeInfo:   framework.NewNodeInfo(newResourcePod(framework.Resource{MilliCPU: 10, Memory: 20})),
			name:       "even without specified resources, predicate fails when there's no space for additional pod",
			wantStatus: framework.NewStatus(framework.Unschedulable, "Too many pods"),
		},
		{
			pod:        newResourcePod(framework.Resource{MilliCPU: 1, Memory: 1}),
			nodeInfo:   framework.NewNodeInfo(newResourcePod(framework.Resource{MilliCPU: 5, Memory: 5})),
			name:       "even if both resources fit, predicate fails when there's no space for additional pod",
			wantStatus: framework.NewStatus(framework.Unschedulable, "Too many pods"),
		},
		{
			pod:        newResourcePod(framework.Resource{MilliCPU: 5, Memory: 1}),
			nodeInfo:   framework.NewNodeInfo(newResourcePod(framework.Resource{MilliCPU: 5, Memory: 19})),
			name:       "even for equal edge case, predicate fails when there's no space for additional pod",
			wantStatus: framework.NewStatus(framework.Unschedulable, "Too many pods"),
		},
		{
			pod:        newResourceInitPod(newResourcePod(framework.Resource{MilliCPU: 5, Memory: 1}), framework.Resource{MilliCPU: 5, Memory: 1}),
			nodeInfo:   framework.NewNodeInfo(newResourcePod(framework.Resource{MilliCPU: 5, Memory: 19})),
			name:       "even for equal edge case, predicate fails when there's no space for additional pod due to init container",
			wantStatus: framework.NewStatus(framework.Unschedulable, "Too many pods"),
		},
	}
	for _, test := range notEnoughPodsTests {
		t.Run(test.name, func(t *testing.T) {
			_, ctx := ktesting.NewTestContext(t)
			ctx, cancel := context.WithCancel(ctx)
			defer cancel()
			node := v1.Node{Status: v1.NodeStatus{Capacity: v1.ResourceList{}, Allocatable: makeAllocatableResources(10, 20, 1, 0, 0, 0)}}
			test.nodeInfo.SetNode(&node)

			p, err := NewFit(ctx, &config.NodeResourcesFitArgs{ScoringStrategy: defaultScoringStrategy}, nil, plfeature.Features{})
			if err != nil {
				t.Fatal(err)
			}
			cycleState := framework.NewCycleState()
			_, preFilterStatus := p.(framework.PreFilterPlugin).PreFilter(ctx, cycleState, test.pod)
			if !preFilterStatus.IsSuccess() {
				t.Errorf("prefilter failed with status: %v", preFilterStatus)
			}

			gotStatus := p.(framework.FilterPlugin).Filter(ctx, cycleState, test.pod, test.nodeInfo)
			if !reflect.DeepEqual(gotStatus, test.wantStatus) {
				t.Errorf("status does not match: %v, want: %v", gotStatus, test.wantStatus)
			}
		})
	}

}

func TestStorageRequests(t *testing.T) {
	storagePodsTests := []struct {
		pod        *v1.Pod
		nodeInfo   *framework.NodeInfo
		name       string
		wantStatus *framework.Status
	}{
		{
			pod: newResourcePod(framework.Resource{MilliCPU: 1, Memory: 1}),
			nodeInfo: framework.NewNodeInfo(
				newResourcePod(framework.Resource{MilliCPU: 2, Memory: 10})),
			name: "empty storage requested, and pod fits",
		},
		{
			pod: newResourcePod(framework.Resource{EphemeralStorage: 25}),
			nodeInfo: framework.NewNodeInfo(
				newResourcePod(framework.Resource{MilliCPU: 2, Memory: 2})),
			name:       "storage ephemeral local storage request exceeds allocatable",
			wantStatus: framework.NewStatus(framework.Unschedulable, getErrReason(v1.ResourceEphemeralStorage)),
		},
		{
			pod: newResourceInitPod(newResourcePod(framework.Resource{EphemeralStorage: 5})),
			nodeInfo: framework.NewNodeInfo(
				newResourcePod(framework.Resource{MilliCPU: 2, Memory: 2, EphemeralStorage: 10})),
			name: "ephemeral local storage is sufficient",
		},
		{
			pod: newResourcePod(framework.Resource{EphemeralStorage: 10}),
			nodeInfo: framework.NewNodeInfo(
				newResourcePod(framework.Resource{MilliCPU: 2, Memory: 2})),
			name: "pod fits",
		},
	}

	for _, test := range storagePodsTests {
		t.Run(test.name, func(t *testing.T) {
			_, ctx := ktesting.NewTestContext(t)
			ctx, cancel := context.WithCancel(ctx)
			defer cancel()
			node := v1.Node{Status: v1.NodeStatus{Capacity: makeResources(10, 20, 32, 5, 20, 5), Allocatable: makeAllocatableResources(10, 20, 32, 5, 20, 5)}}
			test.nodeInfo.SetNode(&node)

			p, err := NewFit(ctx, &config.NodeResourcesFitArgs{ScoringStrategy: defaultScoringStrategy}, nil, plfeature.Features{})
			if err != nil {
				t.Fatal(err)
			}
			cycleState := framework.NewCycleState()
			_, preFilterStatus := p.(framework.PreFilterPlugin).PreFilter(ctx, cycleState, test.pod)
			if !preFilterStatus.IsSuccess() {
				t.Errorf("prefilter failed with status: %v", preFilterStatus)
			}

			gotStatus := p.(framework.FilterPlugin).Filter(ctx, cycleState, test.pod, test.nodeInfo)
			if !reflect.DeepEqual(gotStatus, test.wantStatus) {
				t.Errorf("status does not match: %v, want: %v", gotStatus, test.wantStatus)
			}
		})
	}

}

func TestRestartableInitContainers(t *testing.T) {
	newPod := func() *v1.Pod {
		return &v1.Pod{
			Spec: v1.PodSpec{
				Containers: []v1.Container{
					{Name: "regular"},
				},
			},
		}
	}
	newPodWithRestartableInitContainers := func() *v1.Pod {
		restartPolicyAlways := v1.ContainerRestartPolicyAlways
		return &v1.Pod{
			Spec: v1.PodSpec{
				Containers: []v1.Container{
					{Name: "regular"},
				},
				InitContainers: []v1.Container{
					{
						Name:          "restartable-init",
						RestartPolicy: &restartPolicyAlways,
					},
				},
			},
		}
	}

	testCases := []struct {
		name                    string
		pod                     *v1.Pod
		enableSidecarContainers bool
		wantPreFilterStatus     *framework.Status
	}{
		{
			name: "allow pod without restartable init containers if sidecar containers is disabled",
			pod:  newPod(),
		},
		{
			name:                "not allow pod with restartable init containers if sidecar containers is disabled",
			pod:                 newPodWithRestartableInitContainers(),
			wantPreFilterStatus: framework.NewStatus(framework.UnschedulableAndUnresolvable, "Pod has a restartable init container and the SidecarContainers feature is disabled"),
		},
		{
			name:                    "allow pod without restartable init containers if sidecar containers is enabled",
			enableSidecarContainers: true,
			pod:                     newPod(),
		},
		{
			name:                    "allow pod with restartable init containers if sidecar containers is enabled",
			enableSidecarContainers: true,
			pod:                     newPodWithRestartableInitContainers(),
		},
	}

	for _, test := range testCases {
		t.Run(test.name, func(t *testing.T) {
			_, ctx := ktesting.NewTestContext(t)
			ctx, cancel := context.WithCancel(ctx)
			defer cancel()
			node := v1.Node{Status: v1.NodeStatus{Capacity: v1.ResourceList{}, Allocatable: makeAllocatableResources(0, 0, 1, 0, 0, 0)}}
			nodeInfo := framework.NewNodeInfo()
			nodeInfo.SetNode(&node)

			p, err := NewFit(ctx, &config.NodeResourcesFitArgs{ScoringStrategy: defaultScoringStrategy}, nil, plfeature.Features{EnableSidecarContainers: test.enableSidecarContainers})
			if err != nil {
				t.Fatal(err)
			}
			cycleState := framework.NewCycleState()
			_, preFilterStatus := p.(framework.PreFilterPlugin).PreFilter(context.Background(), cycleState, test.pod)
			if diff := cmp.Diff(test.wantPreFilterStatus, preFilterStatus); diff != "" {
				t.Error("status does not match (-expected +actual):\n", diff)
			}
			if !preFilterStatus.IsSuccess() {
				return
			}

			filterStatus := p.(framework.FilterPlugin).Filter(ctx, cycleState, test.pod, nodeInfo)
			if !filterStatus.IsSuccess() {
				t.Error("status does not match (-expected +actual):\n- Success\n +\n", filterStatus.Code())
			}
		})
	}

}

func TestFitScore(t *testing.T) {
	tests := []struct {
		name                 string
		requestedPod         *v1.Pod
		nodes                []*v1.Node
		existingPods         []*v1.Pod
		expectedPriorities   framework.NodeScoreList
		nodeResourcesFitArgs config.NodeResourcesFitArgs
		runPreScore          bool
	}{
		{
			name: "test case for ScoringStrategy RequestedToCapacityRatio case1",
			requestedPod: st.MakePod().
				Req(map[v1.ResourceName]string{"cpu": "3000", "memory": "5000"}).
				Obj(),
			nodes: []*v1.Node{
				st.MakeNode().Name("node1").Capacity(map[v1.ResourceName]string{"cpu": "4000", "memory": "10000"}).Obj(),
				st.MakeNode().Name("node2").Capacity(map[v1.ResourceName]string{"cpu": "6000", "memory": "10000"}).Obj(),
			},
			existingPods: []*v1.Pod{
				st.MakePod().Node("node1").Req(map[v1.ResourceName]string{"cpu": "2000", "memory": "4000"}).Obj(),
				st.MakePod().Node("node2").Req(map[v1.ResourceName]string{"cpu": "1000", "memory": "2000"}).Obj(),
			},
			expectedPriorities: []framework.NodeScore{{Name: "node1", Score: 10}, {Name: "node2", Score: 32}},
			nodeResourcesFitArgs: config.NodeResourcesFitArgs{
				ScoringStrategy: &config.ScoringStrategy{
					Type:      config.RequestedToCapacityRatio,
					Resources: defaultResources,
					RequestedToCapacityRatio: &config.RequestedToCapacityRatioParam{
						Shape: []config.UtilizationShapePoint{
							{Utilization: 0, Score: 10},
							{Utilization: 100, Score: 0},
						},
					},
				},
			},
			runPreScore: true,
		},
		{
			name: "test case for ScoringStrategy RequestedToCapacityRatio case2",
			requestedPod: st.MakePod().
				Req(map[v1.ResourceName]string{"cpu": "3000", "memory": "5000"}).
				Obj(),
			nodes: []*v1.Node{
				st.MakeNode().Name("node1").Capacity(map[v1.ResourceName]string{"cpu": "4000", "memory": "10000"}).Obj(),
				st.MakeNode().Name("node2").Capacity(map[v1.ResourceName]string{"cpu": "6000", "memory": "10000"}).Obj(),
			},
			existingPods: []*v1.Pod{
				st.MakePod().Node("node1").Req(map[v1.ResourceName]string{"cpu": "2000", "memory": "4000"}).Obj(),
				st.MakePod().Node("node2").Req(map[v1.ResourceName]string{"cpu": "1000", "memory": "2000"}).Obj(),
			},
			expectedPriorities: []framework.NodeScore{{Name: "node1", Score: 95}, {Name: "node2", Score: 68}},
			nodeResourcesFitArgs: config.NodeResourcesFitArgs{
				ScoringStrategy: &config.ScoringStrategy{
					Type:      config.RequestedToCapacityRatio,
					Resources: defaultResources,
					RequestedToCapacityRatio: &config.RequestedToCapacityRatioParam{
						Shape: []config.UtilizationShapePoint{
							{Utilization: 0, Score: 0},
							{Utilization: 100, Score: 10},
						},
					},
				},
			},
			runPreScore: true,
		},
		{
			name: "test case for ScoringStrategy MostAllocated",
			requestedPod: st.MakePod().
				Req(map[v1.ResourceName]string{"cpu": "1000", "memory": "2000"}).
				Obj(),
			nodes: []*v1.Node{
				st.MakeNode().Name("node1").Capacity(map[v1.ResourceName]string{"cpu": "4000", "memory": "10000"}).Obj(),
				st.MakeNode().Name("node2").Capacity(map[v1.ResourceName]string{"cpu": "6000", "memory": "10000"}).Obj(),
			},
			existingPods: []*v1.Pod{
				st.MakePod().Node("node1").Req(map[v1.ResourceName]string{"cpu": "2000", "memory": "4000"}).Obj(),
				st.MakePod().Node("node2").Req(map[v1.ResourceName]string{"cpu": "1000", "memory": "2000"}).Obj(),
			},
			expectedPriorities: []framework.NodeScore{{Name: "node1", Score: 67}, {Name: "node2", Score: 36}},
			nodeResourcesFitArgs: config.NodeResourcesFitArgs{
				ScoringStrategy: &config.ScoringStrategy{
					Type:      config.MostAllocated,
					Resources: defaultResources,
				},
			},
			runPreScore: true,
		},
		{
			name: "test case for ScoringStrategy LeastAllocated",
			requestedPod: st.MakePod().
				Req(map[v1.ResourceName]string{"cpu": "1000", "memory": "2000"}).
				Obj(),
			nodes: []*v1.Node{
				st.MakeNode().Name("node1").Capacity(map[v1.ResourceName]string{"cpu": "4000", "memory": "10000"}).Obj(),
				st.MakeNode().Name("node2").Capacity(map[v1.ResourceName]string{"cpu": "6000", "memory": "10000"}).Obj(),
			},
			existingPods: []*v1.Pod{
				st.MakePod().Node("node1").Req(map[v1.ResourceName]string{"cpu": "2000", "memory": "4000"}).Obj(),
				st.MakePod().Node("node2").Req(map[v1.ResourceName]string{"cpu": "1000", "memory": "2000"}).Obj(),
			},
			expectedPriorities: []framework.NodeScore{{Name: "node1", Score: 32}, {Name: "node2", Score: 63}},
			nodeResourcesFitArgs: config.NodeResourcesFitArgs{
				ScoringStrategy: &config.ScoringStrategy{
					Type:      config.LeastAllocated,
					Resources: defaultResources,
				},
			},
			runPreScore: true,
		},
		{
			name: "test case for ScoringStrategy RequestedToCapacityRatio case1 if PreScore is not called",
			requestedPod: st.MakePod().
				Req(map[v1.ResourceName]string{"cpu": "3000", "memory": "5000"}).
				Obj(),
			nodes: []*v1.Node{
				st.MakeNode().Name("node1").Capacity(map[v1.ResourceName]string{"cpu": "4000", "memory": "10000"}).Obj(),
				st.MakeNode().Name("node2").Capacity(map[v1.ResourceName]string{"cpu": "6000", "memory": "10000"}).Obj(),
			},
			existingPods: []*v1.Pod{
				st.MakePod().Node("node1").Req(map[v1.ResourceName]string{"cpu": "2000", "memory": "4000"}).Obj(),
				st.MakePod().Node("node2").Req(map[v1.ResourceName]string{"cpu": "1000", "memory": "2000"}).Obj(),
			},
			expectedPriorities: []framework.NodeScore{{Name: "node1", Score: 10}, {Name: "node2", Score: 32}},
			nodeResourcesFitArgs: config.NodeResourcesFitArgs{
				ScoringStrategy: &config.ScoringStrategy{
					Type:      config.RequestedToCapacityRatio,
					Resources: defaultResources,
					RequestedToCapacityRatio: &config.RequestedToCapacityRatioParam{
						Shape: []config.UtilizationShapePoint{
							{Utilization: 0, Score: 10},
							{Utilization: 100, Score: 0},
						},
					},
				},
			},
			runPreScore: false,
		},
		{
			name: "test case for ScoringStrategy MostAllocated if PreScore is not called",
			requestedPod: st.MakePod().
				Req(map[v1.ResourceName]string{"cpu": "1000", "memory": "2000"}).
				Obj(),
			nodes: []*v1.Node{
				st.MakeNode().Name("node1").Capacity(map[v1.ResourceName]string{"cpu": "4000", "memory": "10000"}).Obj(),
				st.MakeNode().Name("node2").Capacity(map[v1.ResourceName]string{"cpu": "6000", "memory": "10000"}).Obj(),
			},
			existingPods: []*v1.Pod{
				st.MakePod().Node("node1").Req(map[v1.ResourceName]string{"cpu": "2000", "memory": "4000"}).Obj(),
				st.MakePod().Node("node2").Req(map[v1.ResourceName]string{"cpu": "1000", "memory": "2000"}).Obj(),
			},
			expectedPriorities: []framework.NodeScore{{Name: "node1", Score: 67}, {Name: "node2", Score: 36}},
			nodeResourcesFitArgs: config.NodeResourcesFitArgs{
				ScoringStrategy: &config.ScoringStrategy{
					Type:      config.MostAllocated,
					Resources: defaultResources,
				},
			},
			runPreScore: false,
		},
		{
			name: "test case for ScoringStrategy LeastAllocated if PreScore is not called",
			requestedPod: st.MakePod().
				Req(map[v1.ResourceName]string{"cpu": "1000", "memory": "2000"}).
				Obj(),
			nodes: []*v1.Node{
				st.MakeNode().Name("node1").Capacity(map[v1.ResourceName]string{"cpu": "4000", "memory": "10000"}).Obj(),
				st.MakeNode().Name("node2").Capacity(map[v1.ResourceName]string{"cpu": "6000", "memory": "10000"}).Obj(),
			},
			existingPods: []*v1.Pod{
				st.MakePod().Node("node1").Req(map[v1.ResourceName]string{"cpu": "2000", "memory": "4000"}).Obj(),
				st.MakePod().Node("node2").Req(map[v1.ResourceName]string{"cpu": "1000", "memory": "2000"}).Obj(),
			},
			expectedPriorities: []framework.NodeScore{{Name: "node1", Score: 32}, {Name: "node2", Score: 63}},
			nodeResourcesFitArgs: config.NodeResourcesFitArgs{
				ScoringStrategy: &config.ScoringStrategy{
					Type:      config.LeastAllocated,
					Resources: defaultResources,
				},
			},
			runPreScore: false,
		},
	}

	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			_, ctx := ktesting.NewTestContext(t)
			ctx, cancel := context.WithCancel(ctx)
			defer cancel()

			state := framework.NewCycleState()
			snapshot := cache.NewSnapshot(test.existingPods, test.nodes)
			fh, _ := runtime.NewFramework(ctx, nil, nil, runtime.WithSnapshotSharedLister(snapshot))
			args := test.nodeResourcesFitArgs
			p, err := NewFit(ctx, &args, fh, plfeature.Features{})
			if err != nil {
				t.Fatalf("unexpected error: %v", err)
			}

			var gotPriorities framework.NodeScoreList
			for _, n := range test.nodes {
				if test.runPreScore {
					status := p.(framework.PreScorePlugin).PreScore(ctx, state, test.requestedPod, tf.BuildNodeInfos(test.nodes))
					if !status.IsSuccess() {
						t.Errorf("PreScore is expected to return success, but didn't. Got status: %v", status)
					}
				}
				score, status := p.(framework.ScorePlugin).Score(ctx, state, test.requestedPod, n.Name)
				if !status.IsSuccess() {
					t.Errorf("Score is expected to return success, but didn't. Got status: %v", status)
				}
				gotPriorities = append(gotPriorities, framework.NodeScore{Name: n.Name, Score: score})
			}

			if !reflect.DeepEqual(test.expectedPriorities, gotPriorities) {
				t.Errorf("expected:\n\t%+v,\ngot:\n\t%+v", test.expectedPriorities, gotPriorities)
			}
		})
	}
}

var benchmarkResourceSet = []config.ResourceSpec{
	{Name: string(v1.ResourceCPU), Weight: 1},
	{Name: string(v1.ResourceMemory), Weight: 1},
	{Name: string(v1.ResourcePods), Weight: 1},
	{Name: string(v1.ResourceStorage), Weight: 1},
	{Name: string(v1.ResourceEphemeralStorage), Weight: 1},
	{Name: string(extendedResourceA), Weight: 1},
	{Name: string(extendedResourceB), Weight: 1},
	{Name: string(kubernetesIOResourceA), Weight: 1},
	{Name: string(kubernetesIOResourceB), Weight: 1},
	{Name: string(hugePageResourceA), Weight: 1},
}

func BenchmarkTestFitScore(b *testing.B) {
	tests := []struct {
		name                 string
		nodeResourcesFitArgs config.NodeResourcesFitArgs
	}{
		{
			name: "RequestedToCapacityRatio with defaultResources",
			nodeResourcesFitArgs: config.NodeResourcesFitArgs{
				ScoringStrategy: &config.ScoringStrategy{
					Type:      config.RequestedToCapacityRatio,
					Resources: defaultResources,
					RequestedToCapacityRatio: &config.RequestedToCapacityRatioParam{
						Shape: []config.UtilizationShapePoint{
							{Utilization: 0, Score: 10},
							{Utilization: 100, Score: 0},
						},
					},
				},
			},
		},
		{
			name: "RequestedToCapacityRatio with 10 resources",
			nodeResourcesFitArgs: config.NodeResourcesFitArgs{
				ScoringStrategy: &config.ScoringStrategy{
					Type:      config.RequestedToCapacityRatio,
					Resources: benchmarkResourceSet,
					RequestedToCapacityRatio: &config.RequestedToCapacityRatioParam{
						Shape: []config.UtilizationShapePoint{
							{Utilization: 0, Score: 10},
							{Utilization: 100, Score: 0},
						},
					},
				},
			},
		},
		{
			name: "MostAllocated with defaultResources",
			nodeResourcesFitArgs: config.NodeResourcesFitArgs{
				ScoringStrategy: &config.ScoringStrategy{
					Type:      config.MostAllocated,
					Resources: defaultResources,
				},
			},
		},
		{
			name: "MostAllocated with 10 resources",
			nodeResourcesFitArgs: config.NodeResourcesFitArgs{
				ScoringStrategy: &config.ScoringStrategy{
					Type:      config.MostAllocated,
					Resources: benchmarkResourceSet,
				},
			},
		},
		{
			name: "LeastAllocated with defaultResources",
			nodeResourcesFitArgs: config.NodeResourcesFitArgs{
				ScoringStrategy: &config.ScoringStrategy{
					Type:      config.LeastAllocated,
					Resources: defaultResources,
				},
			},
		},
		{
			name: "LeastAllocated with 10 resources",
			nodeResourcesFitArgs: config.NodeResourcesFitArgs{
				ScoringStrategy: &config.ScoringStrategy{
					Type:      config.LeastAllocated,
					Resources: benchmarkResourceSet,
				},
			},
		},
	}

	for _, test := range tests {
		b.Run(test.name, func(b *testing.B) {
			_, ctx := ktesting.NewTestContext(b)
			ctx, cancel := context.WithCancel(ctx)
			defer cancel()
			existingPods := []*v1.Pod{
				st.MakePod().Node("node1").Req(map[v1.ResourceName]string{"cpu": "2000", "memory": "4000"}).Obj(),
			}
			nodes := []*v1.Node{
				st.MakeNode().Name("node1").Capacity(map[v1.ResourceName]string{"cpu": "4000", "memory": "10000"}).Obj(),
			}
			state := framework.NewCycleState()
			var nodeResourcesFunc = runtime.FactoryAdapter(plfeature.Features{}, NewFit)
			pl := plugintesting.SetupPlugin(ctx, b, nodeResourcesFunc, &test.nodeResourcesFitArgs, cache.NewSnapshot(existingPods, nodes))
			p := pl.(*Fit)

			b.ResetTimer()

			requestedPod := st.MakePod().Req(map[v1.ResourceName]string{"cpu": "1000", "memory": "2000"}).Obj()
			for i := 0; i < b.N; i++ {
				_, status := p.Score(ctx, state, requestedPod, nodes[0].Name)
				if !status.IsSuccess() {
					b.Errorf("unexpected status: %v", status)
				}
			}
		})
	}
}

func TestEventsToRegister(t *testing.T) {
	tests := []struct {
		name                             string
		inPlacePodVerticalScalingEnabled bool
		expectedClusterEvents            []framework.ClusterEventWithHint
	}{
		{
			"Register events with InPlacePodVerticalScaling feature enabled",
			true,
			[]framework.ClusterEventWithHint{
				{Event: framework.ClusterEvent{Resource: "Pod", ActionType: framework.Update | framework.Delete}},
				{Event: framework.ClusterEvent{Resource: "Node", ActionType: framework.Add | framework.Update}},
			},
		},
		{
			"Register events with InPlacePodVerticalScaling feature disabled",
			false,
			[]framework.ClusterEventWithHint{
				{Event: framework.ClusterEvent{Resource: "Pod", ActionType: framework.Delete}},
				{Event: framework.ClusterEvent{Resource: "Node", ActionType: framework.Add | framework.Update}},
			},
		},
	}

	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			fp := &Fit{enableInPlacePodVerticalScaling: test.inPlacePodVerticalScalingEnabled}
			actualClusterEvents := fp.EventsToRegister()
			for i := range actualClusterEvents {
				actualClusterEvents[i].QueueingHintFn = nil
			}
			if diff := cmp.Diff(test.expectedClusterEvents, actualClusterEvents); diff != "" {
				t.Error("Cluster Events doesn't match extected events (-expected +actual):\n", diff)
			}
		})
	}
}

func Test_isSchedulableAfterPodChange(t *testing.T) {
	testcases := map[string]struct {
		pod                             *v1.Pod
		oldObj, newObj                  interface{}
		enableInPlacePodVerticalScaling bool
		expectedHint                    framework.QueueingHint
		expectedErr                     bool
	}{
		"backoff-wrong-old-object": {
			pod:                             &v1.Pod{},
			oldObj:                          "not-a-pod",
			enableInPlacePodVerticalScaling: true,
			expectedHint:                    framework.Queue,
			expectedErr:                     true,
		},
		"backoff-wrong-new-object": {
			pod:                             &v1.Pod{},
			newObj:                          "not-a-pod",
			enableInPlacePodVerticalScaling: true,
			expectedHint:                    framework.Queue,
			expectedErr:                     true,
		},
		"queue-on-deleted": {
			pod:                             st.MakePod().Req(map[v1.ResourceName]string{v1.ResourceCPU: "1"}).Obj(),
			oldObj:                          st.MakePod().Req(map[v1.ResourceName]string{v1.ResourceCPU: "1"}).Node("fake").Obj(),
			enableInPlacePodVerticalScaling: true,
			expectedHint:                    framework.Queue,
		},
		"skip-queue-on-unscheduled-pod-deleted": {
			pod:                             &v1.Pod{},
			oldObj:                          &v1.Pod{},
			enableInPlacePodVerticalScaling: true,
			expectedHint:                    framework.QueueSkip,
		},
		"skip-queue-on-disable-inplace-pod-vertical-scaling": {
			pod:                             st.MakePod().Req(map[v1.ResourceName]string{v1.ResourceCPU: "1"}).Obj(),
			oldObj:                          st.MakePod().Req(map[v1.ResourceName]string{v1.ResourceCPU: "2"}).Node("fake").Obj(),
			newObj:                          st.MakePod().Req(map[v1.ResourceName]string{v1.ResourceCPU: "1"}).Node("fake").Obj(),
			enableInPlacePodVerticalScaling: false,
			expectedHint:                    framework.QueueSkip,
		},
		"skip-queue-on-unscheduled-pod": {
			pod:                             st.MakePod().Req(map[v1.ResourceName]string{v1.ResourceCPU: "1"}).Obj(),
			oldObj:                          st.MakePod().Req(map[v1.ResourceName]string{v1.ResourceCPU: "2"}).Obj(),
			newObj:                          st.MakePod().Req(map[v1.ResourceName]string{v1.ResourceCPU: "1"}).Obj(),
			enableInPlacePodVerticalScaling: true,
			expectedHint:                    framework.QueueSkip,
		},
		"skip-queue-on-non-resource-changes": {
			pod:                             &v1.Pod{},
			oldObj:                          st.MakePod().Label("k", "v").Node("fake").Obj(),
			newObj:                          st.MakePod().Label("foo", "bar").Node("fake").Obj(),
			enableInPlacePodVerticalScaling: true,
			expectedHint:                    framework.QueueSkip,
		},
		"skip-queue-on-unrelated-resource-changes": {
			pod:                             st.MakePod().Req(map[v1.ResourceName]string{v1.ResourceCPU: "1"}).Obj(),
			oldObj:                          st.MakePod().Req(map[v1.ResourceName]string{v1.ResourceMemory: "2"}).Node("fake").Obj(),
			newObj:                          st.MakePod().Req(map[v1.ResourceName]string{v1.ResourceMemory: "1"}).Node("fake").Obj(),
			enableInPlacePodVerticalScaling: true,
			expectedHint:                    framework.QueueSkip,
		},
		"skip-queue-on-resource-scale-up": {
			pod:                             st.MakePod().Req(map[v1.ResourceName]string{v1.ResourceCPU: "1"}).Obj(),
			oldObj:                          st.MakePod().Req(map[v1.ResourceName]string{v1.ResourceCPU: "1"}).Node("fake").Obj(),
			newObj:                          st.MakePod().Req(map[v1.ResourceName]string{v1.ResourceCPU: "2"}).Node("fake").Obj(),
			enableInPlacePodVerticalScaling: true,
			expectedHint:                    framework.QueueSkip,
		},
		"queue-on-some-resource-scale-down": {
			pod:                             st.MakePod().Req(map[v1.ResourceName]string{v1.ResourceCPU: "1"}).Obj(),
			oldObj:                          st.MakePod().Req(map[v1.ResourceName]string{v1.ResourceCPU: "2"}).Node("fake").Obj(),
			newObj:                          st.MakePod().Req(map[v1.ResourceName]string{v1.ResourceCPU: "1"}).Node("fake").Obj(),
			enableInPlacePodVerticalScaling: true,
			expectedHint:                    framework.Queue,
		},
	}

	for name, tc := range testcases {
		t.Run(name, func(t *testing.T) {
			logger, ctx := ktesting.NewTestContext(t)
			p, err := NewFit(ctx, &config.NodeResourcesFitArgs{ScoringStrategy: defaultScoringStrategy}, nil, plfeature.Features{
				EnableInPlacePodVerticalScaling: tc.enableInPlacePodVerticalScaling,
			})
			if err != nil {
				t.Fatal(err)
			}
			actualHint, err := p.(*Fit).isSchedulableAfterPodChange(logger, tc.pod, tc.oldObj, tc.newObj)
			if tc.expectedErr {
				require.Error(t, err)
				return
			}
			require.NoError(t, err)
			require.Equal(t, tc.expectedHint, actualHint)
		})
	}
}

func Test_isSchedulableAfterNodeChange(t *testing.T) {
	testcases := map[string]struct {
		pod            *v1.Pod
		oldObj, newObj interface{}
		expectedHint   framework.QueueingHint
		expectedErr    bool
	}{
		"backoff-wrong-new-object": {
			pod:          &v1.Pod{},
			newObj:       "not-a-node",
			expectedHint: framework.Queue,
			expectedErr:  true,
		},
		"backoff-wrong-old-object": {
			pod:          &v1.Pod{},
			oldObj:       "not-a-node",
			newObj:       &v1.Node{},
			expectedHint: framework.Queue,
			expectedErr:  true,
		},
		"skip-queue-on-node-add-without-sufficient-resources": {
			pod: newResourcePod(framework.Resource{Memory: 2}),
			newObj: st.MakeNode().Capacity(map[v1.ResourceName]string{
				v1.ResourceMemory: "1",
			}).Obj(),
			expectedHint: framework.QueueSkip,
		},
		"skip-queue-on-node-add-without-required-resource-type": {
			pod: newResourcePod(framework.Resource{
				ScalarResources: map[v1.ResourceName]int64{extendedResourceA: 1}},
			),
			newObj: st.MakeNode().Capacity(map[v1.ResourceName]string{
				extendedResourceB: "1",
			}).Obj(),
			expectedHint: framework.QueueSkip,
		},
		"queue-on-node-add-with-sufficient-resources": {
			pod: newResourcePod(framework.Resource{
				Memory:          2,
				ScalarResources: map[v1.ResourceName]int64{extendedResourceA: 1},
			}),
			newObj: st.MakeNode().Capacity(map[v1.ResourceName]string{
				v1.ResourceMemory: "4",
				extendedResourceA: "2",
			}).Obj(),
			expectedHint: framework.Queue,
		},
		// uncomment this case when the isSchedulableAfterNodeChange also check the
		// original node's resources.
		// "skip-queue-on-node-unrelated-changes": {
		// 	pod:          &v1.Pod{},
		// 	oldObj:       st.MakeNode().Obj(),
		// 	newObj:       st.MakeNode().Label("foo", "bar").Obj(),
		// 	expectedHint: framework.QueueSkip,
		// },
		"skip-queue-on-node-changes-from-suitable-to-unsuitable": {
			pod: newResourcePod(framework.Resource{
				Memory:          2,
				ScalarResources: map[v1.ResourceName]int64{extendedResourceA: 1},
			}),
			oldObj: st.MakeNode().Capacity(map[v1.ResourceName]string{
				v1.ResourceMemory: "4",
				extendedResourceA: "2",
			}).Obj(),
			newObj: st.MakeNode().Capacity(map[v1.ResourceName]string{
				v1.ResourceMemory: "1",
				extendedResourceA: "2",
			}).Obj(),
			expectedHint: framework.QueueSkip,
		},
		"queue-on-node-changes-from-unsuitable-to-suitable": {
			pod: newResourcePod(framework.Resource{
				Memory:          2,
				ScalarResources: map[v1.ResourceName]int64{extendedResourceA: 1},
			}),
			oldObj: st.MakeNode().Capacity(map[v1.ResourceName]string{
				v1.ResourceMemory: "1",
				extendedResourceA: "2",
			}).Obj(),
			newObj: st.MakeNode().Capacity(map[v1.ResourceName]string{
				v1.ResourceMemory: "4",
				extendedResourceA: "2",
			}).Obj(),
			expectedHint: framework.Queue,
		},
	}

	for name, tc := range testcases {
		t.Run(name, func(t *testing.T) {
			logger, ctx := ktesting.NewTestContext(t)
			p, err := NewFit(ctx, &config.NodeResourcesFitArgs{ScoringStrategy: defaultScoringStrategy}, nil, plfeature.Features{})
			if err != nil {
				t.Fatal(err)
			}
			actualHint, err := p.(*Fit).isSchedulableAfterNodeChange(logger, tc.pod, tc.oldObj, tc.newObj)
			if tc.expectedErr {
				require.Error(t, err)
				return
			}
			require.NoError(t, err)
			require.Equal(t, tc.expectedHint, actualHint)
		})
	}
}

func TestIsFit(t *testing.T) {
	testCases := map[string]struct {
		pod      *v1.Pod
		node     *v1.Node
		expected bool
	}{
		"nil node": {
			pod:      &v1.Pod{},
			expected: false,
		},
		"insufficient resource": {
			pod:      st.MakePod().Req(map[v1.ResourceName]string{v1.ResourceCPU: "2"}).Obj(),
			node:     st.MakeNode().Capacity(map[v1.ResourceName]string{v1.ResourceCPU: "1"}).Obj(),
			expected: false,
		},
		"sufficient resource": {
			pod:      st.MakePod().Req(map[v1.ResourceName]string{v1.ResourceCPU: "1"}).Obj(),
			node:     st.MakeNode().Capacity(map[v1.ResourceName]string{v1.ResourceCPU: "2"}).Obj(),
			expected: true,
		},
	}

	for name, tc := range testCases {
		t.Run(name, func(t *testing.T) {
			if got := isFit(tc.pod, tc.node); got != tc.expected {
				t.Errorf("expected: %v, got: %v", tc.expected, got)
			}
		})
	}
}
-e 
func helloWorld() {
    println("hello world")
}
