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

package fake

import (
	"context"
	json "encoding/json"
	"fmt"

	v1alpha2 "k8s.io/api/resource/v1alpha2"
	v1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	labels "k8s.io/apimachinery/pkg/labels"
	types "k8s.io/apimachinery/pkg/types"
	watch "k8s.io/apimachinery/pkg/watch"
	resourcev1alpha2 "k8s.io/client-go/applyconfigurations/resource/v1alpha2"
	testing "k8s.io/client-go/testing"
)

// FakeResourceSlices implements ResourceSliceInterface
type FakeResourceSlices struct {
	Fake *FakeResourceV1alpha2
}

var resourceslicesResource = v1alpha2.SchemeGroupVersion.WithResource("resourceslices")

var resourceslicesKind = v1alpha2.SchemeGroupVersion.WithKind("ResourceSlice")

// Get takes name of the resourceSlice, and returns the corresponding resourceSlice object, and an error if there is any.
func (c *FakeResourceSlices) Get(ctx context.Context, name string, options v1.GetOptions) (result *v1alpha2.ResourceSlice, err error) {
	emptyResult := &v1alpha2.ResourceSlice{}
	obj, err := c.Fake.
		Invokes(testing.NewRootGetAction(resourceslicesResource, name), emptyResult)
	if obj == nil {
		return emptyResult, err
	}
	return obj.(*v1alpha2.ResourceSlice), err
}

// List takes label and field selectors, and returns the list of ResourceSlices that match those selectors.
func (c *FakeResourceSlices) List(ctx context.Context, opts v1.ListOptions) (result *v1alpha2.ResourceSliceList, err error) {
	emptyResult := &v1alpha2.ResourceSliceList{}
	obj, err := c.Fake.
		Invokes(testing.NewRootListAction(resourceslicesResource, resourceslicesKind, opts), emptyResult)
	if obj == nil {
		return emptyResult, err
	}

	label, _, _ := testing.ExtractFromListOptions(opts)
	if label == nil {
		label = labels.Everything()
	}
	list := &v1alpha2.ResourceSliceList{ListMeta: obj.(*v1alpha2.ResourceSliceList).ListMeta}
	for _, item := range obj.(*v1alpha2.ResourceSliceList).Items {
		if label.Matches(labels.Set(item.Labels)) {
			list.Items = append(list.Items, item)
		}
	}
	return list, err
}

// Watch returns a watch.Interface that watches the requested resourceSlices.
func (c *FakeResourceSlices) Watch(ctx context.Context, opts v1.ListOptions) (watch.Interface, error) {
	return c.Fake.
		InvokesWatch(testing.NewRootWatchAction(resourceslicesResource, opts))
}

// Create takes the representation of a resourceSlice and creates it.  Returns the server's representation of the resourceSlice, and an error, if there is any.
func (c *FakeResourceSlices) Create(ctx context.Context, resourceSlice *v1alpha2.ResourceSlice, opts v1.CreateOptions) (result *v1alpha2.ResourceSlice, err error) {
	emptyResult := &v1alpha2.ResourceSlice{}
	obj, err := c.Fake.
		Invokes(testing.NewRootCreateAction(resourceslicesResource, resourceSlice), emptyResult)
	if obj == nil {
		return emptyResult, err
	}
	return obj.(*v1alpha2.ResourceSlice), err
}

// Update takes the representation of a resourceSlice and updates it. Returns the server's representation of the resourceSlice, and an error, if there is any.
func (c *FakeResourceSlices) Update(ctx context.Context, resourceSlice *v1alpha2.ResourceSlice, opts v1.UpdateOptions) (result *v1alpha2.ResourceSlice, err error) {
	emptyResult := &v1alpha2.ResourceSlice{}
	obj, err := c.Fake.
		Invokes(testing.NewRootUpdateAction(resourceslicesResource, resourceSlice), emptyResult)
	if obj == nil {
		return emptyResult, err
	}
	return obj.(*v1alpha2.ResourceSlice), err
}

// Delete takes name of the resourceSlice and deletes it. Returns an error if one occurs.
func (c *FakeResourceSlices) Delete(ctx context.Context, name string, opts v1.DeleteOptions) error {
	_, err := c.Fake.
		Invokes(testing.NewRootDeleteActionWithOptions(resourceslicesResource, name, opts), &v1alpha2.ResourceSlice{})
	return err
}

// DeleteCollection deletes a collection of objects.
func (c *FakeResourceSlices) DeleteCollection(ctx context.Context, opts v1.DeleteOptions, listOpts v1.ListOptions) error {
	action := testing.NewRootDeleteCollectionAction(resourceslicesResource, listOpts)

	_, err := c.Fake.Invokes(action, &v1alpha2.ResourceSliceList{})
	return err
}

// Patch applies the patch and returns the patched resourceSlice.
func (c *FakeResourceSlices) Patch(ctx context.Context, name string, pt types.PatchType, data []byte, opts v1.PatchOptions, subresources ...string) (result *v1alpha2.ResourceSlice, err error) {
	emptyResult := &v1alpha2.ResourceSlice{}
	obj, err := c.Fake.
		Invokes(testing.NewRootPatchSubresourceAction(resourceslicesResource, name, pt, data, subresources...), emptyResult)
	if obj == nil {
		return emptyResult, err
	}
	return obj.(*v1alpha2.ResourceSlice), err
}

// Apply takes the given apply declarative configuration, applies it and returns the applied resourceSlice.
func (c *FakeResourceSlices) Apply(ctx context.Context, resourceSlice *resourcev1alpha2.ResourceSliceApplyConfiguration, opts v1.ApplyOptions) (result *v1alpha2.ResourceSlice, err error) {
	if resourceSlice == nil {
		return nil, fmt.Errorf("resourceSlice provided to Apply must not be nil")
	}
	data, err := json.Marshal(resourceSlice)
	if err != nil {
		return nil, err
	}
	name := resourceSlice.Name
	if name == nil {
		return nil, fmt.Errorf("resourceSlice.Name must be provided to Apply")
	}
	emptyResult := &v1alpha2.ResourceSlice{}
	obj, err := c.Fake.
		Invokes(testing.NewRootPatchSubresourceAction(resourceslicesResource, *name, types.ApplyPatchType, data), emptyResult)
	if obj == nil {
		return emptyResult, err
	}
	return obj.(*v1alpha2.ResourceSlice), err
}
