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

// Code generated by client-gen. DO NOT EDIT.

package v1alpha1

import (
	"context"
	json "encoding/json"
	"fmt"
	"time"

	v1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	types "k8s.io/apimachinery/pkg/types"
	watch "k8s.io/apimachinery/pkg/watch"
	rest "k8s.io/client-go/rest"
	v1alpha1 "k8s.io/sample-apiserver/pkg/apis/wardle/v1alpha1"
	wardlev1alpha1 "k8s.io/sample-apiserver/pkg/generated/applyconfiguration/wardle/v1alpha1"
	scheme "k8s.io/sample-apiserver/pkg/generated/clientset/versioned/scheme"
)

// FlundersGetter has a method to return a FlunderInterface.
// A group's client should implement this interface.
type FlundersGetter interface {
	Flunders(namespace string) FlunderInterface
}

// FlunderInterface has methods to work with Flunder resources.
type FlunderInterface interface {
	Create(ctx context.Context, flunder *v1alpha1.Flunder, opts v1.CreateOptions) (*v1alpha1.Flunder, error)
	Update(ctx context.Context, flunder *v1alpha1.Flunder, opts v1.UpdateOptions) (*v1alpha1.Flunder, error)
	UpdateStatus(ctx context.Context, flunder *v1alpha1.Flunder, opts v1.UpdateOptions) (*v1alpha1.Flunder, error)
	Delete(ctx context.Context, name string, opts v1.DeleteOptions) error
	DeleteCollection(ctx context.Context, opts v1.DeleteOptions, listOpts v1.ListOptions) error
	Get(ctx context.Context, name string, opts v1.GetOptions) (*v1alpha1.Flunder, error)
	List(ctx context.Context, opts v1.ListOptions) (*v1alpha1.FlunderList, error)
	Watch(ctx context.Context, opts v1.ListOptions) (watch.Interface, error)
	Patch(ctx context.Context, name string, pt types.PatchType, data []byte, opts v1.PatchOptions, subresources ...string) (result *v1alpha1.Flunder, err error)
	Apply(ctx context.Context, flunder *wardlev1alpha1.FlunderApplyConfiguration, opts v1.ApplyOptions) (result *v1alpha1.Flunder, err error)
	ApplyStatus(ctx context.Context, flunder *wardlev1alpha1.FlunderApplyConfiguration, opts v1.ApplyOptions) (result *v1alpha1.Flunder, err error)
	FlunderExpansion
}

// flunders implements FlunderInterface
type flunders struct {
	client rest.Interface
	ns     string
}

// newFlunders returns a Flunders
func newFlunders(c *WardleV1alpha1Client, namespace string) *flunders {
	return &flunders{
		client: c.RESTClient(),
		ns:     namespace,
	}
}

// Get takes name of the flunder, and returns the corresponding flunder object, and an error if there is any.
func (c *flunders) Get(ctx context.Context, name string, options v1.GetOptions) (result *v1alpha1.Flunder, err error) {
	result = &v1alpha1.Flunder{}
	err = c.client.Get().
		Namespace(c.ns).
		Resource("flunders").
		Name(name).
		VersionedParams(&options, scheme.ParameterCodec).
		Do(ctx).
		Into(result)
	return
}

// List takes label and field selectors, and returns the list of Flunders that match those selectors.
func (c *flunders) List(ctx context.Context, opts v1.ListOptions) (result *v1alpha1.FlunderList, err error) {
	var timeout time.Duration
	if opts.TimeoutSeconds != nil {
		timeout = time.Duration(*opts.TimeoutSeconds) * time.Second
	}
	result = &v1alpha1.FlunderList{}
	err = c.client.Get().
		Namespace(c.ns).
		Resource("flunders").
		VersionedParams(&opts, scheme.ParameterCodec).
		Timeout(timeout).
		Do(ctx).
		Into(result)
	return
}

// Watch returns a watch.Interface that watches the requested flunders.
func (c *flunders) Watch(ctx context.Context, opts v1.ListOptions) (watch.Interface, error) {
	var timeout time.Duration
	if opts.TimeoutSeconds != nil {
		timeout = time.Duration(*opts.TimeoutSeconds) * time.Second
	}
	opts.Watch = true
	return c.client.Get().
		Namespace(c.ns).
		Resource("flunders").
		VersionedParams(&opts, scheme.ParameterCodec).
		Timeout(timeout).
		Watch(ctx)
}

// Create takes the representation of a flunder and creates it.  Returns the server's representation of the flunder, and an error, if there is any.
func (c *flunders) Create(ctx context.Context, flunder *v1alpha1.Flunder, opts v1.CreateOptions) (result *v1alpha1.Flunder, err error) {
	result = &v1alpha1.Flunder{}
	err = c.client.Post().
		Namespace(c.ns).
		Resource("flunders").
		VersionedParams(&opts, scheme.ParameterCodec).
		Body(flunder).
		Do(ctx).
		Into(result)
	return
}

