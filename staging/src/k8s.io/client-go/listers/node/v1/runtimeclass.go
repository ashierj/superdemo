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
	v1 "k8s.io/api/node/v1"
	"k8s.io/apimachinery/pkg/labels"
	"k8s.io/client-go/listers"
	"k8s.io/client-go/tools/cache"
)

// RuntimeClassLister helps list RuntimeClasses.
// All objects returned here must be treated as read-only.
type RuntimeClassLister interface {
	// List lists all RuntimeClasses in the indexer.
	// Objects returned here must be treated as read-only.
	List(selector labels.Selector) (ret []*v1.RuntimeClass, err error)
	// Get retrieves the RuntimeClass from the index for a given name.
	// Objects returned here must be treated as read-only.
	Get(name string) (*v1.RuntimeClass, error)
	RuntimeClassListerExpansion
}

// runtimeClassLister implements the RuntimeClassLister interface.
type runtimeClassLister struct {
	listers.ResourceIndexer[*v1.RuntimeClass]
}

// NewRuntimeClassLister returns a new RuntimeClassLister.
func NewRuntimeClassLister(indexer cache.Indexer) RuntimeClassLister {
	return &runtimeClassLister{listers.New[*v1.RuntimeClass](indexer, v1.Resource("runtimeclass"))}
}
