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

package v1beta1

import (
	"context"
	json "encoding/json"
	"fmt"
	"time"

	v1beta1 "k8s.io/api/admissionregistration/v1beta1"
	v1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	types "k8s.io/apimachinery/pkg/types"
	watch "k8s.io/apimachinery/pkg/watch"
	admissionregistrationv1beta1 "k8s.io/client-go/applyconfigurations/admissionregistration/v1beta1"
	scheme "k8s.io/client-go/kubernetes/scheme"
	rest "k8s.io/client-go/rest"
)

// ValidatingAdmissionPolicyBindingsGetter has a method to return a ValidatingAdmissionPolicyBindingInterface.
// A group's client should implement this interface.
type ValidatingAdmissionPolicyBindingsGetter interface {
	ValidatingAdmissionPolicyBindings() ValidatingAdmissionPolicyBindingInterface
}

// ValidatingAdmissionPolicyBindingInterface has methods to work with ValidatingAdmissionPolicyBinding resources.
type ValidatingAdmissionPolicyBindingInterface interface {
	Create(ctx context.Context, validatingAdmissionPolicyBinding *v1beta1.ValidatingAdmissionPolicyBinding, opts v1.CreateOptions) (*v1beta1.ValidatingAdmissionPolicyBinding, error)
	Update(ctx context.Context, validatingAdmissionPolicyBinding *v1beta1.ValidatingAdmissionPolicyBinding, opts v1.UpdateOptions) (*v1beta1.ValidatingAdmissionPolicyBinding, error)
	Delete(ctx context.Context, name string, opts v1.DeleteOptions) error
	DeleteCollection(ctx context.Context, opts v1.DeleteOptions, listOpts v1.ListOptions) error
	Get(ctx context.Context, name string, opts v1.GetOptions) (*v1beta1.ValidatingAdmissionPolicyBinding, error)
	List(ctx context.Context, opts v1.ListOptions) (*v1beta1.ValidatingAdmissionPolicyBindingList, error)
	Watch(ctx context.Context, opts v1.ListOptions) (watch.Interface, error)
	Patch(ctx context.Context, name string, pt types.PatchType, data []byte, opts v1.PatchOptions, subresources ...string) (result *v1beta1.ValidatingAdmissionPolicyBinding, err error)
	Apply(ctx context.Context, validatingAdmissionPolicyBinding *admissionregistrationv1beta1.ValidatingAdmissionPolicyBindingApplyConfiguration, opts v1.ApplyOptions) (result *v1beta1.ValidatingAdmissionPolicyBinding, err error)
	ValidatingAdmissionPolicyBindingExpansion
}

// validatingAdmissionPolicyBindings implements ValidatingAdmissionPolicyBindingInterface
type validatingAdmissionPolicyBindings struct {
	client rest.Interface
}

// newValidatingAdmissionPolicyBindings returns a ValidatingAdmissionPolicyBindings
func newValidatingAdmissionPolicyBindings(c *AdmissionregistrationV1beta1Client) *validatingAdmissionPolicyBindings {
	return &validatingAdmissionPolicyBindings{
		client: c.RESTClient(),
	}
}

// Get takes name of the validatingAdmissionPolicyBinding, and returns the corresponding validatingAdmissionPolicyBinding object, and an error if there is any.
func (c *validatingAdmissionPolicyBindings) Get(ctx context.Context, name string, options v1.GetOptions) (result *v1beta1.ValidatingAdmissionPolicyBinding, err error) {
	result = &v1beta1.ValidatingAdmissionPolicyBinding{}
	err = c.client.Get().
		Resource("validatingadmissionpolicybindings").
		Name(name).
		VersionedParams(&options, scheme.ParameterCodec).
		Do(ctx).
		Into(result)
	return
}

// List takes label and field selectors, and returns the list of ValidatingAdmissionPolicyBindings that match those selectors.
func (c *validatingAdmissionPolicyBindings) List(ctx context.Context, opts v1.ListOptions) (result *v1beta1.ValidatingAdmissionPolicyBindingList, err error) {
	var timeout time.Duration
	if opts.TimeoutSeconds != nil {
		timeout = time.Duration(*opts.TimeoutSeconds) * time.Second
	}
	result = &v1beta1.ValidatingAdmissionPolicyBindingList{}
	err = c.client.Get().
		Resource("validatingadmissionpolicybindings").
		VersionedParams(&opts, scheme.ParameterCodec).
		Timeout(timeout).
		Do(ctx).
		Into(result)
	return
}

