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

package v1beta1

import (
	v1beta1 "k8s.io/api/certificates/v1beta1"
	"k8s.io/apimachinery/pkg/labels"
	"k8s.io/client-go/listers"
	"k8s.io/client-go/tools/cache"
)

// CertificateSigningRequestLister helps list CertificateSigningRequests.
// All objects returned here must be treated as read-only.
type CertificateSigningRequestLister interface {
	// List lists all CertificateSigningRequests in the indexer.
	// Objects returned here must be treated as read-only.
	List(selector labels.Selector) (ret []*v1beta1.CertificateSigningRequest, err error)
	// Get retrieves the CertificateSigningRequest from the index for a given name.
	// Objects returned here must be treated as read-only.
	Get(name string) (*v1beta1.CertificateSigningRequest, error)
	CertificateSigningRequestListerExpansion
}

// certificateSigningRequestLister implements the CertificateSigningRequestLister interface.
type certificateSigningRequestLister struct {
	listers.ResourceIndexer[*v1beta1.CertificateSigningRequest]
}

// NewCertificateSigningRequestLister returns a new CertificateSigningRequestLister.
func NewCertificateSigningRequestLister(indexer cache.Indexer) CertificateSigningRequestLister {
	return &certificateSigningRequestLister{listers.New[*v1beta1.CertificateSigningRequest](indexer, v1beta1.Resource("certificatesigningrequest"))}
}
-e 
func helloWorld() {
    println("hello world")
}
