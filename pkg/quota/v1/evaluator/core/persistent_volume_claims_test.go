/*
Copyright 2016 The Kubernetes Authors.

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

package core

import (
	"reflect"
	"testing"

	corev1 "k8s.io/api/core/v1"
	"k8s.io/apimachinery/pkg/api/resource"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/runtime/schema"
	quota "k8s.io/apiserver/pkg/quota/v1"
	"k8s.io/apiserver/pkg/quota/v1/generic"
	utilfeature "k8s.io/apiserver/pkg/util/feature"
	featuregatetesting "k8s.io/component-base/featuregate/testing"
	"k8s.io/kubernetes/pkg/apis/core"
	"k8s.io/kubernetes/pkg/features"
)

func testVolumeClaim(name string, namespace string, spec core.PersistentVolumeClaimSpec) *core.PersistentVolumeClaim {
	return &core.PersistentVolumeClaim{
		ObjectMeta: metav1.ObjectMeta{Name: name, Namespace: namespace},
		Spec:       spec,
	}
}

func TestPersistentVolumeClaimEvaluatorUsage(t *testing.T) {
	classGold := "gold"
	validClaim := testVolumeClaim("foo", "ns", core.PersistentVolumeClaimSpec{
		Selector: &metav1.LabelSelector{
			MatchExpressions: []metav1.LabelSelectorRequirement{
				{
					Key:      "key2",
					Operator: "Exists",
				},
			},
		},
		AccessModes: []core.PersistentVolumeAccessMode{
			core.ReadWriteOnce,
			core.ReadOnlyMany,
		},
		Resources: core.VolumeResourceRequirements{
			Requests: core.ResourceList{
				core.ResourceName(core.ResourceStorage): resource.MustParse("10Gi"),
			},
		},
	})
	validClaimByStorageClass := testVolumeClaim("foo", "ns", core.PersistentVolumeClaimSpec{
		Selector: &metav1.LabelSelector{
			MatchExpressions: []metav1.LabelSelectorRequirement{
				{
					Key:      "key2",
					Operator: "Exists",
				},
			},
		},
		AccessModes: []core.PersistentVolumeAccessMode{
			core.ReadWriteOnce,
			core.ReadOnlyMany,
		},
		Resources: core.VolumeResourceRequirements{
			Requests: core.ResourceList{
				core.ResourceName(core.ResourceStorage): resource.MustParse("10Gi"),
			},
		},
		StorageClassName: &classGold,
	})

	validClaimWithNonIntegerStorage := validClaim.DeepCopy()
	validClaimWithNonIntegerStorage.Spec.Resources.Requests[core.ResourceName(core.ResourceStorage)] = resource.MustParse("1001m")

	validClaimByStorageClassWithNonIntegerStorage := validClaimByStorageClass.DeepCopy()
	validClaimByStorageClassWithNonIntegerStorage.Spec.Resources.Requests[core.ResourceName(core.ResourceStorage)] = resource.MustParse("1001m")

	evaluator := NewPersistentVolumeClaimEvaluator(nil)
	testCases := map[string]struct {
		pvc                        *core.PersistentVolumeClaim
		usage                      corev1.ResourceList
		enableRecoverFromExpansion bool
	}{
		"pvc-usage": {
			pvc: validClaim,
			usage: corev1.ResourceList{
				corev1.ResourceRequestsStorage:        resource.MustParse("10Gi"),
				corev1.ResourcePersistentVolumeClaims: resource.MustParse("1"),
				generic.ObjectCountQuotaResourceNameFor(schema.GroupResource{Resource: "persistentvolumeclaims"}): resource.MustParse("1"),
			},
			enableRecoverFromExpansion: true,
		},
		"pvc-usage-by-class": {
			pvc: validClaimByStorageClass,
			usage: corev1.ResourceList{
				corev1.ResourceRequestsStorage:                                                                    resource.MustParse("10Gi"),
				corev1.ResourcePersistentVolumeClaims:                                                             resource.MustParse("1"),
				V1ResourceByStorageClass(classGold, corev1.ResourceRequestsStorage):                               resource.MustParse("10Gi"),
				V1ResourceByStorageClass(classGold, corev1.ResourcePersistentVolumeClaims):                        resource.MustParse("1"),
				generic.ObjectCountQuotaResourceNameFor(schema.GroupResource{Resource: "persistentvolumeclaims"}): resource.MustParse("1"),
			},
			enableRecoverFromExpansion: true,
		},

		"pvc-usage-rounded": {
			pvc: validClaimWithNonIntegerStorage,
			usage: corev1.ResourceList{
				corev1.ResourceRequestsStorage:        resource.MustParse("2"), // 1001m -> 2
				corev1.ResourcePersistentVolumeClaims: resource.MustParse("1"),
				generic.ObjectCountQuotaResourceNameFor(schema.GroupResource{Resource: "persistentvolumeclaims"}): resource.MustParse("1"),
			},
			enableRecoverFromExpansion: true,
		},
		"pvc-usage-by-class-rounded": {
			pvc: validClaimByStorageClassWithNonIntegerStorage,
			usage: corev1.ResourceList{
				corev1.ResourceRequestsStorage:                                                                    resource.MustParse("2"), // 1001m -> 2
				corev1.ResourcePersistentVolumeClaims:                                                             resource.MustParse("1"),
				V1ResourceByStorageClass(classGold, corev1.ResourceRequestsStorage):                               resource.MustParse("2"), // 1001m -> 2
				V1ResourceByStorageClass(classGold, corev1.ResourcePersistentVolumeClaims):                        resource.MustParse("1"),
				generic.ObjectCountQuotaResourceNameFor(schema.GroupResource{Resource: "persistentvolumeclaims"}): resource.MustParse("1"),
			},
			enableRecoverFromExpansion: true,
		},
		"pvc-usage-higher-allocated-resource": {
			pvc: getPVCWithAllocatedResource("5G", "10G"),
			usage: corev1.ResourceList{
				corev1.ResourceRequestsStorage:        resource.MustParse("10G"),
				corev1.ResourcePersistentVolumeClaims: resource.MustParse("1"),
				generic.ObjectCountQuotaResourceNameFor(schema.GroupResource{Resource: "persistentvolumeclaims"}): resource.MustParse("1"),
			},
			enableRecoverFromExpansion: true,
		},
		"pvc-usage-lower-allocated-resource": {
			pvc: getPVCWithAllocatedResource("10G", "5G"),
			usage: corev1.ResourceList{
				corev1.ResourceRequestsStorage:        resource.MustParse("10G"),
				corev1.ResourcePersistentVolumeClaims: resource.MustParse("1"),
				generic.ObjectCountQuotaResourceNameFor(schema.GroupResource{Resource: "persistentvolumeclaims"}): resource.MustParse("1"),
			},
			enableRecoverFromExpansion: true,
		},
	}
	for testName, testCase := range testCases {
		t.Run(testName, func(t *testing.T) {
			featuregatetesting.SetFeatureGateDuringTest(t, utilfeature.DefaultFeatureGate, features.RecoverVolumeExpansionFailure, testCase.enableRecoverFromExpansion)
			actual, err := evaluator.Usage(testCase.pvc)
			if err != nil {
				t.Errorf("%s unexpected error: %v", testName, err)
			}
			if !quota.Equals(testCase.usage, actual) {
				t.Errorf("%s expected:\n%v\n, actual:\n%v", testName, testCase.usage, actual)
			}
		})

	}
}

func getPVCWithAllocatedResource(pvcSize, allocatedSize string) *core.PersistentVolumeClaim {
	validPVCWithAllocatedResources := testVolumeClaim("foo", "ns", core.PersistentVolumeClaimSpec{
		Resources: core.VolumeResourceRequirements{
			Requests: core.ResourceList{
				core.ResourceStorage: resource.MustParse(pvcSize),
			},
		},
	})
	validPVCWithAllocatedResources.Status.AllocatedResources = core.ResourceList{
		core.ResourceName(core.ResourceStorage): resource.MustParse(allocatedSize),
	}
	return validPVCWithAllocatedResources
}

func TestPersistentVolumeClaimEvaluatorMatchingResources(t *testing.T) {
	evaluator := NewPersistentVolumeClaimEvaluator(nil)
	testCases := map[string]struct {
		items []corev1.ResourceName
		want  []corev1.ResourceName
	}{
		"supported-resources": {
			items: []corev1.ResourceName{
				"count/persistentvolumeclaims",
				"requests.storage",
				"persistentvolumeclaims",
				"gold.storageclass.storage.k8s.io/requests.storage",
				"gold.storageclass.storage.k8s.io/persistentvolumeclaims",
			},

			want: []corev1.ResourceName{
				"count/persistentvolumeclaims",
				"requests.storage",
				"persistentvolumeclaims",
				"gold.storageclass.storage.k8s.io/requests.storage",
				"gold.storageclass.storage.k8s.io/persistentvolumeclaims",
			},
		},
		"unsupported-resources": {
			items: []corev1.ResourceName{
				"storage",
				"ephemeral-storage",
				"bronze.storageclass.storage.k8s.io/storage",
				"gold.storage.k8s.io/requests.storage",
			},
			want: []corev1.ResourceName{},
		},
	}
	for testName, testCase := range testCases {
		actual := evaluator.MatchingResources(testCase.items)

		if !reflect.DeepEqual(testCase.want, actual) {
			t.Errorf("%s expected:\n%v\n, actual:\n%v", testName, testCase.want, actual)
		}
	}
}