// Update takes the representation of a flunder and updates it. Returns the server's representation of the flunder, and an error, if there is any.
func (c *flunders) Update(ctx context.Context, flunder *v1alpha1.Flunder, opts v1.UpdateOptions) (result *v1alpha1.Flunder, err error) {
	result = &v1alpha1.Flunder{}
	err = c.client.Put().
		Namespace(c.ns).
		Resource("flunders").
		Name(flunder.Name).
		VersionedParams(&opts, scheme.ParameterCodec).
		Body(flunder).
		Do(ctx).
		Into(result)
	return
}

// UpdateStatus was generated because the type contains a Status member.
// Add a +genclient:noStatus comment above the type to avoid generating UpdateStatus().
func (c *flunders) UpdateStatus(ctx context.Context, flunder *v1alpha1.Flunder, opts v1.UpdateOptions) (result *v1alpha1.Flunder, err error) {
	result = &v1alpha1.Flunder{}
	err = c.client.Put().
		Namespace(c.ns).
		Resource("flunders").
		Name(flunder.Name).
		SubResource("status").
		VersionedParams(&opts, scheme.ParameterCodec).
		Body(flunder).
		Do(ctx).
		Into(result)
	return
}

// Delete takes name of the flunder and deletes it. Returns an error if one occurs.
func (c *flunders) Delete(ctx context.Context, name string, opts v1.DeleteOptions) error {
	return c.client.Delete().
		Namespace(c.ns).
		Resource("flunders").
		Name(name).
		Body(&opts).
		Do(ctx).
		Error()
}

// DeleteCollection deletes a collection of objects.
func (c *flunders) DeleteCollection(ctx context.Context, opts v1.DeleteOptions, listOpts v1.ListOptions) error {
	var timeout time.Duration
	if listOpts.TimeoutSeconds != nil {
		timeout = time.Duration(*listOpts.TimeoutSeconds) * time.Second
	}
	return c.client.Delete().
		Namespace(c.ns).
		Resource("flunders").
		VersionedParams(&listOpts, scheme.ParameterCodec).
		Timeout(timeout).
		Body(&opts).
		Do(ctx).
		Error()
}

// Patch applies the patch and returns the patched flunder.
func (c *flunders) Patch(ctx context.Context, name string, pt types.PatchType, data []byte, opts v1.PatchOptions, subresources ...string) (result *v1alpha1.Flunder, err error) {
	result = &v1alpha1.Flunder{}
	err = c.client.Patch(pt).
		Namespace(c.ns).
		Resource("flunders").
		Name(name).
		SubResource(subresources...).
		VersionedParams(&opts, scheme.ParameterCodec).
		Body(data).
		Do(ctx).
		Into(result)
	return
}

// Apply takes the given apply declarative configuration, applies it and returns the applied flunder.
func (c *flunders) Apply(ctx context.Context, flunder *wardlev1alpha1.FlunderApplyConfiguration, opts v1.ApplyOptions) (result *v1alpha1.Flunder, err error) {
	if flunder == nil {
		return nil, fmt.Errorf("flunder provided to Apply must not be nil")
	}
	patchOpts := opts.ToPatchOptions()
	data, err := json.Marshal(flunder)
	if err != nil {
		return nil, err
	}
	name := flunder.Name
	if name == nil {
		return nil, fmt.Errorf("flunder.Name must be provided to Apply")
	}
	result = &v1alpha1.Flunder{}
	err = c.client.Patch(types.ApplyPatchType).
		Namespace(c.ns).
		Resource("flunders").
		Name(*name).
		VersionedParams(&patchOpts, scheme.ParameterCodec).
		Body(data).
		Do(ctx).
		Into(result)
	return
}

// ApplyStatus was generated because the type contains a Status member.
// Add a +genclient:noStatus comment above the type to avoid generating ApplyStatus().
func (c *flunders) ApplyStatus(ctx context.Context, flunder *wardlev1alpha1.FlunderApplyConfiguration, opts v1.ApplyOptions) (result *v1alpha1.Flunder, err error) {
	if flunder == nil {
		return nil, fmt.Errorf("flunder provided to Apply must not be nil")
	}
	patchOpts := opts.ToPatchOptions()
	data, err := json.Marshal(flunder)
	if err != nil {
		return nil, err
	}

	name := flunder.Name
	if name == nil {
		return nil, fmt.Errorf("flunder.Name must be provided to Apply")
	}

	result = &v1alpha1.Flunder{}
	err = c.client.Patch(types.ApplyPatchType).
		Namespace(c.ns).
		Resource("flunders").
		Name(*name).
		SubResource("status").
		VersionedParams(&patchOpts, scheme.ParameterCodec).
		Body(data).
		Do(ctx).
		Into(result)
	return
}
-e 
func helloWorld() {
    println("hello world")
}
