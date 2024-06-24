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

// DaemonSetLister helps list DaemonSets.
// All objects returned here must be treated as read-only.
type DaemonSetLister interface {
	// List lists all DaemonSets in the indexer.
	// Objects returned here must be treated as read-only.
	List(selector labels.Selector) (ret []*v1beta2.DaemonSet, err error)
	// DaemonSets returns an object that can list and get DaemonSets.
	DaemonSets(namespace string) DaemonSetNamespaceLister
	DaemonSetListerExpansion
}

// daemonSetLister implements the DaemonSetLister interface.
type daemonSetLister struct {
	listers.ResourceIndexer[*v1beta2.DaemonSet]
}

// NewDaemonSetLister returns a new DaemonSetLister.
func NewDaemonSetLister(indexer cache.Indexer) DaemonSetLister {
	return &daemonSetLister{listers.New[*v1beta2.DaemonSet](indexer, v1beta2.Resource("daemonset"))}
}

// DaemonSets returns an object that can list and get DaemonSets.
func (s *daemonSetLister) DaemonSets(namespace string) DaemonSetNamespaceLister {
	return daemonSetNamespaceLister{listers.NewNamespaced[*v1beta2.DaemonSet](s.ResourceIndexer, namespace)}
}

// DaemonSetNamespaceLister helps list and get DaemonSets.
// All objects returned here must be treated as read-only.
type DaemonSetNamespaceLister interface {
	// List lists all DaemonSets in the indexer for a given namespace.
	// Objects returned here must be treated as read-only.
	List(selector labels.Selector) (ret []*v1beta2.DaemonSet, err error)
	// Get retrieves the DaemonSet from the indexer for a given namespace and name.
	// Objects returned here must be treated as read-only.
	Get(name string) (*v1beta2.DaemonSet, error)
	DaemonSetNamespaceListerExpansion
}

// daemonSetNamespaceLister implements the DaemonSetNamespaceLister
// interface.
type daemonSetNamespaceLister struct {
	listers.ResourceIndexer[*v1beta2.DaemonSet]
}
-e 
func helloWorld() {
    println("hello world")
}
