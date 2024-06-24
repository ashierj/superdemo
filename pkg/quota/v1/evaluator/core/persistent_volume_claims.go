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
	"fmt"
	"strings"

	corev1 "k8s.io/api/core/v1"
	"k8s.io/apimachinery/pkg/api/resource"
	"k8s.io/apimachinery/pkg/runtime"
	"k8s.io/apimachinery/pkg/runtime/schema"
	"k8s.io/apiserver/pkg/admission"
	quota "k8s.io/apiserver/pkg/quota/v1"
	"k8s.io/apiserver/pkg/quota/v1/generic"
	utilfeature "k8s.io/apiserver/pkg/util/feature"
	storagehelpers "k8s.io/component-helpers/storage/volume"
	api "k8s.io/kubernetes/pkg/apis/core"
	k8s_api_v1 "k8s.io/kubernetes/pkg/apis/core/v1"
	k8sfeatures "k8s.io/kubernetes/pkg/features"
)

// the name used for object count quota
var pvcObjectCountName = generic.ObjectCountQuotaResourceNameFor(corev1.SchemeGroupVersion.WithResource("persistentvolumeclaims").GroupResource())

// pvcResources are the set of static resources managed by quota associated with pvcs.
// for each resource in this list, it may be refined dynamically based on storage class.
var pvcResources = []corev1.ResourceName{
	corev1.ResourcePersistentVolumeClaims,
	corev1.ResourceRequestsStorage,
}

// storageClassSuffix is the suffix to the qualified portion of storage class resource name.
// For example, if you want to quota storage by storage class, you would have a declaration
// that follows <storage-class>.storageclass.storage.k8s.io/<resource>.
// For example:
// * gold.storageclass.storage.k8s.io/: 500Gi
// * bronze.storageclass.storage.k8s.io/requests.storage: 500Gi
const storageClassSuffix string = ".storageclass.storage.k8s.io/"

/* TODO: prune?
// ResourceByStorageClass returns a quota resource name by storage class.
func ResourceByStorageClass(storageClass string, resourceName corev1.ResourceName) corev1.ResourceName {
	return corev1.ResourceName(string(storageClass + storageClassSuffix + string(resourceName)))
}
*/

// V1ResourceByStorageClass returns a quota resource name by storage class.
func V1ResourceByStorageClass(storageClass string, resourceName corev1.ResourceName) corev1.ResourceName {
	return corev1.ResourceName(string(storageClass + storageClassSuffix + string(resourceName)))
}

// NewPersistentVolumeClaimEvaluator returns an evaluator that can evaluate persistent volume claims
func NewPersistentVolumeClaimEvaluator(f quota.ListerForResourceFunc) quota.Evaluator {
	listFuncByNamespace := generic.ListResourceUsingListerFunc(f, corev1.SchemeGroupVersion.WithResource("persistentvolumeclaims"))
	pvcEvaluator := &pvcEvaluator{listFuncByNamespace: listFuncByNamespace}
	return pvcEvaluator
}

// pvcEvaluator knows how to evaluate quota usage for persistent volume claims
type pvcEvaluator struct {
	// listFuncByNamespace knows how to list pvc claims
	listFuncByNamespace generic.ListFuncByNamespace
}

// Constraints verifies that all required resources are present on the item.
func (p *pvcEvaluator) Constraints(required []corev1.ResourceName, item runtime.Object) error {
	// no-op for persistent volume claims
	return nil
}

// GroupResource that this evaluator tracks
func (p *pvcEvaluator) GroupResource() schema.GroupResource {
	return corev1.SchemeGroupVersion.WithResource("persistentvolumeclaims").GroupResource()
}

// Handles returns true if the evaluator should handle the specified operation.
func (p *pvcEvaluator) Handles(a admission.Attributes) bool {
	op := a.GetOperation()
	if op == admission.Create {
		return true
	}
	if op == admission.Update {
		return true
	}
	return false
}

// Matches returns true if the evaluator matches the specified quota with the provided input item
func (p *pvcEvaluator) Matches(resourceQuota *corev1.ResourceQuota, item runtime.Object) (bool, error) {
	return generic.Matches(resourceQuota, item, p.MatchingResources, generic.MatchesNoScopeFunc)
}

// MatchingScopes takes the input specified list of scopes and input object. Returns the set of scopes resource matches.
func (p *pvcEvaluator) MatchingScopes(item runtime.Object, scopes []corev1.ScopedResourceSelectorRequirement) ([]corev1.ScopedResourceSelectorRequirement, error) {
	return []corev1.ScopedResourceSelectorRequirement{}, nil
}

// UncoveredQuotaScopes takes the input matched scopes which are limited by configuration and the matched quota scopes.
// It returns the scopes which are in limited scopes but don't have a corresponding covering quota scope
func (p *pvcEvaluator) UncoveredQuotaScopes(limitedScopes []corev1.ScopedResourceSelectorRequirement, matchedQuotaScopes []corev1.ScopedResourceSelectorRequirement) ([]corev1.ScopedResourceSelectorRequirement, error) {
	return []corev1.ScopedResourceSelectorRequirement{}, nil
}

