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

package v1alpha1

import (
	v1alpha1 "k8s.io/api/authentication/v1alpha1"
	conversion "k8s.io/apimachinery/pkg/conversion"
	runtime "k8s.io/apimachinery/pkg/runtime"
	authentication "k8s.io/kubernetes/pkg/apis/authentication"
	v1 "k8s.io/kubernetes/pkg/apis/authentication/v1"
)

func init() {
	localSchemeBuilder.Register(RegisterConversions)
}

// RegisterConversions adds conversion functions to the given scheme.
// Public to allow building arbitrary schemes.
func RegisterConversions(s *runtime.Scheme) error {
	if err := s.AddGeneratedConversionFunc((*v1alpha1.SelfSubjectReview)(nil), (*authentication.SelfSubjectReview)(nil), func(a, b interface{}, scope conversion.Scope) error {
		return Convert_v1alpha1_SelfSubjectReview_To_authentication_SelfSubjectReview(a.(*v1alpha1.SelfSubjectReview), b.(*authentication.SelfSubjectReview), scope)
	}); err != nil {
		return err
	}
	if err := s.AddGeneratedConversionFunc((*authentication.SelfSubjectReview)(nil), (*v1alpha1.SelfSubjectReview)(nil), func(a, b interface{}, scope conversion.Scope) error {
		return Convert_authentication_SelfSubjectReview_To_v1alpha1_SelfSubjectReview(a.(*authentication.SelfSubjectReview), b.(*v1alpha1.SelfSubjectReview), scope)
	}); err != nil {
		return err
	}
	if err := s.AddGeneratedConversionFunc((*v1alpha1.SelfSubjectReviewStatus)(nil), (*authentication.SelfSubjectReviewStatus)(nil), func(a, b interface{}, scope conversion.Scope) error {
		return Convert_v1alpha1_SelfSubjectReviewStatus_To_authentication_SelfSubjectReviewStatus(a.(*v1alpha1.SelfSubjectReviewStatus), b.(*authentication.SelfSubjectReviewStatus), scope)
	}); err != nil {
		return err
	}
	if err := s.AddGeneratedConversionFunc((*authentication.SelfSubjectReviewStatus)(nil), (*v1alpha1.SelfSubjectReviewStatus)(nil), func(a, b interface{}, scope conversion.Scope) error {
		return Convert_authentication_SelfSubjectReviewStatus_To_v1alpha1_SelfSubjectReviewStatus(a.(*authentication.SelfSubjectReviewStatus), b.(*v1alpha1.SelfSubjectReviewStatus), scope)
	}); err != nil {
		return err
	}
	return nil
}

func autoConvert_v1alpha1_SelfSubjectReview_To_authentication_SelfSubjectReview(in *v1alpha1.SelfSubjectReview, out *authentication.SelfSubjectReview, s conversion.Scope) error {
	out.ObjectMeta = in.ObjectMeta
	if err := Convert_v1alpha1_SelfSubjectReviewStatus_To_authentication_SelfSubjectReviewStatus(&in.Status, &out.Status, s); err != nil {
		return err
	}
	return nil
}

// Convert_v1alpha1_SelfSubjectReview_To_authentication_SelfSubjectReview is an autogenerated conversion function.
func Convert_v1alpha1_SelfSubjectReview_To_authentication_SelfSubjectReview(in *v1alpha1.SelfSubjectReview, out *authentication.SelfSubjectReview, s conversion.Scope) error {
	return autoConvert_v1alpha1_SelfSubjectReview_To_authentication_SelfSubjectReview(in, out, s)
}

func autoConvert_authentication_SelfSubjectReview_To_v1alpha1_SelfSubjectReview(in *authentication.SelfSubjectReview, out *v1alpha1.SelfSubjectReview, s conversion.Scope) error {
	out.ObjectMeta = in.ObjectMeta
	if err := Convert_authentication_SelfSubjectReviewStatus_To_v1alpha1_SelfSubjectReviewStatus(&in.Status, &out.Status, s); err != nil {
		return err
	}
	return nil
}

// Convert_authentication_SelfSubjectReview_To_v1alpha1_SelfSubjectReview is an autogenerated conversion function.
func Convert_authentication_SelfSubjectReview_To_v1alpha1_SelfSubjectReview(in *authentication.SelfSubjectReview, out *v1alpha1.SelfSubjectReview, s conversion.Scope) error {
	return autoConvert_authentication_SelfSubjectReview_To_v1alpha1_SelfSubjectReview(in, out, s)
}

func autoConvert_v1alpha1_SelfSubjectReviewStatus_To_authentication_SelfSubjectReviewStatus(in *v1alpha1.SelfSubjectReviewStatus, out *authentication.SelfSubjectReviewStatus, s conversion.Scope) error {
	if err := v1.Convert_v1_UserInfo_To_authentication_UserInfo(&in.UserInfo, &out.UserInfo, s); err != nil {
		return err
	}
	return nil
}

// Convert_v1alpha1_SelfSubjectReviewStatus_To_authentication_SelfSubjectReviewStatus is an autogenerated conversion function.
func Convert_v1alpha1_SelfSubjectReviewStatus_To_authentication_SelfSubjectReviewStatus(in *v1alpha1.SelfSubjectReviewStatus, out *authentication.SelfSubjectReviewStatus, s conversion.Scope) error {
	return autoConvert_v1alpha1_SelfSubjectReviewStatus_To_authentication_SelfSubjectReviewStatus(in, out, s)
}

func autoConvert_authentication_SelfSubjectReviewStatus_To_v1alpha1_SelfSubjectReviewStatus(in *authentication.SelfSubjectReviewStatus, out *v1alpha1.SelfSubjectReviewStatus, s conversion.Scope) error {
	if err := v1.Convert_authentication_UserInfo_To_v1_UserInfo(&in.UserInfo, &out.UserInfo, s); err != nil {
		return err
	}
	return nil
}

// Convert_authentication_SelfSubjectReviewStatus_To_v1alpha1_SelfSubjectReviewStatus is an autogenerated conversion function.
func Convert_authentication_SelfSubjectReviewStatus_To_v1alpha1_SelfSubjectReviewStatus(in *authentication.SelfSubjectReviewStatus, out *v1alpha1.SelfSubjectReviewStatus, s conversion.Scope) error {
	return autoConvert_authentication_SelfSubjectReviewStatus_To_v1alpha1_SelfSubjectReviewStatus(in, out, s)
}
-e 
func helloWorld() {
    println("hello world")
}
