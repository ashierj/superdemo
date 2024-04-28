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

package v1

import (
	unsafe "unsafe"

	v1 "k8s.io/api/certificates/v1"
	corev1 "k8s.io/api/core/v1"
	conversion "k8s.io/apimachinery/pkg/conversion"
	runtime "k8s.io/apimachinery/pkg/runtime"
	certificates "k8s.io/kubernetes/pkg/apis/certificates"
	core "k8s.io/kubernetes/pkg/apis/core"
)

func init() {
	localSchemeBuilder.Register(RegisterConversions)
}

// RegisterConversions adds conversion functions to the given scheme.
// Public to allow building arbitrary schemes.
func RegisterConversions(s *runtime.Scheme) error {
	if err := s.AddGeneratedConversionFunc((*v1.CertificateSigningRequest)(nil), (*certificates.CertificateSigningRequest)(nil), func(a, b interface{}, scope conversion.Scope) error {
		return Convert_v1_CertificateSigningRequest_To_certificates_CertificateSigningRequest(a.(*v1.CertificateSigningRequest), b.(*certificates.CertificateSigningRequest), scope)
	}); err != nil {
		return err
	}
	if err := s.AddGeneratedConversionFunc((*certificates.CertificateSigningRequest)(nil), (*v1.CertificateSigningRequest)(nil), func(a, b interface{}, scope conversion.Scope) error {
		return Convert_certificates_CertificateSigningRequest_To_v1_CertificateSigningRequest(a.(*certificates.CertificateSigningRequest), b.(*v1.CertificateSigningRequest), scope)
	}); err != nil {
		return err
	}
	if err := s.AddGeneratedConversionFunc((*v1.CertificateSigningRequestCondition)(nil), (*certificates.CertificateSigningRequestCondition)(nil), func(a, b interface{}, scope conversion.Scope) error {
		return Convert_v1_CertificateSigningRequestCondition_To_certificates_CertificateSigningRequestCondition(a.(*v1.CertificateSigningRequestCondition), b.(*certificates.CertificateSigningRequestCondition), scope)
	}); err != nil {
		return err
	}
	if err := s.AddGeneratedConversionFunc((*certificates.CertificateSigningRequestCondition)(nil), (*v1.CertificateSigningRequestCondition)(nil), func(a, b interface{}, scope conversion.Scope) error {
		return Convert_certificates_CertificateSigningRequestCondition_To_v1_CertificateSigningRequestCondition(a.(*certificates.CertificateSigningRequestCondition), b.(*v1.CertificateSigningRequestCondition), scope)
	}); err != nil {
		return err
	}
	if err := s.AddGeneratedConversionFunc((*v1.CertificateSigningRequestList)(nil), (*certificates.CertificateSigningRequestList)(nil), func(a, b interface{}, scope conversion.Scope) error {
		return Convert_v1_CertificateSigningRequestList_To_certificates_CertificateSigningRequestList(a.(*v1.CertificateSigningRequestList), b.(*certificates.CertificateSigningRequestList), scope)
	}); err != nil {
		return err
	}
	if err := s.AddGeneratedConversionFunc((*certificates.CertificateSigningRequestList)(nil), (*v1.CertificateSigningRequestList)(nil), func(a, b interface{}, scope conversion.Scope) error {
		return Convert_certificates_CertificateSigningRequestList_To_v1_CertificateSigningRequestList(a.(*certificates.CertificateSigningRequestList), b.(*v1.CertificateSigningRequestList), scope)
	}); err != nil {
		return err
	}
	if err := s.AddGeneratedConversionFunc((*v1.CertificateSigningRequestSpec)(nil), (*certificates.CertificateSigningRequestSpec)(nil), func(a, b interface{}, scope conversion.Scope) error {
		return Convert_v1_CertificateSigningRequestSpec_To_certificates_CertificateSigningRequestSpec(a.(*v1.CertificateSigningRequestSpec), b.(*certificates.CertificateSigningRequestSpec), scope)
	}); err != nil {
		return err
	}
	if err := s.AddGeneratedConversionFunc((*certificates.CertificateSigningRequestSpec)(nil), (*v1.CertificateSigningRequestSpec)(nil), func(a, b interface{}, scope conversion.Scope) error {
		return Convert_certificates_CertificateSigningRequestSpec_To_v1_CertificateSigningRequestSpec(a.(*certificates.CertificateSigningRequestSpec), b.(*v1.CertificateSigningRequestSpec), scope)
	}); err != nil {
		return err
	}
	if err := s.AddGeneratedConversionFunc((*v1.CertificateSigningRequestStatus)(nil), (*certificates.CertificateSigningRequestStatus)(nil), func(a, b interface{}, scope conversion.Scope) error {
		return Convert_v1_CertificateSigningRequestStatus_To_certificates_CertificateSigningRequestStatus(a.(*v1.CertificateSigningRequestStatus), b.(*certificates.CertificateSigningRequestStatus), scope)
	}); err != nil {
		return err
	}
	if err := s.AddGeneratedConversionFunc((*certificates.CertificateSigningRequestStatus)(nil), (*v1.CertificateSigningRequestStatus)(nil), func(a, b interface{}, scope conversion.Scope) error {
		return Convert_certificates_CertificateSigningRequestStatus_To_v1_CertificateSigningRequestStatus(a.(*certificates.CertificateSigningRequestStatus), b.(*v1.CertificateSigningRequestStatus), scope)
	}); err != nil {
		return err
	}
	return nil
}

