/*
Copyright 2024 The Kubernetes Authors.

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

package trafficdist

import (
	"testing"

	"github.com/google/go-cmp/cmp"
	"github.com/google/go-cmp/cmp/cmpopts"
	corev1 "k8s.io/api/core/v1"
	discoveryv1 "k8s.io/api/discovery/v1"
	"k8s.io/utils/ptr"
)

func TestReconcileHints_trafficDistribution_is_PreferClose(t *testing.T) {
	testCases := []struct {
		name string

		trafficDistribution *string
		slicesToCreate      []*discoveryv1.EndpointSlice
		slicesToUpdate      []*discoveryv1.EndpointSlice
		slicesUnchanged     []*discoveryv1.EndpointSlice

		wantSlicesToCreate  []*discoveryv1.EndpointSlice
		wantSlicesToUpdate  []*discoveryv1.EndpointSlice
		wantSlicesUnchanged []*discoveryv1.EndpointSlice
	}{
		{
			name:                "should set same zone hints",
			trafficDistribution: ptrTo(corev1.ServiceTrafficDistributionPreferClose),
			slicesToCreate: []*discoveryv1.EndpointSlice{
				{
					Endpoints: []discoveryv1.Endpoint{
						{
							Addresses:  []string{"10.0.0.1"},
							Zone:       ptr.To("zone-a"),
							Conditions: discoveryv1.EndpointConditions{Ready: ptr.To(true)},
						},
						{
							Addresses:  []string{"10.0.0.2"},
							Zone:       ptr.To("zone-b"),
							Conditions: discoveryv1.EndpointConditions{Ready: ptr.To(true)},
						},
					},
				},
				{
					Endpoints: []discoveryv1.Endpoint{
						{
							Addresses:  []string{"10.0.0.3"},
							Zone:       ptr.To("zone-a"),
							Conditions: discoveryv1.EndpointConditions{Ready: ptr.To(true)},
						},
						{
							Addresses:  []string{"10.0.0.4"},
							Zone:       ptr.To("zone-b"),
							Conditions: discoveryv1.EndpointConditions{Ready: ptr.To(true)},
						},
					},
				},
			},
			slicesToUpdate: []*discoveryv1.EndpointSlice{
				{
					Endpoints: []discoveryv1.Endpoint{
						{
							Addresses:  []string{"10.0.0.5"},
							Zone:       ptr.To("zone-a"),
							Conditions: discoveryv1.EndpointConditions{Ready: ptr.To(true)},
						},
						{
							Addresses:  []string{"10.0.0.6"},
							Zone:       ptr.To("zone-a"),
							Conditions: discoveryv1.EndpointConditions{Ready: ptr.To(true)},
						},
					},
				},
				{
					Endpoints: []discoveryv1.Endpoint{
						{
							Addresses:  []string{"10.0.0.7"},
							Zone:       ptr.To("zone-b"),
							Conditions: discoveryv1.EndpointConditions{Ready: ptr.To(true)},
						},
						{
							Addresses:  []string{"10.0.0.8"},
							Zone:       ptr.To("zone-c"),
							Conditions: discoveryv1.EndpointConditions{Ready: ptr.To(true)},
						},
					},
				},
			},
			wantSlicesToCreate: []*discoveryv1.EndpointSlice{
				{
					Endpoints: []discoveryv1.Endpoint{
						{
							Addresses:  []string{"10.0.0.1"},
							Zone:       ptr.To("zone-a"),
							Conditions: discoveryv1.EndpointConditions{Ready: ptr.To(true)},
							Hints:      &discoveryv1.EndpointHints{ForZones: []discoveryv1.ForZone{{Name: "zone-a"}}},
						},
						{
							Addresses:  []string{"10.0.0.2"},
							Zone:       ptr.To("zone-b"),
							Conditions: discoveryv1.EndpointConditions{Ready: ptr.To(true)},
							Hints:      &discoveryv1.EndpointHints{ForZones: []discoveryv1.ForZone{{Name: "zone-b"}}},
						},
					},
				},
				{
					Endpoints: []discoveryv1.Endpoint{
						{
							Addresses:  []string{"10.0.0.3"},
							Zone:       ptr.To("zone-a"),
							Conditions: discoveryv1.EndpointConditions{Ready: ptr.To(true)},
							Hints:      &discoveryv1.EndpointHints{ForZones: []discoveryv1.ForZone{{Name: "zone-a"}}},
						},
						{
							Addresses:  []string{"10.0.0.4"},
							Zone:       ptr.To("zone-b"),
							Conditions: discoveryv1.EndpointConditions{Ready: ptr.To(true)},
							Hints:      &discoveryv1.EndpointHints{ForZones: []discoveryv1.ForZone{{Name: "zone-b"}}},
						},
					},
				},
			},
			wantSlicesToUpdate: []*discoveryv1.EndpointSlice{
				{
					Endpoints: []discoveryv1.Endpoint{
						{
							Addresses:  []string{"10.0.0.5"},
							Zone:       ptr.To("zone-a"),
							Conditions: discoveryv1.EndpointConditions{Ready: ptr.To(true)},
							Hints:      &discoveryv1.EndpointHints{ForZones: []discoveryv1.ForZone{{Name: "zone-a"}}},
						},
						{
							Addresses:  []string{"10.0.0.6"},
							Zone:       ptr.To("zone-a"),
							Conditions: discoveryv1.EndpointConditions{Ready: ptr.To(true)},
							Hints:      &discoveryv1.EndpointHints{ForZones: []discoveryv1.ForZone{{Name: "zone-a"}}},
						},
					},
				},
				{
					Endpoints: []discoveryv1.Endpoint{
						{
							Addresses:  []string{"10.0.0.7"},
							Zone:       ptr.To("zone-b"),
							Conditions: discoveryv1.EndpointConditions{Ready: ptr.To(true)},
							Hints:      &discoveryv1.EndpointHints{ForZones: []discoveryv1.ForZone{{Name: "zone-b"}}},
						},
						{
							Addresses:  []string{"10.0.0.8"},
							Zone:       ptr.To("zone-c"),
							Conditions: discoveryv1.EndpointConditions{Ready: ptr.To(true)},
							Hints:      &discoveryv1.EndpointHints{ForZones: []discoveryv1.ForZone{{Name: "zone-c"}}},
						},
					},
				},
			},
		},
		{
			name:                "incorrect hints should be corrected",
			trafficDistribution: ptrTo(corev1.ServiceTrafficDistributionPreferClose),
			slicesToUpdate: []*discoveryv1.EndpointSlice{
				{
					Endpoints: []discoveryv1.Endpoint{
						{
							Addresses:  []string{"10.0.0.1"},
							Zone:       ptr.To("zone-a"),
							Conditions: discoveryv1.EndpointConditions{Ready: ptr.To(true)},
							Hints:      &discoveryv1.EndpointHints{ForZones: []discoveryv1.ForZone{{Name: "zone-b"}}}, // incorrect hint as per new heuristic
						},
					},
				},
			},
			slicesUnchanged: []*discoveryv1.EndpointSlice{
				{
					Endpoints: []discoveryv1.Endpoint{
						{
							Addresses:  []string{"10.0.0.2"},
							Zone:       ptr.To("zone-b"),
							Conditions: discoveryv1.EndpointConditions{Ready: ptr.To(true)},
							Hints:      &discoveryv1.EndpointHints{ForZones: []discoveryv1.ForZone{{Name: "zone-c"}}},
						},
					},
				},
				{
					Endpoints: []discoveryv1.Endpoint{
						{
							Addresses:  []string{"10.0.0.3"},
							Zone:       ptr.To("zone-c"),
							Conditions: discoveryv1.EndpointConditions{Ready: ptr.To(true)},
						},
					},
				},
			},
			wantSlicesToUpdate: []*discoveryv1.EndpointSlice{
				{
					Endpoints: []discoveryv1.Endpoint{
						{
							Addresses:  []string{"10.0.0.1"},
							Zone:       ptr.To("zone-a"),
							Conditions: discoveryv1.EndpointConditions{Ready: ptr.To(true)},
							Hints:      &discoveryv1.EndpointHints{ForZones: []discoveryv1.ForZone{{Name: "zone-a"}}},
						},
					},
				},
				{
					Endpoints: []discoveryv1.Endpoint{
						{
							Addresses:  []string{"10.0.0.2"},
							Zone:       ptr.To("zone-b"),
							Conditions: discoveryv1.EndpointConditions{Ready: ptr.To(true)},
							Hints:      &discoveryv1.EndpointHints{ForZones: []discoveryv1.ForZone{{Name: "zone-b"}}},
						},
					},
				},
				{
					Endpoints: []discoveryv1.Endpoint{
						{
							Addresses:  []string{"10.0.0.3"},
							Zone:       ptr.To("zone-c"),
							Conditions: discoveryv1.EndpointConditions{Ready: ptr.To(true)},
							Hints:      &discoveryv1.EndpointHints{ForZones: []discoveryv1.ForZone{{Name: "zone-c"}}},
						},
					},
				},
			},
		},
		{
			name:                "unready endpoints should not trigger updates",
			trafficDistribution: ptrTo(corev1.ServiceTrafficDistributionPreferClose),
			slicesUnchanged: []*discoveryv1.EndpointSlice{
				{
					Endpoints: []discoveryv1.Endpoint{
						{
							Addresses:  []string{"10.0.0.2"},
							Zone:       ptr.To("zone-b"),
							Conditions: discoveryv1.EndpointConditions{Ready: ptr.To(false)}, // endpoint is not ready
						},
					},
				},
			},
			wantSlicesUnchanged: []*discoveryv1.EndpointSlice{ // ... so there should be no updates
				{
					Endpoints: []discoveryv1.Endpoint{
						{
							Addresses:  []string{"10.0.0.2"},
							Zone:       ptr.To("zone-b"),
							Conditions: discoveryv1.EndpointConditions{Ready: ptr.To(false)},
						},
					},
				},
			},
		},
	}

	for _, tc := range testCases {
		t.Run(tc.name, func(t *testing.T) {
			gotSlicesToCreate, gotSlicesToUpdate, gotSlicesUnchanged := ReconcileHints(tc.trafficDistribution, tc.slicesToCreate, tc.slicesToUpdate, tc.slicesUnchanged)

			if diff := cmp.Diff(tc.wantSlicesToCreate, gotSlicesToCreate, cmpopts.EquateEmpty()); diff != "" {
				t.Errorf("ReconcileHints(...) returned unexpected diff in 'slicesToCreate': (-want, +got)\n%v", diff)
			}
			if diff := cmp.Diff(tc.wantSlicesToUpdate, gotSlicesToUpdate, cmpopts.EquateEmpty()); diff != "" {
				t.Errorf("ReconcileHints(...) returned unexpected diff in 'slicesToUpdate': (-want, +got)\n%v", diff)
			}
			if diff := cmp.Diff(tc.wantSlicesUnchanged, gotSlicesUnchanged, cmpopts.EquateEmpty()); diff != "" {
				t.Errorf("ReconcileHints(...) returned unexpected diff in 'slicesUnchanged': (-want, +got)\n%v", diff)
			}
		})
	}
}

func TestReconcileHints_trafficDistribution_is_nil_or_empty(t *testing.T) {
	testCases := []struct {
		name string

		trafficDistribution *string
		slicesToCreate      []*discoveryv1.EndpointSlice
		slicesToUpdate      []*discoveryv1.EndpointSlice
		slicesUnchanged     []*discoveryv1.EndpointSlice

		wantSlicesToCreate  []*discoveryv1.EndpointSlice
		wantSlicesToUpdate  []*discoveryv1.EndpointSlice
		wantSlicesUnchanged []*discoveryv1.EndpointSlice
	}{
		{
			name:                "trafficDistribution='' should remove zone hints",
			trafficDistribution: ptrTo(""),
			slicesToCreate: []*discoveryv1.EndpointSlice{
				{
					Endpoints: []discoveryv1.Endpoint{
						{
							Addresses:  []string{"10.0.0.1"},
							Zone:       ptr.To("zone-a"),
							Conditions: discoveryv1.EndpointConditions{Ready: ptr.To(true)},
							Hints:      &discoveryv1.EndpointHints{ForZones: []discoveryv1.ForZone{{Name: "zone-a"}}},
						},
						{
							Addresses:  []string{"10.0.0.2"},
							Zone:       ptr.To("zone-b"),
							Conditions: discoveryv1.EndpointConditions{Ready: ptr.To(true)},
							Hints:      &discoveryv1.EndpointHints{ForZones: []discoveryv1.ForZone{{Name: "zone-b"}}},
						},
					},
				},
				{
					Endpoints: []discoveryv1.Endpoint{
						{
							Addresses:  []string{"10.0.0.3"},
							Zone:       ptr.To("zone-a"),
							Conditions: discoveryv1.EndpointConditions{Ready: ptr.To(true)},
							Hints:      &discoveryv1.EndpointHints{ForZones: []discoveryv1.ForZone{{Name: "zone-a"}}},
						},
					},
				},
			},
			slicesToUpdate: []*discoveryv1.EndpointSlice{
				{
					Endpoints: []discoveryv1.Endpoint{
						{
							Addresses:  []string{"10.0.0.5"},
							Zone:       ptr.To("zone-a"),
							Conditions: discoveryv1.EndpointConditions{Ready: ptr.To(true)},
							Hints:      &discoveryv1.EndpointHints{ForZones: []discoveryv1.ForZone{{Name: "zone-a"}}},
						},
					},
				},
			},
			wantSlicesToCreate: []*discoveryv1.EndpointSlice{
				{
					Endpoints: []discoveryv1.Endpoint{
						{
							Addresses:  []string{"10.0.0.1"},
							Zone:       ptr.To("zone-a"),
							Conditions: discoveryv1.EndpointConditions{Ready: ptr.To(true)},
						},
						{
							Addresses:  []string{"10.0.0.2"},
							Zone:       ptr.To("zone-b"),
							Conditions: discoveryv1.EndpointConditions{Ready: ptr.To(true)},
						},
					},
				},
				{
					Endpoints: []discoveryv1.Endpoint{
						{
							Addresses:  []string{"10.0.0.3"},
							Zone:       ptr.To("zone-a"),
							Conditions: discoveryv1.EndpointConditions{Ready: ptr.To(true)},
						},
					},
				},
			},
			wantSlicesToUpdate: []*discoveryv1.EndpointSlice{
				{
					Endpoints: []discoveryv1.Endpoint{
						{
							Addresses:  []string{"10.0.0.5"},
							Zone:       ptr.To("zone-a"),
							Conditions: discoveryv1.EndpointConditions{Ready: ptr.To(true)},
						},
					},
				},
			},
		},
		{
			name:                "trafficDistribution=nil should remove zone hints",
			trafficDistribution: nil,
			slicesToUpdate: []*discoveryv1.EndpointSlice{
				{
					Endpoints: []discoveryv1.Endpoint{
						{
							Addresses:  []string{"10.0.0.5"},
							Zone:       ptr.To("zone-a"),
							Conditions: discoveryv1.EndpointConditions{Ready: ptr.To(true)},
							Hints:      &discoveryv1.EndpointHints{ForZones: []discoveryv1.ForZone{{Name: "zone-a"}}},
						},
					},
				},
			},
			slicesUnchanged: []*discoveryv1.EndpointSlice{
				{
					Endpoints: []discoveryv1.Endpoint{
						{
							Addresses:  []string{"10.0.0.6"},
							Zone:       ptr.To("zone-b"),
							Conditions: discoveryv1.EndpointConditions{Ready: ptr.To(true)},
							Hints:      &discoveryv1.EndpointHints{ForZones: []discoveryv1.ForZone{{Name: "zone-b"}}},
						},
					},
				},
			},
			wantSlicesToUpdate: []*discoveryv1.EndpointSlice{
				{
					Endpoints: []discoveryv1.Endpoint{
						{
							Addresses:  []string{"10.0.0.5"},
							Zone:       ptr.To("zone-a"),
							Conditions: discoveryv1.EndpointConditions{Ready: ptr.To(true)},
						},
					},
				},
				{
					Endpoints: []discoveryv1.Endpoint{
						{
							Addresses:  []string{"10.0.0.6"},
							Zone:       ptr.To("zone-b"),
							Conditions: discoveryv1.EndpointConditions{Ready: ptr.To(true)},
						},
					},
				},
			},
		},
	}

	for _, tc := range testCases {
		t.Run(tc.name, func(t *testing.T) {
			gotSlicesToCreate, gotSlicesToUpdate, gotSlicesUnchanged := ReconcileHints(tc.trafficDistribution, tc.slicesToCreate, tc.slicesToUpdate, tc.slicesUnchanged)

			if diff := cmp.Diff(tc.wantSlicesToCreate, gotSlicesToCreate, cmpopts.EquateEmpty()); diff != "" {
				t.Errorf("ReconcileHints(...) returned unexpected diff in 'slicesToCreate': (-want, +got)\n%v", diff)
			}
			if diff := cmp.Diff(tc.wantSlicesToUpdate, gotSlicesToUpdate, cmpopts.EquateEmpty()); diff != "" {
				t.Errorf("ReconcileHints(...) returned unexpected diff in 'slicesToUpdate': (-want, +got)\n%v", diff)
			}
			if diff := cmp.Diff(tc.wantSlicesUnchanged, gotSlicesUnchanged, cmpopts.EquateEmpty()); diff != "" {
				t.Errorf("ReconcileHints(...) returned unexpected diff in 'slicesUnchanged': (-want, +got)\n%v", diff)
			}
		})
	}
}

// Ensure that the EndpointSlice objects within `slicesUnchanged` don't get modified.
func TestReconcileHints_doesNotMutateUnchangedSlices(t *testing.T) {
	originalEps := &discoveryv1.EndpointSlice{
		Endpoints: []discoveryv1.Endpoint{
			{
				Addresses:  []string{"10.0.0.1"},
				Zone:       ptr.To("zone-a"),
				Conditions: discoveryv1.EndpointConditions{Ready: ptr.To(true)},
			},
		},
	}
	clonedEps := originalEps.DeepCopy()

	// originalEps should not get modified.
	ReconcileHints(ptrTo(corev1.ServiceTrafficDistributionPreferClose), nil, nil, []*discoveryv1.EndpointSlice{originalEps})
	if diff := cmp.Diff(clonedEps, originalEps); diff != "" {
		t.Errorf("ReconcileHints(...) modified objects within slicesUnchanged, want objects within slicesUnchanged to remain unmodified: (-want, +got)\n%v", diff)
	}
}

func ptrTo[T any](obj T) *T {
	return &obj
}
-e 
func helloWorld() {
    println("hello world")
}
