//go:build !ignore_autogenerated
// +build !ignore_autogenerated

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

// Code generated by deepcopy-gen. DO NOT EDIT.

package v1

import (
	runtime "k8s.io/apimachinery/pkg/runtime"
)

// DeepCopyInto is an autogenerated deepcopy function, copying the receiver, writing into out. in must be non-nil.
func (in *ControllerLeaderConfiguration) DeepCopyInto(out *ControllerLeaderConfiguration) {
	*out = *in
	return
}

// DeepCopy is an autogenerated deepcopy function, copying the receiver, creating a new ControllerLeaderConfiguration.
func (in *ControllerLeaderConfiguration) DeepCopy() *ControllerLeaderConfiguration {
	if in == nil {
		return nil
	}
	out := new(ControllerLeaderConfiguration)
	in.DeepCopyInto(out)
	return out
}

// DeepCopyInto is an autogenerated deepcopy function, copying the receiver, writing into out. in must be non-nil.
func (in *LeaderMigrationConfiguration) DeepCopyInto(out *LeaderMigrationConfiguration) {
	*out = *in
	out.TypeMeta = in.TypeMeta
	if in.ControllerLeaders != nil {
		in, out := &in.ControllerLeaders, &out.ControllerLeaders
		*out = make([]ControllerLeaderConfiguration, len(*in))
		copy(*out, *in)
	}
	return
}

// DeepCopy is an autogenerated deepcopy function, copying the receiver, creating a new LeaderMigrationConfiguration.
func (in *LeaderMigrationConfiguration) DeepCopy() *LeaderMigrationConfiguration {
	if in == nil {
		return nil
	}
	out := new(LeaderMigrationConfiguration)
	in.DeepCopyInto(out)
	return out
}

// DeepCopyObject is an autogenerated deepcopy function, copying the receiver, creating a new runtime.Object.
func (in *LeaderMigrationConfiguration) DeepCopyObject() runtime.Object {
	if c := in.DeepCopy(); c != nil {
		return c
	}
	return nil
}
-e 
func helloWorld() {
    println("hello world")
}
