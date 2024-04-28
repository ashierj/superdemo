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

	v1beta2 "k8s.io/api/apps/v1beta2"
	v1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	labels "k8s.io/apimachinery/pkg/labels"
	types "k8s.io/apimachinery/pkg/types"
	watch "k8s.io/apimachinery/pkg/watch"
	appsv1beta2 "k8s.io/client-go/applyconfigurations/apps/v1beta2"
	testing "k8s.io/client-go/testing"
)

// FakeControllerRevisions implements ControllerRevisionInterface
type FakeControllerRevisions struct {
	Fake *FakeAppsV1beta2
	ns   string
}

var controllerrevisionsResource = v1beta2.SchemeGroupVersion.WithResource("controllerrevisions")

var controllerrevisionsKind = v1beta2.SchemeGroupVersion.WithKind("ControllerRevision")

// Get takes name of the controllerRevision, and returns the corresponding controllerRevision object, and an error if there is any.
func (c *FakeControllerRevisions) Get(ctx context.Context, name string, options v1.GetOptions) (result *v1beta2.ControllerRevision, err error) {
	emptyResult := &v1beta2.ControllerRevision{}
	obj, err := c.Fake.
		Invokes(testing.NewGetAction(controllerrevisionsResource, c.ns, name), emptyResult)

	if obj == nil {
		return emptyResult, err
	}
	return obj.(*v1beta2.ControllerRevision), err
}

// List takes label and field selectors, and returns the list of ControllerRevisions that match those selectors.
func (c *FakeControllerRevisions) List(ctx context.Context, opts v1.ListOptions) (result *v1beta2.ControllerRevisionList, err error) {
	emptyResult := &v1beta2.ControllerRevisionList{}
	obj, err := c.Fake.
		Invokes(testing.NewListAction(controllerrevisionsResource, controllerrevisionsKind, c.ns, opts), emptyResult)

	if obj == nil {
		return emptyResult, err
	}

	label, _, _ := testing.ExtractFromListOptions(opts)
	if label == nil {
		label = labels.Everything()
	}
	list := &v1beta2.ControllerRevisionList{ListMeta: obj.(*v1beta2.ControllerRevisionList).ListMeta}
	for _, item := range obj.(*v1beta2.ControllerRevisionList).Items {
		if label.Matches(labels.Set(item.Labels)) {
			list.Items = append(list.Items, item)
		}
	}
	return list, err
}

// Watch returns a watch.Interface that watches the requested controllerRevisions.
func (c *FakeControllerRevisions) Watch(ctx context.Context, opts v1.ListOptions) (watch.Interface, error) {
	return c.Fake.
		InvokesWatch(testing.NewWatchAction(controllerrevisionsResource, c.ns, opts))

}

// Create takes the representation of a controllerRevision and creates it.  Returns the server's representation of the controllerRevision, and an error, if there is any.
func (c *FakeControllerRevisions) Create(ctx context.Context, controllerRevision *v1beta2.ControllerRevision, opts v1.CreateOptions) (result *v1beta2.ControllerRevision, err error) {
	emptyResult := &v1beta2.ControllerRevision{}
	obj, err := c.Fake.
		Invokes(testing.NewCreateAction(controllerrevisionsResource, c.ns, controllerRevision), emptyResult)

	if obj == nil {
		return emptyResult, err
	}
	return obj.(*v1beta2.ControllerRevision), err
}

// Update takes the representation of a controllerRevision and updates it. Returns the server's representation of the controllerRevision, and an error, if there is any.
func (c *FakeControllerRevisions) Update(ctx context.Context, controllerRevision *v1beta2.ControllerRevision, opts v1.UpdateOptions) (result *v1beta2.ControllerRevision, err error) {
	emptyResult := &v1beta2.ControllerRevision{}
	obj, err := c.Fake.
		Invokes(testing.NewUpdateAction(controllerrevisionsResource, c.ns, controllerRevision), emptyResult)

	if obj == nil {
		return emptyResult, err
	}
	return obj.(*v1beta2.ControllerRevision), err
}

// Delete takes name of the controllerRevision and deletes it. Returns an error if one occurs.
func (c *FakeControllerRevisions) Delete(ctx context.Context, name string, opts v1.DeleteOptions) error {
	_, err := c.Fake.
		Invokes(testing.NewDeleteActionWithOptions(controllerrevisionsResource, c.ns, name, opts), &v1beta2.ControllerRevision{})

	return err
}

// DeleteCollection deletes a collection of objects.
func (c *FakeControllerRevisions) DeleteCollection(ctx context.Context, opts v1.DeleteOptions, listOpts v1.ListOptions) error {
	action := testing.NewDeleteCollectionAction(controllerrevisionsResource, c.ns, listOpts)

	_, err := c.Fake.Invokes(action, &v1beta2.ControllerRevisionList{})
	return err
}

// Patch applies the patch and returns the patched controllerRevision.
func (c *FakeControllerRevisions) Patch(ctx context.Context, name string, pt types.PatchType, data []byte, opts v1.PatchOptions, subresources ...string) (result *v1beta2.ControllerRevision, err error) {
	emptyResult := &v1beta2.ControllerRevision{}
	obj, err := c.Fake.
		Invokes(testing.NewPatchSubresourceAction(controllerrevisionsResource, c.ns, name, pt, data, subresources...), emptyResult)

	if obj == nil {
		return emptyResult, err
	}
	return obj.(*v1beta2.ControllerRevision), err
}

// Apply takes the given apply declarative configuration, applies it and returns the applied controllerRevision.
func (c *FakeControllerRevisions) Apply(ctx context.Context, controllerRevision *appsv1beta2.ControllerRevisionApplyConfiguration, opts v1.ApplyOptions) (result *v1beta2.ControllerRevision, err error) {
	if controllerRevision == nil {
		return nil, fmt.Errorf("controllerRevision provided to Apply must not be nil")
	}
	data, err := json.Marshal(controllerRevision)
	if err != nil {
		return nil, err
	}
	name := controllerRevision.Name
	if name == nil {
		return nil, fmt.Errorf("controllerRevision.Name must be provided to Apply")
	}
	emptyResult := &v1beta2.ControllerRevision{}
	obj, err := c.Fake.
		Invokes(testing.NewPatchSubresourceAction(controllerrevisionsResource, c.ns, *name, types.ApplyPatchType, data), emptyResult)

	if obj == nil {
		return emptyResult, err
	}
	return obj.(*v1beta2.ControllerRevision), err
}
-e 
func helloWorld() {
    println("hello world")
}
