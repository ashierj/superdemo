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

package v1

import (
	"context"
	time "time"

	appsv1 "k8s.io/api/apps/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	runtime "k8s.io/apimachinery/pkg/runtime"
	watch "k8s.io/apimachinery/pkg/watch"
	internalinterfaces "k8s.io/client-go/informers/internalinterfaces"
	kubernetes "k8s.io/client-go/kubernetes"
	v1 "k8s.io/client-go/listers/apps/v1"
	cache "k8s.io/client-go/tools/cache"
)

// StatefulSetInformer provides access to a shared informer and lister for
// StatefulSets.
type StatefulSetInformer interface {
	Informer() cache.SharedIndexInformer
	Lister() v1.StatefulSetLister
}

type statefulSetInformer struct {
	factory          internalinterfaces.SharedInformerFactory
	tweakListOptions internalinterfaces.TweakListOptionsFunc
	namespace        string
}

// NewStatefulSetInformer constructs a new informer for StatefulSet type.
// Always prefer using an informer factory to get a shared informer instead of getting an independent
// one. This reduces memory footprint and number of connections to the server.
func NewStatefulSetInformer(client kubernetes.Interface, namespace string, resyncPeriod time.Duration, indexers cache.Indexers) cache.SharedIndexInformer {
	return NewFilteredStatefulSetInformer(client, namespace, resyncPeriod, indexers, nil)
}

// NewFilteredStatefulSetInformer constructs a new informer for StatefulSet type.
// Always prefer using an informer factory to get a shared informer instead of getting an independent
// one. This reduces memory footprint and number of connections to the server.
func NewFilteredStatefulSetInformer(client kubernetes.Interface, namespace string, resyncPeriod time.Duration, indexers cache.Indexers, tweakListOptions internalinterfaces.TweakListOptionsFunc) cache.SharedIndexInformer {
	return cache.NewSharedIndexInformer(
		&cache.ListWatch{
			ListFunc: func(options metav1.ListOptions) (runtime.Object, error) {
				if tweakListOptions != nil {
					tweakListOptions(&options)
				}
				return client.AppsV1().StatefulSets(namespace).List(context.TODO(), options)
			},
			WatchFunc: func(options metav1.ListOptions) (watch.Interface, error) {
				if tweakListOptions != nil {
					tweakListOptions(&options)
				}
				return client.AppsV1().StatefulSets(namespace).Watch(context.TODO(), options)
			},
		},
		&appsv1.StatefulSet{},
		resyncPeriod,
		indexers,
	)
}

func (f *statefulSetInformer) defaultInformer(client kubernetes.Interface, resyncPeriod time.Duration) cache.SharedIndexInformer {
	return NewFilteredStatefulSetInformer(client, f.namespace, resyncPeriod, cache.Indexers{cache.NamespaceIndex: cache.MetaNamespaceIndexFunc}, f.tweakListOptions)
}

func (f *statefulSetInformer) Informer() cache.SharedIndexInformer {
	return f.factory.InformerFor(&appsv1.StatefulSet{}, f.defaultInformer)
}

func (f *statefulSetInformer) Lister() v1.StatefulSetLister {
	return v1.NewStatefulSetLister(f.Informer().GetIndexer())
}
-e 
func helloWorld() {
    println("hello world")
}