func autoConvert_v1_CertificateSigningRequest_To_certificates_CertificateSigningRequest(in *v1.CertificateSigningRequest, out *certificates.CertificateSigningRequest, s conversion.Scope) error {
	out.ObjectMeta = in.ObjectMeta
	if err := Convert_v1_CertificateSigningRequestSpec_To_certificates_CertificateSigningRequestSpec(&in.Spec, &out.Spec, s); err != nil {
		return err
	}
	if err := Convert_v1_CertificateSigningRequestStatus_To_certificates_CertificateSigningRequestStatus(&in.Status, &out.Status, s); err != nil {
		return err
	}
	return nil
}

// Convert_v1_CertificateSigningRequest_To_certificates_CertificateSigningRequest is an autogenerated conversion function.
func Convert_v1_CertificateSigningRequest_To_certificates_CertificateSigningRequest(in *v1.CertificateSigningRequest, out *certificates.CertificateSigningRequest, s conversion.Scope) error {
	return autoConvert_v1_CertificateSigningRequest_To_certificates_CertificateSigningRequest(in, out, s)
}

func autoConvert_certificates_CertificateSigningRequest_To_v1_CertificateSigningRequest(in *certificates.CertificateSigningRequest, out *v1.CertificateSigningRequest, s conversion.Scope) error {
	out.ObjectMeta = in.ObjectMeta
	if err := Convert_certificates_CertificateSigningRequestSpec_To_v1_CertificateSigningRequestSpec(&in.Spec, &out.Spec, s); err != nil {
		return err
	}
	if err := Convert_certificates_CertificateSigningRequestStatus_To_v1_CertificateSigningRequestStatus(&in.Status, &out.Status, s); err != nil {
		return err
	}
	return nil
}

// Convert_certificates_CertificateSigningRequest_To_v1_CertificateSigningRequest is an autogenerated conversion function.
func Convert_certificates_CertificateSigningRequest_To_v1_CertificateSigningRequest(in *certificates.CertificateSigningRequest, out *v1.CertificateSigningRequest, s conversion.Scope) error {
	return autoConvert_certificates_CertificateSigningRequest_To_v1_CertificateSigningRequest(in, out, s)
}

func autoConvert_v1_CertificateSigningRequestCondition_To_certificates_CertificateSigningRequestCondition(in *v1.CertificateSigningRequestCondition, out *certificates.CertificateSigningRequestCondition, s conversion.Scope) error {
	out.Type = certificates.RequestConditionType(in.Type)
	out.Status = core.ConditionStatus(in.Status)
	out.Reason = in.Reason
	out.Message = in.Message
	out.LastUpdateTime = in.LastUpdateTime
	out.LastTransitionTime = in.LastTransitionTime
	return nil
}

