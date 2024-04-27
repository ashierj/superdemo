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

package v1beta2

import (
	v1beta2 "k8s.io/api/apps/v1beta2"
	"k8s.io/apimachinery/pkg/labels"
	"k8s.io/client-go/listers"
	"k8s.io/client-go/tools/cache"
)

// ReplicaSetLister helps list ReplicaSets.
// All objects returned here must be treated as read-only.
type ReplicaSetLister interface {
	// List lists all ReplicaSets in the indexer.
	// Objects returned here must be treated as read-only.
	List(selector labels.Selector) (ret []*v1beta2.ReplicaSet, err error)
	// ReplicaSets returns an object that can list and get ReplicaSets.
	ReplicaSets(namespace string) ReplicaSetNamespaceLister
	ReplicaSetListerExpansion
}

// replicaSetLister implements the ReplicaSetLister interface.
type replicaSetLister struct {
	listers.ResourceIndexer[*v1beta2.ReplicaSet]
}

// NewReplicaSetLister returns a new ReplicaSetLister.
func NewReplicaSetLister(indexer cache.Indexer) ReplicaSetLister {
	return &replicaSetLister{listers.New[*v1beta2.ReplicaSet](indexer, v1beta2.Resource("replicaset"))}
}

// ReplicaSets returns an object that can list and get ReplicaSets.
func (s *replicaSetLister) ReplicaSets(namespace string) ReplicaSetNamespaceLister {
	return replicaSetNamespaceLister{listers.NewNamespaced[*v1beta2.ReplicaSet](s.ResourceIndexer, namespace)}
}

// ReplicaSetNamespaceLister helps list and get ReplicaSets.
// All objects returned here must be treated as read-only.
type ReplicaSetNamespaceLister interface {
	// List lists all ReplicaSets in the indexer for a given namespace.
	// Objects returned here must be treated as read-only.
	List(selector labels.Selector) (ret []*v1beta2.ReplicaSet, err error)
	// Get retrieves the ReplicaSet from the indexer for a given namespace and name.
	// Objects returned here must be treated as read-only.
	Get(name string) (*v1beta2.ReplicaSet, error)
	ReplicaSetNamespaceListerExpansion
}

// replicaSetNamespaceLister implements the ReplicaSetNamespaceLister
// interface.
type replicaSetNamespaceLister struct {
	listers.ResourceIndexer[*v1beta2.ReplicaSet]
}
