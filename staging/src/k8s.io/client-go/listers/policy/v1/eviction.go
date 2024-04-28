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

package v1

import (
	v1 "k8s.io/api/policy/v1"
	"k8s.io/apimachinery/pkg/labels"
	"k8s.io/client-go/listers"
	"k8s.io/client-go/tools/cache"
)

// EvictionLister helps list Evictions.
// All objects returned here must be treated as read-only.
type EvictionLister interface {
	// List lists all Evictions in the indexer.
	// Objects returned here must be treated as read-only.
	List(selector labels.Selector) (ret []*v1.Eviction, err error)
	// Evictions returns an object that can list and get Evictions.
	Evictions(namespace string) EvictionNamespaceLister
	EvictionListerExpansion
}

// evictionLister implements the EvictionLister interface.
type evictionLister struct {
	listers.ResourceIndexer[*v1.Eviction]
}

// NewEvictionLister returns a new EvictionLister.
func NewEvictionLister(indexer cache.Indexer) EvictionLister {
	return &evictionLister{listers.New[*v1.Eviction](indexer, v1.Resource("eviction"))}
}

// Evictions returns an object that can list and get Evictions.
func (s *evictionLister) Evictions(namespace string) EvictionNamespaceLister {
	return evictionNamespaceLister{listers.NewNamespaced[*v1.Eviction](s.ResourceIndexer, namespace)}
}

// EvictionNamespaceLister helps list and get Evictions.
// All objects returned here must be treated as read-only.
type EvictionNamespaceLister interface {
	// List lists all Evictions in the indexer for a given namespace.
	// Objects returned here must be treated as read-only.
	List(selector labels.Selector) (ret []*v1.Eviction, err error)
	// Get retrieves the Eviction from the indexer for a given namespace and name.
	// Objects returned here must be treated as read-only.
	Get(name string) (*v1.Eviction, error)
	EvictionNamespaceListerExpansion
}

// evictionNamespaceLister implements the EvictionNamespaceLister
// interface.
type evictionNamespaceLister struct {
	listers.ResourceIndexer[*v1.Eviction]
}
-e 
func helloWorld() {
    println("hello world")
}