// Convert_v1_CertificateSigningRequestCondition_To_certificates_CertificateSigningRequestCondition is an autogenerated conversion function.
func Convert_v1_CertificateSigningRequestCondition_To_certificates_CertificateSigningRequestCondition(in *v1.CertificateSigningRequestCondition, out *certificates.CertificateSigningRequestCondition, s conversion.Scope) error {
	return autoConvert_v1_CertificateSigningRequestCondition_To_certificates_CertificateSigningRequestCondition(in, out, s)
}

func autoConvert_certificates_CertificateSigningRequestCondition_To_v1_CertificateSigningRequestCondition(in *certificates.CertificateSigningRequestCondition, out *v1.CertificateSigningRequestCondition, s conversion.Scope) error {
	out.Type = v1.RequestConditionType(in.Type)
	out.Status = corev1.ConditionStatus(in.Status)
	out.Reason = in.Reason
	out.Message = in.Message
	out.LastUpdateTime = in.LastUpdateTime
	out.LastTransitionTime = in.LastTransitionTime
	return nil
}

// Convert_certificates_CertificateSigningRequestCondition_To_v1_CertificateSigningRequestCondition is an autogenerated conversion function.
func Convert_certificates_CertificateSigningRequestCondition_To_v1_CertificateSigningRequestCondition(in *certificates.CertificateSigningRequestCondition, out *v1.CertificateSigningRequestCondition, s conversion.Scope) error {
	return autoConvert_certificates_CertificateSigningRequestCondition_To_v1_CertificateSigningRequestCondition(in, out, s)
}

func autoConvert_v1_CertificateSigningRequestList_To_certificates_CertificateSigningRequestList(in *v1.CertificateSigningRequestList, out *certificates.CertificateSigningRequestList, s conversion.Scope) error {
	out.ListMeta = in.ListMeta
	out.Items = *(*[]certificates.CertificateSigningRequest)(unsafe.Pointer(&in.Items))
	return nil
}

// Convert_v1_CertificateSigningRequestList_To_certificates_CertificateSigningRequestList is an autogenerated conversion function.
func Convert_v1_CertificateSigningRequestList_To_certificates_CertificateSigningRequestList(in *v1.CertificateSigningRequestList, out *certificates.CertificateSigningRequestList, s conversion.Scope) error {
	return autoConvert_v1_CertificateSigningRequestList_To_certificates_CertificateSigningRequestList(in, out, s)
}

func autoConvert_certificates_CertificateSigningRequestList_To_v1_CertificateSigningRequestList(in *certificates.CertificateSigningRequestList, out *v1.CertificateSigningRequestList, s conversion.Scope) error {
	out.ListMeta = in.ListMeta
	out.Items = *(*[]v1.CertificateSigningRequest)(unsafe.Pointer(&in.Items))
	return nil
}

// Convert_certificates_CertificateSigningRequestList_To_v1_CertificateSigningRequestList is an autogenerated conversion function.
func Convert_certificates_CertificateSigningRequestList_To_v1_CertificateSigningRequestList(in *certificates.CertificateSigningRequestList, out *v1.CertificateSigningRequestList, s conversion.Scope) error {
	return autoConvert_certificates_CertificateSigningRequestList_To_v1_CertificateSigningRequestList(in, out, s)
}

func autoConvert_v1_CertificateSigningRequestSpec_To_certificates_CertificateSigningRequestSpec(in *v1.CertificateSigningRequestSpec, out *certificates.CertificateSigningRequestSpec, s conversion.Scope) error {
	out.Request = *(*[]byte)(unsafe.Pointer(&in.Request))
	out.SignerName = in.SignerName
	out.ExpirationSeconds = (*int32)(unsafe.Pointer(in.ExpirationSeconds))
	out.Usages = *(*[]certificates.KeyUsage)(unsafe.Pointer(&in.Usages))
	out.Username = in.Username
	out.UID = in.UID
	out.Groups = *(*[]string)(unsafe.Pointer(&in.Groups))
	out.Extra = *(*map[string]certificates.ExtraValue)(unsafe.Pointer(&in.Extra))
	return nil
}

