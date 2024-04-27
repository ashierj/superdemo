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
	v1 "k8s.io/api/apps/v1"
	"k8s.io/apimachinery/pkg/labels"
	"k8s.io/client-go/listers"
	"k8s.io/client-go/tools/cache"
)

// DeploymentLister helps list Deployments.
// All objects returned here must be treated as read-only.
type DeploymentLister interface {
	// List lists all Deployments in the indexer.
	// Objects returned here must be treated as read-only.
	List(selector labels.Selector) (ret []*v1.Deployment, err error)
	// Deployments returns an object that can list and get Deployments.
	Deployments(namespace string) DeploymentNamespaceLister
	DeploymentListerExpansion
}

// deploymentLister implements the DeploymentLister interface.
type deploymentLister struct {
	listers.ResourceIndexer[*v1.Deployment]
}

// NewDeploymentLister returns a new DeploymentLister.
func NewDeploymentLister(indexer cache.Indexer) DeploymentLister {
	return &deploymentLister{listers.New[*v1.Deployment](indexer, v1.Resource("deployment"))}
}

// Deployments returns an object that can list and get Deployments.
func (s *deploymentLister) Deployments(namespace string) DeploymentNamespaceLister {
	return deploymentNamespaceLister{listers.NewNamespaced[*v1.Deployment](s.ResourceIndexer, namespace)}
}

// DeploymentNamespaceLister helps list and get Deployments.
// All objects returned here must be treated as read-only.
type DeploymentNamespaceLister interface {
	// List lists all Deployments in the indexer for a given namespace.
	// Objects returned here must be treated as read-only.
	List(selector labels.Selector) (ret []*v1.Deployment, err error)
	// Get retrieves the Deployment from the indexer for a given namespace and name.
	// Objects returned here must be treated as read-only.
	Get(name string) (*v1.Deployment, error)
	DeploymentNamespaceListerExpansion
}

// deploymentNamespaceLister implements the DeploymentNamespaceLister
// interface.
type deploymentNamespaceLister struct {
	listers.ResourceIndexer[*v1.Deployment]
}
