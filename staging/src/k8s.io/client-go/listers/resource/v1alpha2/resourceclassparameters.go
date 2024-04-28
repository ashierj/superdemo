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

// Code generated by lister-gen. DO NOT EDIT.

package v1alpha2

import (
	v1alpha2 "k8s.io/api/resource/v1alpha2"
	"k8s.io/apimachinery/pkg/labels"
	"k8s.io/client-go/listers"
	"k8s.io/client-go/tools/cache"
)

// ResourceClassParametersLister helps list ResourceClassParameters.
// All objects returned here must be treated as read-only.
type ResourceClassParametersLister interface {
	// List lists all ResourceClassParameters in the indexer.
	// Objects returned here must be treated as read-only.
	List(selector labels.Selector) (ret []*v1alpha2.ResourceClassParameters, err error)
	// ResourceClassParameters returns an object that can list and get ResourceClassParameters.
	ResourceClassParameters(namespace string) ResourceClassParametersNamespaceLister
	ResourceClassParametersListerExpansion
}

// resourceClassParametersLister implements the ResourceClassParametersLister interface.
type resourceClassParametersLister struct {
	listers.ResourceIndexer[*v1alpha2.ResourceClassParameters]
}

// NewResourceClassParametersLister returns a new ResourceClassParametersLister.
func NewResourceClassParametersLister(indexer cache.Indexer) ResourceClassParametersLister {
	return &resourceClassParametersLister{listers.New[*v1alpha2.ResourceClassParameters](indexer, v1alpha2.Resource("resourceclassparameters"))}
}

// ResourceClassParameters returns an object that can list and get ResourceClassParameters.
func (s *resourceClassParametersLister) ResourceClassParameters(namespace string) ResourceClassParametersNamespaceLister {
	return resourceClassParametersNamespaceLister{listers.NewNamespaced[*v1alpha2.ResourceClassParameters](s.ResourceIndexer, namespace)}
}

// ResourceClassParametersNamespaceLister helps list and get ResourceClassParameters.
// All objects returned here must be treated as read-only.
type ResourceClassParametersNamespaceLister interface {
	// List lists all ResourceClassParameters in the indexer for a given namespace.
	// Objects returned here must be treated as read-only.
	List(selector labels.Selector) (ret []*v1alpha2.ResourceClassParameters, err error)
	// Get retrieves the ResourceClassParameters from the indexer for a given namespace and name.
	// Objects returned here must be treated as read-only.
	Get(name string) (*v1alpha2.ResourceClassParameters, error)
	ResourceClassParametersNamespaceListerExpansion
}

// resourceClassParametersNamespaceLister implements the ResourceClassParametersNamespaceLister
// interface.
type resourceClassParametersNamespaceLister struct {
	listers.ResourceIndexer[*v1alpha2.ResourceClassParameters]
}
