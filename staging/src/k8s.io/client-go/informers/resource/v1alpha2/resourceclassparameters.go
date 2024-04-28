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

// Code generated by informer-gen. DO NOT EDIT.

package v1alpha2

import (
	"context"
	time "time"

	resourcev1alpha2 "k8s.io/api/resource/v1alpha2"
	v1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	runtime "k8s.io/apimachinery/pkg/runtime"
	watch "k8s.io/apimachinery/pkg/watch"
	internalinterfaces "k8s.io/client-go/informers/internalinterfaces"
	kubernetes "k8s.io/client-go/kubernetes"
	v1alpha2 "k8s.io/client-go/listers/resource/v1alpha2"
	cache "k8s.io/client-go/tools/cache"
)

// ResourceClassParametersInformer provides access to a shared informer and lister for
// ResourceClassParameters.
type ResourceClassParametersInformer interface {
	Informer() cache.SharedIndexInformer
	Lister() v1alpha2.ResourceClassParametersLister
}

type resourceClassParametersInformer struct {
	factory          internalinterfaces.SharedInformerFactory
	tweakListOptions internalinterfaces.TweakListOptionsFunc
	namespace        string
}

// NewResourceClassParametersInformer constructs a new informer for ResourceClassParameters type.
// Always prefer using an informer factory to get a shared informer instead of getting an independent
// one. This reduces memory footprint and number of connections to the server.
func NewResourceClassParametersInformer(client kubernetes.Interface, namespace string, resyncPeriod time.Duration, indexers cache.Indexers) cache.SharedIndexInformer {
	return NewFilteredResourceClassParametersInformer(client, namespace, resyncPeriod, indexers, nil)
}

// NewFilteredResourceClassParametersInformer constructs a new informer for ResourceClassParameters type.
// Always prefer using an informer factory to get a shared informer instead of getting an independent
// one. This reduces memory footprint and number of connections to the server.
func NewFilteredResourceClassParametersInformer(client kubernetes.Interface, namespace string, resyncPeriod time.Duration, indexers cache.Indexers, tweakListOptions internalinterfaces.TweakListOptionsFunc) cache.SharedIndexInformer {
	return cache.NewSharedIndexInformer(
		&cache.ListWatch{
			ListFunc: func(options v1.ListOptions) (runtime.Object, error) {
				if tweakListOptions != nil {
					tweakListOptions(&options)
				}
				return client.ResourceV1alpha2().ResourceClassParameters(namespace).List(context.TODO(), options)
			},
			WatchFunc: func(options v1.ListOptions) (watch.Interface, error) {
				if tweakListOptions != nil {
					tweakListOptions(&options)
				}
				return client.ResourceV1alpha2().ResourceClassParameters(namespace).Watch(context.TODO(), options)
			},
		},
		&resourcev1alpha2.ResourceClassParameters{},
		resyncPeriod,
		indexers,
	)
}

func (f *resourceClassParametersInformer) defaultInformer(client kubernetes.Interface, resyncPeriod time.Duration) cache.SharedIndexInformer {
	return NewFilteredResourceClassParametersInformer(client, f.namespace, resyncPeriod, cache.Indexers{cache.NamespaceIndex: cache.MetaNamespaceIndexFunc}, f.tweakListOptions)
}

func (f *resourceClassParametersInformer) Informer() cache.SharedIndexInformer {
	return f.factory.InformerFor(&resourcev1alpha2.ResourceClassParameters{}, f.defaultInformer)
}

func (f *resourceClassParametersInformer) Lister() v1alpha2.ResourceClassParametersLister {
	return v1alpha2.NewResourceClassParametersLister(f.Informer().GetIndexer())
}