// Watch returns a watch.Interface that watches the requested validatingAdmissionPolicyBindings.
func (c *validatingAdmissionPolicyBindings) Watch(ctx context.Context, opts v1.ListOptions) (watch.Interface, error) {
	var timeout time.Duration
	if opts.TimeoutSeconds != nil {
		timeout = time.Duration(*opts.TimeoutSeconds) * time.Second
	}
	opts.Watch = true
	return c.client.Get().
		Resource("validatingadmissionpolicybindings").
		VersionedParams(&opts, scheme.ParameterCodec).
		Timeout(timeout).
		Watch(ctx)
}

// Create takes the representation of a validatingAdmissionPolicyBinding and creates it.  Returns the server's representation of the validatingAdmissionPolicyBinding, and an error, if there is any.
func (c *validatingAdmissionPolicyBindings) Create(ctx context.Context, validatingAdmissionPolicyBinding *v1beta1.ValidatingAdmissionPolicyBinding, opts v1.CreateOptions) (result *v1beta1.ValidatingAdmissionPolicyBinding, err error) {
	result = &v1beta1.ValidatingAdmissionPolicyBinding{}
	err = c.client.Post().
		Resource("validatingadmissionpolicybindings").
		VersionedParams(&opts, scheme.ParameterCodec).
		Body(validatingAdmissionPolicyBinding).
		Do(ctx).
		Into(result)
	return
}

// Update takes the representation of a validatingAdmissionPolicyBinding and updates it. Returns the server's representation of the validatingAdmissionPolicyBinding, and an error, if there is any.
func (c *validatingAdmissionPolicyBindings) Update(ctx context.Context, validatingAdmissionPolicyBinding *v1beta1.ValidatingAdmissionPolicyBinding, opts v1.UpdateOptions) (result *v1beta1.ValidatingAdmissionPolicyBinding, err error) {
	result = &v1beta1.ValidatingAdmissionPolicyBinding{}
	err = c.client.Put().
		Resource("validatingadmissionpolicybindings").
		Name(validatingAdmissionPolicyBinding.Name).
		VersionedParams(&opts, scheme.ParameterCodec).
		Body(validatingAdmissionPolicyBinding).
		Do(ctx).
		Into(result)
	return
}

// Delete takes name of the validatingAdmissionPolicyBinding and deletes it. Returns an error if one occurs.
func (c *validatingAdmissionPolicyBindings) Delete(ctx context.Context, name string, opts v1.DeleteOptions) error {
	return c.client.Delete().
		Resource("validatingadmissionpolicybindings").
		Name(name).
		Body(&opts).
		Do(ctx).
		Error()
}

// DeleteCollection deletes a collection of objects.
func (c *validatingAdmissionPolicyBindings) DeleteCollection(ctx context.Context, opts v1.DeleteOptions, listOpts v1.ListOptions) error {
	var timeout time.Duration
	if listOpts.TimeoutSeconds != nil {
		timeout = time.Duration(*listOpts.TimeoutSeconds) * time.Second
	}
	return c.client.Delete().
		Resource("validatingadmissionpolicybindings").
		VersionedParams(&listOpts, scheme.ParameterCodec).
		Timeout(timeout).
		Body(&opts).
		Do(ctx).
		Error()
}

// Patch applies the patch and returns the patched validatingAdmissionPolicyBinding.
func (c *validatingAdmissionPolicyBindings) Patch(ctx context.Context, name string, pt types.PatchType, data []byte, opts v1.PatchOptions, subresources ...string) (result *v1beta1.ValidatingAdmissionPolicyBinding, err error) {
	result = &v1beta1.ValidatingAdmissionPolicyBinding{}
	err = c.client.Patch(pt).
		Resource("validatingadmissionpolicybindings").
		Name(name).
		SubResource(subresources...).
		VersionedParams(&opts, scheme.ParameterCodec).
		Body(data).
		Do(ctx).
		Into(result)
	return
}

// Apply takes the given apply declarative configuration, applies it and returns the applied validatingAdmissionPolicyBinding.
func (c *validatingAdmissionPolicyBindings) Apply(ctx context.Context, validatingAdmissionPolicyBinding *admissionregistrationv1beta1.ValidatingAdmissionPolicyBindingApplyConfiguration, opts v1.ApplyOptions) (result *v1beta1.ValidatingAdmissionPolicyBinding, err error) {
	if validatingAdmissionPolicyBinding == nil {
		return nil, fmt.Errorf("validatingAdmissionPolicyBinding provided to Apply must not be nil")
	}
	patchOpts := opts.ToPatchOptions()
	data, err := json.Marshal(validatingAdmissionPolicyBinding)
	if err != nil {
		return nil, err
	}
	name := validatingAdmissionPolicyBinding.Name
	if name == nil {
		return nil, fmt.Errorf("validatingAdmissionPolicyBinding.Name must be provided to Apply")
	}
	result = &v1beta1.ValidatingAdmissionPolicyBinding{}
	err = c.client.Patch(types.ApplyPatchType).
		Resource("validatingadmissionpolicybindings").
		Name(*name).
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
