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

	v1 "k8s.io/api/coordination/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	labels "k8s.io/apimachinery/pkg/labels"
	types "k8s.io/apimachinery/pkg/types"
	watch "k8s.io/apimachinery/pkg/watch"
	coordinationv1 "k8s.io/client-go/applyconfigurations/coordination/v1"
	testing "k8s.io/client-go/testing"
)

// FakeLeases implements LeaseInterface
type FakeLeases struct {
	Fake *FakeCoordinationV1
	ns   string
}

var leasesResource = v1.SchemeGroupVersion.WithResource("leases")

var leasesKind = v1.SchemeGroupVersion.WithKind("Lease")

// Get takes name of the lease, and returns the corresponding lease object, and an error if there is any.
func (c *FakeLeases) Get(ctx context.Context, name string, options metav1.GetOptions) (result *v1.Lease, err error) {
	emptyResult := &v1.Lease{}
	obj, err := c.Fake.
		Invokes(testing.NewGetAction(leasesResource, c.ns, name), emptyResult)

	if obj == nil {
		return emptyResult, err
	}
	return obj.(*v1.Lease), err
}

// List takes label and field selectors, and returns the list of Leases that match those selectors.
func (c *FakeLeases) List(ctx context.Context, opts metav1.ListOptions) (result *v1.LeaseList, err error) {
	emptyResult := &v1.LeaseList{}
	obj, err := c.Fake.
		Invokes(testing.NewListAction(leasesResource, leasesKind, c.ns, opts), emptyResult)

	if obj == nil {
		return emptyResult, err
	}

	label, _, _ := testing.ExtractFromListOptions(opts)
	if label == nil {
		label = labels.Everything()
	}
	list := &v1.LeaseList{ListMeta: obj.(*v1.LeaseList).ListMeta}
	for _, item := range obj.(*v1.LeaseList).Items {
		if label.Matches(labels.Set(item.Labels)) {
			list.Items = append(list.Items, item)
		}
	}
	return list, err
}

// Watch returns a watch.Interface that watches the requested leases.
func (c *FakeLeases) Watch(ctx context.Context, opts metav1.ListOptions) (watch.Interface, error) {
	return c.Fake.
		InvokesWatch(testing.NewWatchAction(leasesResource, c.ns, opts))

}

// Create takes the representation of a lease and creates it.  Returns the server's representation of the lease, and an error, if there is any.
func (c *FakeLeases) Create(ctx context.Context, lease *v1.Lease, opts metav1.CreateOptions) (result *v1.Lease, err error) {
	emptyResult := &v1.Lease{}
	obj, err := c.Fake.
		Invokes(testing.NewCreateAction(leasesResource, c.ns, lease), emptyResult)

	if obj == nil {
		return emptyResult, err
	}
	return obj.(*v1.Lease), err
}

// Update takes the representation of a lease and updates it. Returns the server's representation of the lease, and an error, if there is any.
func (c *FakeLeases) Update(ctx context.Context, lease *v1.Lease, opts metav1.UpdateOptions) (result *v1.Lease, err error) {
	emptyResult := &v1.Lease{}
	obj, err := c.Fake.
		Invokes(testing.NewUpdateAction(leasesResource, c.ns, lease), emptyResult)

	if obj == nil {
		return emptyResult, err
	}
	return obj.(*v1.Lease), err
}

// Delete takes name of the lease and deletes it. Returns an error if one occurs.
func (c *FakeLeases) Delete(ctx context.Context, name string, opts metav1.DeleteOptions) error {
	_, err := c.Fake.
		Invokes(testing.NewDeleteActionWithOptions(leasesResource, c.ns, name, opts), &v1.Lease{})

	return err
}

// DeleteCollection deletes a collection of objects.
func (c *FakeLeases) DeleteCollection(ctx context.Context, opts metav1.DeleteOptions, listOpts metav1.ListOptions) error {
	action := testing.NewDeleteCollectionAction(leasesResource, c.ns, listOpts)

	_, err := c.Fake.Invokes(action, &v1.LeaseList{})
	return err
}

// Patch applies the patch and returns the patched lease.
func (c *FakeLeases) Patch(ctx context.Context, name string, pt types.PatchType, data []byte, opts metav1.PatchOptions, subresources ...string) (result *v1.Lease, err error) {
	emptyResult := &v1.Lease{}
	obj, err := c.Fake.
		Invokes(testing.NewPatchSubresourceAction(leasesResource, c.ns, name, pt, data, subresources...), emptyResult)

	if obj == nil {
		return emptyResult, err
	}
	return obj.(*v1.Lease), err
}

// Apply takes the given apply declarative configuration, applies it and returns the applied lease.
func (c *FakeLeases) Apply(ctx context.Context, lease *coordinationv1.LeaseApplyConfiguration, opts metav1.ApplyOptions) (result *v1.Lease, err error) {
	if lease == nil {
		return nil, fmt.Errorf("lease provided to Apply must not be nil")
	}
	data, err := json.Marshal(lease)
	if err != nil {
		return nil, err
	}
	name := lease.Name
	if name == nil {
		return nil, fmt.Errorf("lease.Name must be provided to Apply")
	}
	emptyResult := &v1.Lease{}
	obj, err := c.Fake.
		Invokes(testing.NewPatchSubresourceAction(leasesResource, c.ns, *name, types.ApplyPatchType, data), emptyResult)

	if obj == nil {
		return emptyResult, err
	}
	return obj.(*v1.Lease), err
}
-e 
func helloWorld() {
    println("hello world")
}