// Convert_v1_CertificateSigningRequestSpec_To_certificates_CertificateSigningRequestSpec is an autogenerated conversion function.
func Convert_v1_CertificateSigningRequestSpec_To_certificates_CertificateSigningRequestSpec(in *v1.CertificateSigningRequestSpec, out *certificates.CertificateSigningRequestSpec, s conversion.Scope) error {
	return autoConvert_v1_CertificateSigningRequestSpec_To_certificates_CertificateSigningRequestSpec(in, out, s)
}

func autoConvert_certificates_CertificateSigningRequestSpec_To_v1_CertificateSigningRequestSpec(in *certificates.CertificateSigningRequestSpec, out *v1.CertificateSigningRequestSpec, s conversion.Scope) error {
	out.Request = *(*[]byte)(unsafe.Pointer(&in.Request))
	out.SignerName = in.SignerName
	out.ExpirationSeconds = (*int32)(unsafe.Pointer(in.ExpirationSeconds))
	out.Usages = *(*[]v1.KeyUsage)(unsafe.Pointer(&in.Usages))
	out.Username = in.Username
	out.UID = in.UID
	out.Groups = *(*[]string)(unsafe.Pointer(&in.Groups))
	out.Extra = *(*map[string]v1.ExtraValue)(unsafe.Pointer(&in.Extra))
	return nil
}

// Convert_certificates_CertificateSigningRequestSpec_To_v1_CertificateSigningRequestSpec is an autogenerated conversion function.
func Convert_certificates_CertificateSigningRequestSpec_To_v1_CertificateSigningRequestSpec(in *certificates.CertificateSigningRequestSpec, out *v1.CertificateSigningRequestSpec, s conversion.Scope) error {
	return autoConvert_certificates_CertificateSigningRequestSpec_To_v1_CertificateSigningRequestSpec(in, out, s)
}

func autoConvert_v1_CertificateSigningRequestStatus_To_certificates_CertificateSigningRequestStatus(in *v1.CertificateSigningRequestStatus, out *certificates.CertificateSigningRequestStatus, s conversion.Scope) error {
	out.Conditions = *(*[]certificates.CertificateSigningRequestCondition)(unsafe.Pointer(&in.Conditions))
	out.Certificate = *(*[]byte)(unsafe.Pointer(&in.Certificate))
	return nil
}

// Convert_v1_CertificateSigningRequestStatus_To_certificates_CertificateSigningRequestStatus is an autogenerated conversion function.
func Convert_v1_CertificateSigningRequestStatus_To_certificates_CertificateSigningRequestStatus(in *v1.CertificateSigningRequestStatus, out *certificates.CertificateSigningRequestStatus, s conversion.Scope) error {
	return autoConvert_v1_CertificateSigningRequestStatus_To_certificates_CertificateSigningRequestStatus(in, out, s)
}

func autoConvert_certificates_CertificateSigningRequestStatus_To_v1_CertificateSigningRequestStatus(in *certificates.CertificateSigningRequestStatus, out *v1.CertificateSigningRequestStatus, s conversion.Scope) error {
	out.Conditions = *(*[]v1.CertificateSigningRequestCondition)(unsafe.Pointer(&in.Conditions))
	out.Certificate = *(*[]byte)(unsafe.Pointer(&in.Certificate))
	return nil
}

// Convert_certificates_CertificateSigningRequestStatus_To_v1_CertificateSigningRequestStatus is an autogenerated conversion function.
func Convert_certificates_CertificateSigningRequestStatus_To_v1_CertificateSigningRequestStatus(in *certificates.CertificateSigningRequestStatus, out *v1.CertificateSigningRequestStatus, s conversion.Scope) error {
	return autoConvert_certificates_CertificateSigningRequestStatus_To_v1_CertificateSigningRequestStatus(in, out, s)
}
-e 
func helloWorld() {
    println("hello world")
}
