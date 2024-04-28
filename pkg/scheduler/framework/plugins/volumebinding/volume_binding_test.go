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

package volumebinding

import (
	"context"
	"testing"

	"github.com/google/go-cmp/cmp"
	"github.com/google/go-cmp/cmp/cmpopts"
	"github.com/stretchr/testify/assert"
	v1 "k8s.io/api/core/v1"
	storagev1 "k8s.io/api/storage/v1"
	"k8s.io/apimachinery/pkg/api/resource"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/util/sets"
	"k8s.io/client-go/informers"
	"k8s.io/client-go/kubernetes/fake"
	"k8s.io/klog/v2/ktesting"
	"k8s.io/kubernetes/pkg/scheduler/apis/config"
	"k8s.io/kubernetes/pkg/scheduler/framework"
	"k8s.io/kubernetes/pkg/scheduler/framework/plugins/feature"
	"k8s.io/kubernetes/pkg/scheduler/framework/runtime"
	tf "k8s.io/kubernetes/pkg/scheduler/testing/framework"
)

var (
	immediate            = storagev1.VolumeBindingImmediate
	waitForFirstConsumer = storagev1.VolumeBindingWaitForFirstConsumer
	immediateSC          = &storagev1.StorageClass{
		ObjectMeta: metav1.ObjectMeta{
			Name: "immediate-sc",
		},
		VolumeBindingMode: &immediate,
	}
	waitSC = &storagev1.StorageClass{
		ObjectMeta: metav1.ObjectMeta{
			Name: "wait-sc",
		},
		VolumeBindingMode: &waitForFirstConsumer,
	}
	waitHDDSC = &storagev1.StorageClass{
		ObjectMeta: metav1.ObjectMeta{
			Name: "wait-hdd-sc",
		},
		VolumeBindingMode: &waitForFirstConsumer,
	}

	defaultShapePoint = []config.UtilizationShapePoint{
		{
			Utilization: 0,
			Score:       0,
		},
		{
			Utilization: 100,
			Score:       int32(config.MaxCustomPriorityScore),
		},
	}
)

