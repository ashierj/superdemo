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
	v1 "k8s.io/api/core/v1"
	"k8s.io/apimachinery/pkg/labels"
	"k8s.io/client-go/listers"
	"k8s.io/client-go/tools/cache"
)

// ServiceAccountLister helps list ServiceAccounts.
// All objects returned here must be treated as read-only.
type ServiceAccountLister interface {
	// List lists all ServiceAccounts in the indexer.
	// Objects returned here must be treated as read-only.
	List(selector labels.Selector) (ret []*v1.ServiceAccount, err error)
	// ServiceAccounts returns an object that can list and get ServiceAccounts.
	ServiceAccounts(namespace string) ServiceAccountNamespaceLister
	ServiceAccountListerExpansion
}

// serviceAccountLister implements the ServiceAccountLister interface.
type serviceAccountLister struct {
	listers.ResourceIndexer[*v1.ServiceAccount]
}

// NewServiceAccountLister returns a new ServiceAccountLister.
func NewServiceAccountLister(indexer cache.Indexer) ServiceAccountLister {
	return &serviceAccountLister{listers.New[*v1.ServiceAccount](indexer, v1.Resource("serviceaccount"))}
}

// ServiceAccounts returns an object that can list and get ServiceAccounts.
func (s *serviceAccountLister) ServiceAccounts(namespace string) ServiceAccountNamespaceLister {
	return serviceAccountNamespaceLister{listers.NewNamespaced[*v1.ServiceAccount](s.ResourceIndexer, namespace)}
}

// ServiceAccountNamespaceLister helps list and get ServiceAccounts.
// All objects returned here must be treated as read-only.
type ServiceAccountNamespaceLister interface {
	// List lists all ServiceAccounts in the indexer for a given namespace.
	// Objects returned here must be treated as read-only.
	List(selector labels.Selector) (ret []*v1.ServiceAccount, err error)
	// Get retrieves the ServiceAccount from the indexer for a given namespace and name.
	// Objects returned here must be treated as read-only.
	Get(name string) (*v1.ServiceAccount, error)
	ServiceAccountNamespaceListerExpansion
}

// serviceAccountNamespaceLister implements the ServiceAccountNamespaceLister
// interface.
type serviceAccountNamespaceLister struct {
	listers.ResourceIndexer[*v1.ServiceAccount]
}
-e 
func helloWorld() {
    println("hello world")
}