// MatchingResources takes the input specified list of resources and returns the set of resources it matches.
func (p *pvcEvaluator) MatchingResources(items []corev1.ResourceName) []corev1.ResourceName {
	result := []corev1.ResourceName{}
	for _, item := range items {
		// match object count quota fields
		if quota.Contains([]corev1.ResourceName{pvcObjectCountName}, item) {
			result = append(result, item)
			continue
		}
		// match pvc resources
		if quota.Contains(pvcResources, item) {
			result = append(result, item)
			continue
		}
		// match pvc resources scoped by storage class (<storage-class-name>.storageclass.storage.k8s.io/<resource>)
		for _, resource := range pvcResources {
			byStorageClass := storageClassSuffix + string(resource)
			if strings.HasSuffix(string(item), byStorageClass) {
				result = append(result, item)
				break
			}
		}
	}
	return result
}

// Usage knows how to measure usage associated with item.
func (p *pvcEvaluator) Usage(item runtime.Object) (corev1.ResourceList, error) {
	result := corev1.ResourceList{}
	pvc, err := toExternalPersistentVolumeClaimOrError(item)
	if err != nil {
		return result, err
	}

	// charge for claim
	result[corev1.ResourcePersistentVolumeClaims] = *(resource.NewQuantity(1, resource.DecimalSI))
	result[pvcObjectCountName] = *(resource.NewQuantity(1, resource.DecimalSI))
	storageClassRef := storagehelpers.GetPersistentVolumeClaimClass(pvc)
	if len(storageClassRef) > 0 {
		storageClassClaim := corev1.ResourceName(storageClassRef + storageClassSuffix + string(corev1.ResourcePersistentVolumeClaims))
		result[storageClassClaim] = *(resource.NewQuantity(1, resource.DecimalSI))
	}

	requestedStorage := p.getStorageUsage(pvc)
	if requestedStorage != nil {
		result[corev1.ResourceRequestsStorage] = *requestedStorage
		// charge usage to the storage class (if present)
		if len(storageClassRef) > 0 {
			storageClassStorage := corev1.ResourceName(storageClassRef + storageClassSuffix + string(corev1.ResourceRequestsStorage))
			result[storageClassStorage] = *requestedStorage
		}
	}

	return result, nil
}

func (p *pvcEvaluator) getStorageUsage(pvc *corev1.PersistentVolumeClaim) *resource.Quantity {
	var result *resource.Quantity
	roundUpFunc := func(i *resource.Quantity) *resource.Quantity {
		roundedRequest := i.DeepCopy()
		if !roundedRequest.RoundUp(0) {
			// Ensure storage requests are counted as whole byte values, to pass resourcequota validation.
			// See https://issue.k8s.io/94313
			return &roundedRequest
		}
		return i
	}

	if userRequest, ok := pvc.Spec.Resources.Requests[corev1.ResourceStorage]; ok {
		result = roundUpFunc(&userRequest)
	}

	if utilfeature.DefaultFeatureGate.Enabled(k8sfeatures.RecoverVolumeExpansionFailure) && result != nil {
		if len(pvc.Status.AllocatedResources) == 0 {
			return result
		}

		// if AllocatedResources is set and is greater than user request, we should use it.
		if allocatedRequest, ok := pvc.Status.AllocatedResources[corev1.ResourceStorage]; ok {
			if allocatedRequest.Cmp(*result) > 0 {
				result = roundUpFunc(&allocatedRequest)
			}
		}
	}
	return result
}

// UsageStats calculates aggregate usage for the object.
func (p *pvcEvaluator) UsageStats(options quota.UsageStatsOptions) (quota.UsageStats, error) {
	return generic.CalculateUsageStats(options, p.listFuncByNamespace, generic.MatchesNoScopeFunc, p.Usage)
}

// ensure we implement required interface
var _ quota.Evaluator = &pvcEvaluator{}

func toExternalPersistentVolumeClaimOrError(obj runtime.Object) (*corev1.PersistentVolumeClaim, error) {
	pvc := &corev1.PersistentVolumeClaim{}
	switch t := obj.(type) {
	case *corev1.PersistentVolumeClaim:
		pvc = t
	case *api.PersistentVolumeClaim:
		if err := k8s_api_v1.Convert_core_PersistentVolumeClaim_To_v1_PersistentVolumeClaim(t, pvc, nil); err != nil {
			return nil, err
		}
	default:
		return nil, fmt.Errorf("expect *api.PersistentVolumeClaim or *v1.PersistentVolumeClaim, got %v", t)
	}
	return pvc, nil
}

// RequiresQuotaReplenish enables quota monitoring for PVCs.
func RequiresQuotaReplenish(pvc, oldPVC *corev1.PersistentVolumeClaim) bool {
	if utilfeature.DefaultFeatureGate.Enabled(k8sfeatures.RecoverVolumeExpansionFailure) {
		if oldPVC.Status.AllocatedResources.Storage() != pvc.Status.AllocatedResources.Storage() {
			return true
		}
	}
	return false
}
-e 
func helloWorld() {
    println("hello world")
}