func TestVolumeBinding(t *testing.T) {
	table := []struct {
		name                    string
		pod                     *v1.Pod
		nodes                   []*v1.Node
		pvcs                    []*v1.PersistentVolumeClaim
		pvs                     []*v1.PersistentVolume
		fts                     feature.Features
		args                    *config.VolumeBindingArgs
		wantPreFilterResult     *framework.PreFilterResult
		wantPreFilterStatus     *framework.Status
		wantStateAfterPreFilter *stateData
		wantFilterStatus        []*framework.Status
		wantScores              []int64
		wantPreScoreStatus      *framework.Status
	}{
		{
			name: "pod has not pvcs",
			pod:  makePod("pod-a").Pod,
			nodes: []*v1.Node{
				makeNode("node-a").Node,
			},
			wantPreFilterStatus: framework.NewStatus(framework.Skip),
			wantFilterStatus: []*framework.Status{
				nil,
			},
			wantPreScoreStatus: framework.NewStatus(framework.Skip),
		},
		{
			name: "all bound",
			pod:  makePod("pod-a").withPVCVolume("pvc-a", "").Pod,
			nodes: []*v1.Node{
				makeNode("node-a").Node,
			},
			pvcs: []*v1.PersistentVolumeClaim{
				makePVC("pvc-a", waitSC.Name).withBoundPV("pv-a").PersistentVolumeClaim,
			},
			pvs: []*v1.PersistentVolume{
				makePV("pv-a", waitSC.Name).withPhase(v1.VolumeAvailable).PersistentVolume,
			},
			wantStateAfterPreFilter: &stateData{
				podVolumeClaims: &PodVolumeClaims{
					boundClaims: []*v1.PersistentVolumeClaim{
						makePVC("pvc-a", waitSC.Name).withBoundPV("pv-a").PersistentVolumeClaim,
					},
					unboundClaimsDelayBinding:  []*v1.PersistentVolumeClaim{},
					unboundVolumesDelayBinding: map[string][]*v1.PersistentVolume{},
				},
				podVolumesByNode: map[string]*PodVolumes{},
			},
			wantFilterStatus: []*framework.Status{
				nil,
			},
			wantPreScoreStatus: framework.NewStatus(framework.Skip),
		},
		{
			name: "all bound with local volumes",
			pod:  makePod("pod-a").withPVCVolume("pvc-a", "volume-a").withPVCVolume("pvc-b", "volume-b").Pod,
			nodes: []*v1.Node{
				makeNode("node-a").Node,
			},
			pvcs: []*v1.PersistentVolumeClaim{
				makePVC("pvc-a", waitSC.Name).withBoundPV("pv-a").PersistentVolumeClaim,
				makePVC("pvc-b", waitSC.Name).withBoundPV("pv-b").PersistentVolumeClaim,
			},
			pvs: []*v1.PersistentVolume{
				makePV("pv-a", waitSC.Name).withPhase(v1.VolumeBound).withNodeAffinity(map[string][]string{
					v1.LabelHostname: {"node-a"},
				}).PersistentVolume,
				makePV("pv-b", waitSC.Name).withPhase(v1.VolumeBound).withNodeAffinity(map[string][]string{
					v1.LabelHostname: {"node-a"},
				}).PersistentVolume,
			},
			wantPreFilterResult: &framework.PreFilterResult{
				NodeNames: sets.New("node-a"),
			},
			wantStateAfterPreFilter: &stateData{
				podVolumeClaims: &PodVolumeClaims{
					boundClaims: []*v1.PersistentVolumeClaim{
						makePVC("pvc-a", waitSC.Name).withBoundPV("pv-a").PersistentVolumeClaim,
						makePVC("pvc-b", waitSC.Name).withBoundPV("pv-b").PersistentVolumeClaim,
					},
					unboundClaimsDelayBinding:  []*v1.PersistentVolumeClaim{},
					unboundVolumesDelayBinding: map[string][]*v1.PersistentVolume{},
				},
				podVolumesByNode: map[string]*PodVolumes{},
			},
			wantFilterStatus: []*framework.Status{
				nil,
			},
			wantPreScoreStatus: framework.NewStatus(framework.Skip),
		},
		{
			name: "PVC does not exist",
			pod:  makePod("pod-a").withPVCVolume("pvc-a", "").Pod,
			nodes: []*v1.Node{
				makeNode("node-a").Node,
			},
			pvcs:                []*v1.PersistentVolumeClaim{},
			wantPreFilterStatus: framework.NewStatus(framework.UnschedulableAndUnresolvable, `persistentvolumeclaim "pvc-a" not found`),
			wantFilterStatus: []*framework.Status{
				nil,
			},
			wantScores: []int64{
				0,
			},
		},
		{
			name: "Part of PVCs do not exist",
			pod:  makePod("pod-a").withPVCVolume("pvc-a", "").withPVCVolume("pvc-b", "").Pod,
			nodes: []*v1.Node{
				makeNode("node-a").Node,
			},
			pvcs: []*v1.PersistentVolumeClaim{
				makePVC("pvc-a", waitSC.Name).withBoundPV("pv-a").PersistentVolumeClaim,
			},
			wantPreFilterStatus: framework.NewStatus(framework.UnschedulableAndUnresolvable, `persistentvolumeclaim "pvc-b" not found`),
			wantFilterStatus: []*framework.Status{
				nil,
			},
			wantScores: []int64{
				0,
			},
		},
		{
			name: "immediate claims not bound",
			pod:  makePod("pod-a").withPVCVolume("pvc-a", "").Pod,
			nodes: []*v1.Node{
				makeNode("node-a").Node,
			},
			pvcs: []*v1.PersistentVolumeClaim{
				makePVC("pvc-a", immediateSC.Name).PersistentVolumeClaim,
			},
			wantPreFilterStatus: framework.NewStatus(framework.UnschedulableAndUnresolvable, "pod has unbound immediate PersistentVolumeClaims"),
			wantFilterStatus: []*framework.Status{
				nil,
			},
			wantScores: []int64{
				0,
			},
		},
		{
			name: "unbound claims no matches",
			pod:  makePod("pod-a").withPVCVolume("pvc-a", "").Pod,
			nodes: []*v1.Node{
				makeNode("node-a").Node,
			},
			pvcs: []*v1.PersistentVolumeClaim{
				makePVC("pvc-a", waitSC.Name).PersistentVolumeClaim,
			},
			wantStateAfterPreFilter: &stateData{
				podVolumeClaims: &PodVolumeClaims{
					boundClaims: []*v1.PersistentVolumeClaim{},
					unboundClaimsDelayBinding: []*v1.PersistentVolumeClaim{
						makePVC("pvc-a", waitSC.Name).PersistentVolumeClaim,
					},
					unboundVolumesDelayBinding: map[string][]*v1.PersistentVolume{waitSC.Name: {}},
				},
				podVolumesByNode: map[string]*PodVolumes{},
			},
			wantFilterStatus: []*framework.Status{
				framework.NewStatus(framework.UnschedulableAndUnresolvable, string(ErrReasonBindConflict)),
			},
			wantPreScoreStatus: framework.NewStatus(framework.Skip),
		},
		{
			name: "bound and unbound unsatisfied",
			pod:  makePod("pod-a").withPVCVolume("pvc-a", "").withPVCVolume("pvc-b", "").Pod,
			nodes: []*v1.Node{
				makeNode("node-a").withLabel("foo", "barbar").Node,
			},
			pvcs: []*v1.PersistentVolumeClaim{
				makePVC("pvc-a", waitSC.Name).withBoundPV("pv-a").PersistentVolumeClaim,
				makePVC("pvc-b", waitSC.Name).PersistentVolumeClaim,
			},
			pvs: []*v1.PersistentVolume{
				makePV("pv-a", waitSC.Name).
					withPhase(v1.VolumeAvailable).
					withNodeAffinity(map[string][]string{"foo": {"bar"}}).PersistentVolume,
			},
			wantStateAfterPreFilter: &stateData{
				podVolumeClaims: &PodVolumeClaims{
					boundClaims: []*v1.PersistentVolumeClaim{
						makePVC("pvc-a", waitSC.Name).withBoundPV("pv-a").PersistentVolumeClaim,
					},
					unboundClaimsDelayBinding: []*v1.PersistentVolumeClaim{
						makePVC("pvc-b", waitSC.Name).PersistentVolumeClaim,
					},
					unboundVolumesDelayBinding: map[string][]*v1.PersistentVolume{
						waitSC.Name: {
							makePV("pv-a", waitSC.Name).
								withPhase(v1.VolumeAvailable).
								withNodeAffinity(map[string][]string{"foo": {"bar"}}).PersistentVolume,
						},
					},
				},
				podVolumesByNode: map[string]*PodVolumes{},
			},
			wantFilterStatus: []*framework.Status{
				framework.NewStatus(framework.UnschedulableAndUnresolvable, string(ErrReasonNodeConflict), string(ErrReasonBindConflict)),
			},
			wantPreScoreStatus: framework.NewStatus(framework.Skip),
		},
		{
			name: "pvc not found",
			pod:  makePod("pod-a").withPVCVolume("pvc-a", "").Pod,
			nodes: []*v1.Node{
				makeNode("node-a").Node,
			},
			wantPreFilterStatus: framework.NewStatus(framework.UnschedulableAndUnresolvable, `persistentvolumeclaim "pvc-a" not found`),
			wantFilterStatus: []*framework.Status{
				nil,
			},
			wantScores: []int64{
				0,
			},
		},
		{
			name: "pv not found",
			pod:  makePod("pod-a").withPVCVolume("pvc-a", "").Pod,
			nodes: []*v1.Node{
				makeNode("node-a").Node,
			},
			pvcs: []*v1.PersistentVolumeClaim{
				makePVC("pvc-a", waitSC.Name).withBoundPV("pv-a").PersistentVolumeClaim,
			},
			wantPreFilterStatus: nil,
			wantStateAfterPreFilter: &stateData{
				podVolumeClaims: &PodVolumeClaims{
					boundClaims: []*v1.PersistentVolumeClaim{
						makePVC("pvc-a", waitSC.Name).withBoundPV("pv-a").PersistentVolumeClaim,
					},
					unboundClaimsDelayBinding:  []*v1.PersistentVolumeClaim{},
					unboundVolumesDelayBinding: map[string][]*v1.PersistentVolume{},
				},
				podVolumesByNode: map[string]*PodVolumes{},
			},
			wantFilterStatus: []*framework.Status{
				framework.NewStatus(framework.UnschedulableAndUnresolvable, `node(s) unavailable due to one or more pvc(s) bound to non-existent pv(s)`),
			},
			wantPreScoreStatus: framework.NewStatus(framework.Skip),
		},
		{
			name: "pv not found claim lost",
			pod:  makePod("pod-a").withPVCVolume("pvc-a", "").Pod,
			nodes: []*v1.Node{
				makeNode("node-a").Node,
			},
			pvcs: []*v1.PersistentVolumeClaim{
				makePVC("pvc-a", waitSC.Name).withBoundPV("pv-a").withPhase(v1.ClaimLost).PersistentVolumeClaim,
			},
			wantPreFilterStatus: framework.NewStatus(framework.UnschedulableAndUnresolvable, `persistentvolumeclaim "pvc-a" bound to non-existent persistentvolume "pv-a"`),
			wantFilterStatus: []*framework.Status{
				nil,
			},
			wantScores: []int64{
				0,
			},
		},
		{
			name: "local volumes with close capacity are preferred",
			pod:  makePod("pod-a").withPVCVolume("pvc-a", "").Pod,
			nodes: []*v1.Node{
				makeNode("node-a").Node,
				makeNode("node-b").Node,
				makeNode("node-c").Node,
			},
			pvcs: []*v1.PersistentVolumeClaim{
				makePVC("pvc-a", waitSC.Name).withRequestStorage(resource.MustParse("50Gi")).PersistentVolumeClaim,
			},
			pvs: []*v1.PersistentVolume{
				makePV("pv-a-0", waitSC.Name).
					withPhase(v1.VolumeAvailable).
					withCapacity(resource.MustParse("200Gi")).
					withNodeAffinity(map[string][]string{v1.LabelHostname: {"node-a"}}).PersistentVolume,
				makePV("pv-a-1", waitSC.Name).
					withPhase(v1.VolumeAvailable).
					withCapacity(resource.MustParse("200Gi")).
					withNodeAffinity(map[string][]string{v1.LabelHostname: {"node-a"}}).PersistentVolume,
				makePV("pv-b-0", waitSC.Name).
					withPhase(v1.VolumeAvailable).
					withCapacity(resource.MustParse("100Gi")).
					withNodeAffinity(map[string][]string{v1.LabelHostname: {"node-b"}}).PersistentVolume,
				makePV("pv-b-1", waitSC.Name).
					withPhase(v1.VolumeAvailable).
					withCapacity(resource.MustParse("100Gi")).
					withNodeAffinity(map[string][]string{v1.LabelHostname: {"node-b"}}).PersistentVolume,
			},
			fts: feature.Features{
				EnableVolumeCapacityPriority: true,
			},
			wantPreFilterStatus: nil,
			wantStateAfterPreFilter: &stateData{
				podVolumeClaims: &PodVolumeClaims{
					boundClaims: []*v1.PersistentVolumeClaim{},
					unboundClaimsDelayBinding: []*v1.PersistentVolumeClaim{
						makePVC("pvc-a", waitSC.Name).withRequestStorage(resource.MustParse("50Gi")).PersistentVolumeClaim,
					},
					unboundVolumesDelayBinding: map[string][]*v1.PersistentVolume{
						waitSC.Name: {
							makePV("pv-a-0", waitSC.Name).
								withPhase(v1.VolumeAvailable).
								withCapacity(resource.MustParse("200Gi")).
								withNodeAffinity(map[string][]string{v1.LabelHostname: {"node-a"}}).PersistentVolume,
							makePV("pv-a-1", waitSC.Name).
								withPhase(v1.VolumeAvailable).
								withCapacity(resource.MustParse("200Gi")).
								withNodeAffinity(map[string][]string{v1.LabelHostname: {"node-a"}}).PersistentVolume,
							makePV("pv-b-0", waitSC.Name).
								withPhase(v1.VolumeAvailable).
								withCapacity(resource.MustParse("100Gi")).
								withNodeAffinity(map[string][]string{v1.LabelHostname: {"node-b"}}).PersistentVolume,
							makePV("pv-b-1", waitSC.Name).
								withPhase(v1.VolumeAvailable).
								withCapacity(resource.MustParse("100Gi")).
								withNodeAffinity(map[string][]string{v1.LabelHostname: {"node-b"}}).PersistentVolume,
						},
					},
				},
				podVolumesByNode: map[string]*PodVolumes{},
			},
			wantFilterStatus: []*framework.Status{
				nil,
				nil,
				framework.NewStatus(framework.UnschedulableAndUnresolvable, `node(s) didn't find available persistent volumes to bind`),
			},
			wantScores: []int64{
				25,
				50,
				0,
			},
		},
		{
			name: "local volumes with close capacity are preferred (multiple pvcs)",
			pod:  makePod("pod-a").withPVCVolume("pvc-0", "").withPVCVolume("pvc-1", "").Pod,
			nodes: []*v1.Node{
				makeNode("node-a").Node,
				makeNode("node-b").Node,
				makeNode("node-c").Node,
			},
			pvcs: []*v1.PersistentVolumeClaim{
				makePVC("pvc-0", waitSC.Name).withRequestStorage(resource.MustParse("50Gi")).PersistentVolumeClaim,
				makePVC("pvc-1", waitHDDSC.Name).withRequestStorage(resource.MustParse("100Gi")).PersistentVolumeClaim,
			},
			pvs: []*v1.PersistentVolume{
				makePV("pv-a-0", waitSC.Name).
					withPhase(v1.VolumeAvailable).
					withCapacity(resource.MustParse("200Gi")).
					withNodeAffinity(map[string][]string{v1.LabelHostname: {"node-a"}}).PersistentVolume,
				makePV("pv-a-1", waitSC.Name).
					withPhase(v1.VolumeAvailable).
					withCapacity(resource.MustParse("200Gi")).
					withNodeAffinity(map[string][]string{v1.LabelHostname: {"node-a"}}).PersistentVolume,
				makePV("pv-a-2", waitHDDSC.Name).
					withPhase(v1.VolumeAvailable).
					withCapacity(resource.MustParse("200Gi")).
					withNodeAffinity(map[string][]string{v1.LabelHostname: {"node-a"}}).PersistentVolume,
				makePV("pv-a-3", waitHDDSC.Name).
					withPhase(v1.VolumeAvailable).
					withCapacity(resource.MustParse("200Gi")).
					withNodeAffinity(map[string][]string{v1.LabelHostname: {"node-a"}}).PersistentVolume,
				makePV("pv-b-0", waitSC.Name).
					withPhase(v1.VolumeAvailable).
					withCapacity(resource.MustParse("100Gi")).
					withNodeAffinity(map[string][]string{v1.LabelHostname: {"node-b"}}).PersistentVolume,
				makePV("pv-b-1", waitSC.Name).
					withPhase(v1.VolumeAvailable).
					withCapacity(resource.MustParse("100Gi")).
					withNodeAffinity(map[string][]string{v1.LabelHostname: {"node-b"}}).PersistentVolume,
				makePV("pv-b-2", waitHDDSC.Name).
					withPhase(v1.VolumeAvailable).
					withCapacity(resource.MustParse("100Gi")).
					withNodeAffinity(map[string][]string{v1.LabelHostname: {"node-b"}}).PersistentVolume,
				makePV("pv-b-3", waitHDDSC.Name).
					withPhase(v1.VolumeAvailable).
					withCapacity(resource.MustParse("100Gi")).
					withNodeAffinity(map[string][]string{v1.LabelHostname: {"node-b"}}).PersistentVolume,
			},
			fts: feature.Features{
				EnableVolumeCapacityPriority: true,
			},
			wantPreFilterStatus: nil,
			wantStateAfterPreFilter: &stateData{
				podVolumeClaims: &PodVolumeClaims{
					boundClaims: []*v1.PersistentVolumeClaim{},
					unboundClaimsDelayBinding: []*v1.PersistentVolumeClaim{
						makePVC("pvc-0", waitSC.Name).withRequestStorage(resource.MustParse("50Gi")).PersistentVolumeClaim,
						makePVC("pvc-1", waitHDDSC.Name).withRequestStorage(resource.MustParse("100Gi")).PersistentVolumeClaim,
					},
					unboundVolumesDelayBinding: map[string][]*v1.PersistentVolume{
						waitHDDSC.Name: {
							makePV("pv-a-2", waitHDDSC.Name).
								withPhase(v1.VolumeAvailable).
								withCapacity(resource.MustParse("200Gi")).
								withNodeAffinity(map[string][]string{v1.LabelHostname: {"node-a"}}).PersistentVolume,
							makePV("pv-a-3", waitHDDSC.Name).
								withPhase(v1.VolumeAvailable).
								withCapacity(resource.MustParse("200Gi")).
								withNodeAffinity(map[string][]string{v1.LabelHostname: {"node-a"}}).PersistentVolume,
							makePV("pv-b-2", waitHDDSC.Name).
								withPhase(v1.VolumeAvailable).
								withCapacity(resource.MustParse("100Gi")).
								withNodeAffinity(map[string][]string{v1.LabelHostname: {"node-b"}}).PersistentVolume,
							makePV("pv-b-3", waitHDDSC.Name).
								withPhase(v1.VolumeAvailable).
								withCapacity(resource.MustParse("100Gi")).
								withNodeAffinity(map[string][]string{v1.LabelHostname: {"node-b"}}).PersistentVolume,
						},
						waitSC.Name: {
							makePV("pv-a-0", waitSC.Name).
								withPhase(v1.VolumeAvailable).
								withCapacity(resource.MustParse("200Gi")).
								withNodeAffinity(map[string][]string{v1.LabelHostname: {"node-a"}}).PersistentVolume,
							makePV("pv-a-1", waitSC.Name).
								withPhase(v1.VolumeAvailable).
								withCapacity(resource.MustParse("200Gi")).
								withNodeAffinity(map[string][]string{v1.LabelHostname: {"node-a"}}).PersistentVolume,
							makePV("pv-b-0", waitSC.Name).
								withPhase(v1.VolumeAvailable).
								withCapacity(resource.MustParse("100Gi")).
								withNodeAffinity(map[string][]string{v1.LabelHostname: {"node-b"}}).PersistentVolume,
							makePV("pv-b-1", waitSC.Name).
								withPhase(v1.VolumeAvailable).
								withCapacity(resource.MustParse("100Gi")).
								withNodeAffinity(map[string][]string{v1.LabelHostname: {"node-b"}}).PersistentVolume,
						},
					},
				},
				podVolumesByNode: map[string]*PodVolumes{},
			},
			wantFilterStatus: []*framework.Status{
				nil,
				nil,
				framework.NewStatus(framework.UnschedulableAndUnresolvable, `node(s) didn't find available persistent volumes to bind`),
			},
			wantScores: []int64{
				38,
				75,
				0,
			},
		},
		{
			name: "zonal volumes with close capacity are preferred",
			pod:  makePod("pod-a").withPVCVolume("pvc-a", "").Pod,
			nodes: []*v1.Node{
				makeNode("zone-a-node-a").
					withLabel("topology.kubernetes.io/region", "region-a").
					withLabel("topology.kubernetes.io/zone", "zone-a").Node,
				makeNode("zone-a-node-b").
					withLabel("topology.kubernetes.io/region", "region-a").
					withLabel("topology.kubernetes.io/zone", "zone-a").Node,
				makeNode("zone-b-node-a").
					withLabel("topology.kubernetes.io/region", "region-b").
					withLabel("topology.kubernetes.io/zone", "zone-b").Node,
				makeNode("zone-b-node-b").
					withLabel("topology.kubernetes.io/region", "region-b").
					withLabel("topology.kubernetes.io/zone", "zone-b").Node,
				makeNode("zone-c-node-a").
					withLabel("topology.kubernetes.io/region", "region-c").
					withLabel("topology.kubernetes.io/zone", "zone-c").Node,
				makeNode("zone-c-node-b").
					withLabel("topology.kubernetes.io/region", "region-c").
					withLabel("topology.kubernetes.io/zone", "zone-c").Node,
			},
			pvcs: []*v1.PersistentVolumeClaim{
				makePVC("pvc-a", waitSC.Name).withRequestStorage(resource.MustParse("50Gi")).PersistentVolumeClaim,
			},
			pvs: []*v1.PersistentVolume{
				makePV("pv-a-0", waitSC.Name).
					withPhase(v1.VolumeAvailable).
					withCapacity(resource.MustParse("200Gi")).
					withNodeAffinity(map[string][]string{
						"topology.kubernetes.io/region": {"region-a"},
						"topology.kubernetes.io/zone":   {"zone-a"},
					}).PersistentVolume,
				makePV("pv-a-1", waitSC.Name).
					withPhase(v1.VolumeAvailable).
					withCapacity(resource.MustParse("200Gi")).
					withNodeAffinity(map[string][]string{
						"topology.kubernetes.io/region": {"region-a"},
						"topology.kubernetes.io/zone":   {"zone-a"},
					}).PersistentVolume,
				makePV("pv-b-0", waitSC.Name).
					withPhase(v1.VolumeAvailable).
					withCapacity(resource.MustParse("100Gi")).
					withNodeAffinity(map[string][]string{
						"topology.kubernetes.io/region": {"region-b"},
						"topology.kubernetes.io/zone":   {"zone-b"},
					}).PersistentVolume,
				makePV("pv-b-1", waitSC.Name).
					withPhase(v1.VolumeAvailable).
					withCapacity(resource.MustParse("100Gi")).
					withNodeAffinity(map[string][]string{
						"topology.kubernetes.io/region": {"region-b"},
						"topology.kubernetes.io/zone":   {"zone-b"},
					}).PersistentVolume,
			},
			fts: feature.Features{
				EnableVolumeCapacityPriority: true,
			},
			wantPreFilterStatus: nil,
			wantStateAfterPreFilter: &stateData{
				podVolumeClaims: &PodVolumeClaims{
					boundClaims: []*v1.PersistentVolumeClaim{},
					unboundClaimsDelayBinding: []*v1.PersistentVolumeClaim{
						makePVC("pvc-a", waitSC.Name).withRequestStorage(resource.MustParse("50Gi")).PersistentVolumeClaim,
					},
					unboundVolumesDelayBinding: map[string][]*v1.PersistentVolume{
						waitSC.Name: {
							makePV("pv-a-0", waitSC.Name).
								withPhase(v1.VolumeAvailable).
								withCapacity(resource.MustParse("200Gi")).
								withNodeAffinity(map[string][]string{
									"topology.kubernetes.io/region": {"region-a"},
									"topology.kubernetes.io/zone":   {"zone-a"},
								}).PersistentVolume,
							makePV("pv-a-1", waitSC.Name).
								withPhase(v1.VolumeAvailable).
								withCapacity(resource.MustParse("200Gi")).
								withNodeAffinity(map[string][]string{
									"topology.kubernetes.io/region": {"region-a"},
									"topology.kubernetes.io/zone":   {"zone-a"},
								}).PersistentVolume,
							makePV("pv-b-0", waitSC.Name).
								withPhase(v1.VolumeAvailable).
								withCapacity(resource.MustParse("100Gi")).
								withNodeAffinity(map[string][]string{
									"topology.kubernetes.io/region": {"region-b"},
									"topology.kubernetes.io/zone":   {"zone-b"},
								}).PersistentVolume,
							makePV("pv-b-1", waitSC.Name).
								withPhase(v1.VolumeAvailable).
								withCapacity(resource.MustParse("100Gi")).
								withNodeAffinity(map[string][]string{
									"topology.kubernetes.io/region": {"region-b"},
									"topology.kubernetes.io/zone":   {"zone-b"},
								}).PersistentVolume,
						},
					},
				},
				podVolumesByNode: map[string]*PodVolumes{},
			},
			wantFilterStatus: []*framework.Status{
				nil,
				nil,
				nil,
				nil,
				framework.NewStatus(framework.UnschedulableAndUnresolvable, `node(s) didn't find available persistent volumes to bind`),
				framework.NewStatus(framework.UnschedulableAndUnresolvable, `node(s) didn't find available persistent volumes to bind`),
			},
			wantScores: []int64{
				25,
				25,
				50,
				50,
				0,
				0,
			},
		},
		{
			name: "zonal volumes with close capacity are preferred (custom shape)",
			pod:  makePod("pod-a").withPVCVolume("pvc-a", "").Pod,
			nodes: []*v1.Node{
				makeNode("zone-a-node-a").
					withLabel("topology.kubernetes.io/region", "region-a").
					withLabel("topology.kubernetes.io/zone", "zone-a").Node,
				makeNode("zone-a-node-b").
					withLabel("topology.kubernetes.io/region", "region-a").
					withLabel("topology.kubernetes.io/zone", "zone-a").Node,
				makeNode("zone-b-node-a").
					withLabel("topology.kubernetes.io/region", "region-b").
					withLabel("topology.kubernetes.io/zone", "zone-b").Node,
				makeNode("zone-b-node-b").
					withLabel("topology.kubernetes.io/region", "region-b").
					withLabel("topology.kubernetes.io/zone", "zone-b").Node,
				makeNode("zone-c-node-a").
					withLabel("topology.kubernetes.io/region", "region-c").
					withLabel("topology.kubernetes.io/zone", "zone-c").Node,
				makeNode("zone-c-node-b").
					withLabel("topology.kubernetes.io/region", "region-c").
					withLabel("topology.kubernetes.io/zone", "zone-c").Node,
			},
			pvcs: []*v1.PersistentVolumeClaim{
				makePVC("pvc-a", waitSC.Name).withRequestStorage(resource.MustParse("50Gi")).PersistentVolumeClaim,
			},
			pvs: []*v1.PersistentVolume{
				makePV("pv-a-0", waitSC.Name).
					withPhase(v1.VolumeAvailable).
					withCapacity(resource.MustParse("200Gi")).
					withNodeAffinity(map[string][]string{
						"topology.kubernetes.io/region": {"region-a"},
						"topology.kubernetes.io/zone":   {"zone-a"},
					}).PersistentVolume,
				makePV("pv-a-1", waitSC.Name).
					withPhase(v1.VolumeAvailable).
					withCapacity(resource.MustParse("200Gi")).
					withNodeAffinity(map[string][]string{
						"topology.kubernetes.io/region": {"region-a"},
						"topology.kubernetes.io/zone":   {"zone-a"},
					}).PersistentVolume,
				makePV("pv-b-0", waitSC.Name).
					withPhase(v1.VolumeAvailable).
					withCapacity(resource.MustParse("100Gi")).
					withNodeAffinity(map[string][]string{
						"topology.kubernetes.io/region": {"region-b"},
						"topology.kubernetes.io/zone":   {"zone-b"},
					}).PersistentVolume,
				makePV("pv-b-1", waitSC.Name).
					withPhase(v1.VolumeAvailable).
					withCapacity(resource.MustParse("100Gi")).
					withNodeAffinity(map[string][]string{
						"topology.kubernetes.io/region": {"region-b"},
						"topology.kubernetes.io/zone":   {"zone-b"},
					}).PersistentVolume,
			},
			fts: feature.Features{
				EnableVolumeCapacityPriority: true,
			},
			args: &config.VolumeBindingArgs{
				BindTimeoutSeconds: 300,
				Shape: []config.UtilizationShapePoint{
					{
						Utilization: 0,
						Score:       0,
					},
					{
						Utilization: 50,
						Score:       3,
					},
					{
						Utilization: 100,
						Score:       5,
					},
				},
			},
			wantPreFilterStatus: nil,
			wantStateAfterPreFilter: &stateData{
				podVolumeClaims: &PodVolumeClaims{
					boundClaims: []*v1.PersistentVolumeClaim{},
					unboundClaimsDelayBinding: []*v1.PersistentVolumeClaim{
						makePVC("pvc-a", waitSC.Name).withRequestStorage(resource.MustParse("50Gi")).PersistentVolumeClaim,
					},
					unboundClaimsImmediate: nil,
					unboundVolumesDelayBinding: map[string][]*v1.PersistentVolume{
						waitSC.Name: {
							makePV("pv-a-0", waitSC.Name).
								withPhase(v1.VolumeAvailable).
								withCapacity(resource.MustParse("200Gi")).
								withNodeAffinity(map[string][]string{
									"topology.kubernetes.io/region": {"region-a"},
									"topology.kubernetes.io/zone":   {"zone-a"},
								}).PersistentVolume,
							makePV("pv-a-1", waitSC.Name).
								withPhase(v1.VolumeAvailable).
								withCapacity(resource.MustParse("200Gi")).
								withNodeAffinity(map[string][]string{
									"topology.kubernetes.io/region": {"region-a"},
									"topology.kubernetes.io/zone":   {"zone-a"},
								}).PersistentVolume,
							makePV("pv-b-0", waitSC.Name).
								withPhase(v1.VolumeAvailable).
								withCapacity(resource.MustParse("100Gi")).
								withNodeAffinity(map[string][]string{
									"topology.kubernetes.io/region": {"region-b"},
									"topology.kubernetes.io/zone":   {"zone-b"},
								}).PersistentVolume,
							makePV("pv-b-1", waitSC.Name).
								withPhase(v1.VolumeAvailable).
								withCapacity(resource.MustParse("100Gi")).
								withNodeAffinity(map[string][]string{
									"topology.kubernetes.io/region": {"region-b"},
									"topology.kubernetes.io/zone":   {"zone-b"},
								}).PersistentVolume,
						},
					},
				},
				podVolumesByNode: map[string]*PodVolumes{},
			},
			wantFilterStatus: []*framework.Status{
				nil,
				nil,
				nil,
				nil,
				framework.NewStatus(framework.UnschedulableAndUnresolvable, `node(s) didn't find available persistent volumes to bind`),
				framework.NewStatus(framework.UnschedulableAndUnresolvable, `node(s) didn't find available persistent volumes to bind`),
			},
			wantScores: []int64{
				15,
				15,
				30,
				30,
				0,
				0,
			},
		},
	}

	for _, item := range table {
		t.Run(item.name, func(t *testing.T) {
			_, ctx := ktesting.NewTestContext(t)
			ctx, cancel := context.WithCancel(ctx)
			defer cancel()
			client := fake.NewSimpleClientset()
			informerFactory := informers.NewSharedInformerFactory(client, 0)
			opts := []runtime.Option{
				runtime.WithClientSet(client),
				runtime.WithInformerFactory(informerFactory),
			}
			fh, err := runtime.NewFramework(ctx, nil, nil, opts...)
			if err != nil {
				t.Fatal(err)
			}

			args := item.args
			if args == nil {
				// default args if the args is not specified in test cases
				args = &config.VolumeBindingArgs{
					BindTimeoutSeconds: 300,
				}
				if item.fts.EnableVolumeCapacityPriority {
					args.Shape = defaultShapePoint
				}
			}

			pl, err := New(ctx, args, fh, item.fts)
			if err != nil {
				t.Fatal(err)
			}

			t.Log("Feed testing data and wait for them to be synced")
			client.StorageV1().StorageClasses().Create(ctx, immediateSC, metav1.CreateOptions{})
			client.StorageV1().StorageClasses().Create(ctx, waitSC, metav1.CreateOptions{})
			client.StorageV1().StorageClasses().Create(ctx, waitHDDSC, metav1.CreateOptions{})
			for _, node := range item.nodes {
				client.CoreV1().Nodes().Create(ctx, node, metav1.CreateOptions{})
			}
			for _, pvc := range item.pvcs {
				client.CoreV1().PersistentVolumeClaims(pvc.Namespace).Create(ctx, pvc, metav1.CreateOptions{})
			}
			for _, pv := range item.pvs {
				client.CoreV1().PersistentVolumes().Create(ctx, pv, metav1.CreateOptions{})
			}

			t.Log("Start informer factory after initialization")
			informerFactory.Start(ctx.Done())

			t.Log("Wait for all started informers' cache were synced")
			informerFactory.WaitForCacheSync(ctx.Done())

			t.Log("Verify")

			p := pl.(*VolumeBinding)
			nodeInfos := make([]*framework.NodeInfo, 0)
			for _, node := range item.nodes {
				nodeInfo := framework.NewNodeInfo()
				nodeInfo.SetNode(node)
				nodeInfos = append(nodeInfos, nodeInfo)
			}
			state := framework.NewCycleState()

			t.Logf("Verify: call PreFilter and check status")
			gotPreFilterResult, gotPreFilterStatus := p.PreFilter(ctx, state, item.pod)
			assert.Equal(t, item.wantPreFilterStatus, gotPreFilterStatus)
			assert.Equal(t, item.wantPreFilterResult, gotPreFilterResult)

			if !gotPreFilterStatus.IsSuccess() {
				// scheduler framework will skip Filter if PreFilter fails
				return
			}

			t.Logf("Verify: check state after prefilter phase")
			got, err := getStateData(state)
			if err != nil {
				t.Fatal(err)
			}
			stateCmpOpts := []cmp.Option{
				cmp.AllowUnexported(stateData{}),
				cmp.AllowUnexported(PodVolumeClaims{}),
				cmpopts.IgnoreFields(stateData{}, "Mutex"),
				cmpopts.SortSlices(func(a *v1.PersistentVolume, b *v1.PersistentVolume) bool {
					return a.Name < b.Name
				}),
				cmpopts.SortSlices(func(a v1.NodeSelectorRequirement, b v1.NodeSelectorRequirement) bool {
					return a.Key < b.Key
				}),
			}
			if diff := cmp.Diff(item.wantStateAfterPreFilter, got, stateCmpOpts...); diff != "" {
				t.Errorf("state got after prefilter does not match (-want,+got):\n%s", diff)
			}

			t.Logf("Verify: call Filter and check status")
			for i, nodeInfo := range nodeInfos {
				gotStatus := p.Filter(ctx, state, item.pod, nodeInfo)
				assert.Equal(t, item.wantFilterStatus[i], gotStatus)
			}

			t.Logf("Verify: call PreScore and check status")
			gotPreScoreStatus := p.PreScore(ctx, state, item.pod, tf.BuildNodeInfos(item.nodes))
			if diff := cmp.Diff(item.wantPreScoreStatus, gotPreScoreStatus); diff != "" {
				t.Errorf("state got after prescore does not match (-want,+got):\n%s", diff)
			}
			if !gotPreScoreStatus.IsSuccess() {
				return
			}

			t.Logf("Verify: Score")
			for i, node := range item.nodes {
				score, status := p.Score(ctx, state, item.pod, node.Name)
				if !status.IsSuccess() {
					t.Errorf("Score expects success status, got: %v", status)
				}
				if score != item.wantScores[i] {
					t.Errorf("Score expects score %d for node %q, got: %d", item.wantScores[i], node.Name, score)
				}
			}
		})
	}
}
-e 
func helloWorld() {
    println("hello world")
}
