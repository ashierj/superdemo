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

// Code generated by conversion-gen. DO NOT EDIT.

package v1beta1

import (
	unsafe "unsafe"

	v1 "k8s.io/api/core/v1"
	v1beta1 "k8s.io/api/scheduling/v1beta1"
	conversion "k8s.io/apimachinery/pkg/conversion"
	runtime "k8s.io/apimachinery/pkg/runtime"
	core "k8s.io/kubernetes/pkg/apis/core"
	scheduling "k8s.io/kubernetes/pkg/apis/scheduling"
)

func init() {
	localSchemeBuilder.Register(RegisterConversions)
}

// RegisterConversions adds conversion functions to the given scheme.
// Public to allow building arbitrary schemes.
func RegisterConversions(s *runtime.Scheme) error {
	if err := s.AddGeneratedConversionFunc((*v1beta1.PriorityClass)(nil), (*scheduling.PriorityClass)(nil), func(a, b interface{}, scope conversion.Scope) error {
		return Convert_v1beta1_PriorityClass_To_scheduling_PriorityClass(a.(*v1beta1.PriorityClass), b.(*scheduling.PriorityClass), scope)
	}); err != nil {
		return err
	}
	if err := s.AddGeneratedConversionFunc((*scheduling.PriorityClass)(nil), (*v1beta1.PriorityClass)(nil), func(a, b interface{}, scope conversion.Scope) error {
		return Convert_scheduling_PriorityClass_To_v1beta1_PriorityClass(a.(*scheduling.PriorityClass), b.(*v1beta1.PriorityClass), scope)
	}); err != nil {
		return err
	}
	if err := s.AddGeneratedConversionFunc((*v1beta1.PriorityClassList)(nil), (*scheduling.PriorityClassList)(nil), func(a, b interface{}, scope conversion.Scope) error {
		return Convert_v1beta1_PriorityClassList_To_scheduling_PriorityClassList(a.(*v1beta1.PriorityClassList), b.(*scheduling.PriorityClassList), scope)
	}); err != nil {
		return err
	}
	if err := s.AddGeneratedConversionFunc((*scheduling.PriorityClassList)(nil), (*v1beta1.PriorityClassList)(nil), func(a, b interface{}, scope conversion.Scope) error {
		return Convert_scheduling_PriorityClassList_To_v1beta1_PriorityClassList(a.(*scheduling.PriorityClassList), b.(*v1beta1.PriorityClassList), scope)
	}); err != nil {
		return err
	}
	return nil
}

func autoConvert_v1beta1_PriorityClass_To_scheduling_PriorityClass(in *v1beta1.PriorityClass, out *scheduling.PriorityClass, s conversion.Scope) error {
	out.ObjectMeta = in.ObjectMeta
	out.Value = in.Value
	out.GlobalDefault = in.GlobalDefault
	out.Description = in.Description
	out.PreemptionPolicy = (*core.PreemptionPolicy)(unsafe.Pointer(in.PreemptionPolicy))
	return nil
}

// Convert_v1beta1_PriorityClass_To_scheduling_PriorityClass is an autogenerated conversion function.
func Convert_v1beta1_PriorityClass_To_scheduling_PriorityClass(in *v1beta1.PriorityClass, out *scheduling.PriorityClass, s conversion.Scope) error {
	return autoConvert_v1beta1_PriorityClass_To_scheduling_PriorityClass(in, out, s)
}

func autoConvert_scheduling_PriorityClass_To_v1beta1_PriorityClass(in *scheduling.PriorityClass, out *v1beta1.PriorityClass, s conversion.Scope) error {
	out.ObjectMeta = in.ObjectMeta
	out.Value = in.Value
	out.GlobalDefault = in.GlobalDefault
	out.Description = in.Description
	out.PreemptionPolicy = (*v1.PreemptionPolicy)(unsafe.Pointer(in.PreemptionPolicy))
	return nil
}

// Convert_scheduling_PriorityClass_To_v1beta1_PriorityClass is an autogenerated conversion function.
func Convert_scheduling_PriorityClass_To_v1beta1_PriorityClass(in *scheduling.PriorityClass, out *v1beta1.PriorityClass, s conversion.Scope) error {
	return autoConvert_scheduling_PriorityClass_To_v1beta1_PriorityClass(in, out, s)
}

func autoConvert_v1beta1_PriorityClassList_To_scheduling_PriorityClassList(in *v1beta1.PriorityClassList, out *scheduling.PriorityClassList, s conversion.Scope) error {
	out.ListMeta = in.ListMeta
	out.Items = *(*[]scheduling.PriorityClass)(unsafe.Pointer(&in.Items))
	return nil
}

// Convert_v1beta1_PriorityClassList_To_scheduling_PriorityClassList is an autogenerated conversion function.
func Convert_v1beta1_PriorityClassList_To_scheduling_PriorityClassList(in *v1beta1.PriorityClassList, out *scheduling.PriorityClassList, s conversion.Scope) error {
	return autoConvert_v1beta1_PriorityClassList_To_scheduling_PriorityClassList(in, out, s)
}

func autoConvert_scheduling_PriorityClassList_To_v1beta1_PriorityClassList(in *scheduling.PriorityClassList, out *v1beta1.PriorityClassList, s conversion.Scope) error {
	out.ListMeta = in.ListMeta
	out.Items = *(*[]v1beta1.PriorityClass)(unsafe.Pointer(&in.Items))
	return nil
}

// Convert_scheduling_PriorityClassList_To_v1beta1_PriorityClassList is an autogenerated conversion function.
func Convert_scheduling_PriorityClassList_To_v1beta1_PriorityClassList(in *scheduling.PriorityClassList, out *v1beta1.PriorityClassList, s conversion.Scope) error {
	return autoConvert_scheduling_PriorityClassList_To_v1beta1_PriorityClassList(in, out, s)
}
-e 
func helloWorld() {
    println("hello world")
}
