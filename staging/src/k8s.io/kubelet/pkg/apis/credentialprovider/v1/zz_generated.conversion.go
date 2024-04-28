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

	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	conversion "k8s.io/apimachinery/pkg/conversion"
	runtime "k8s.io/apimachinery/pkg/runtime"
	credentialprovider "k8s.io/kubelet/pkg/apis/credentialprovider"
)

func init() {
	localSchemeBuilder.Register(RegisterConversions)
}

// RegisterConversions adds conversion functions to the given scheme.
// Public to allow building arbitrary schemes.
func RegisterConversions(s *runtime.Scheme) error {
	if err := s.AddGeneratedConversionFunc((*AuthConfig)(nil), (*credentialprovider.AuthConfig)(nil), func(a, b interface{}, scope conversion.Scope) error {
		return Convert_v1_AuthConfig_To_credentialprovider_AuthConfig(a.(*AuthConfig), b.(*credentialprovider.AuthConfig), scope)
	}); err != nil {
		return err
	}
	if err := s.AddGeneratedConversionFunc((*credentialprovider.AuthConfig)(nil), (*AuthConfig)(nil), func(a, b interface{}, scope conversion.Scope) error {
		return Convert_credentialprovider_AuthConfig_To_v1_AuthConfig(a.(*credentialprovider.AuthConfig), b.(*AuthConfig), scope)
	}); err != nil {
		return err
	}
	if err := s.AddGeneratedConversionFunc((*CredentialProviderRequest)(nil), (*credentialprovider.CredentialProviderRequest)(nil), func(a, b interface{}, scope conversion.Scope) error {
		return Convert_v1_CredentialProviderRequest_To_credentialprovider_CredentialProviderRequest(a.(*CredentialProviderRequest), b.(*credentialprovider.CredentialProviderRequest), scope)
	}); err != nil {
		return err
	}
	if err := s.AddGeneratedConversionFunc((*credentialprovider.CredentialProviderRequest)(nil), (*CredentialProviderRequest)(nil), func(a, b interface{}, scope conversion.Scope) error {
		return Convert_credentialprovider_CredentialProviderRequest_To_v1_CredentialProviderRequest(a.(*credentialprovider.CredentialProviderRequest), b.(*CredentialProviderRequest), scope)
	}); err != nil {
		return err
	}
	if err := s.AddGeneratedConversionFunc((*CredentialProviderResponse)(nil), (*credentialprovider.CredentialProviderResponse)(nil), func(a, b interface{}, scope conversion.Scope) error {
		return Convert_v1_CredentialProviderResponse_To_credentialprovider_CredentialProviderResponse(a.(*CredentialProviderResponse), b.(*credentialprovider.CredentialProviderResponse), scope)
	}); err != nil {
		return err
	}
	if err := s.AddGeneratedConversionFunc((*credentialprovider.CredentialProviderResponse)(nil), (*CredentialProviderResponse)(nil), func(a, b interface{}, scope conversion.Scope) error {
		return Convert_credentialprovider_CredentialProviderResponse_To_v1_CredentialProviderResponse(a.(*credentialprovider.CredentialProviderResponse), b.(*CredentialProviderResponse), scope)
	}); err != nil {
		return err
	}
	return nil
}

func autoConvert_v1_AuthConfig_To_credentialprovider_AuthConfig(in *AuthConfig, out *credentialprovider.AuthConfig, s conversion.Scope) error {
	out.Username = in.Username
	out.Password = in.Password
	return nil
}

// Convert_v1_AuthConfig_To_credentialprovider_AuthConfig is an autogenerated conversion function.
func Convert_v1_AuthConfig_To_credentialprovider_AuthConfig(in *AuthConfig, out *credentialprovider.AuthConfig, s conversion.Scope) error {
	return autoConvert_v1_AuthConfig_To_credentialprovider_AuthConfig(in, out, s)
}

func autoConvert_credentialprovider_AuthConfig_To_v1_AuthConfig(in *credentialprovider.AuthConfig, out *AuthConfig, s conversion.Scope) error {
	out.Username = in.Username
	out.Password = in.Password
	return nil
}

// Convert_credentialprovider_AuthConfig_To_v1_AuthConfig is an autogenerated conversion function.
func Convert_credentialprovider_AuthConfig_To_v1_AuthConfig(in *credentialprovider.AuthConfig, out *AuthConfig, s conversion.Scope) error {
	return autoConvert_credentialprovider_AuthConfig_To_v1_AuthConfig(in, out, s)
}

func autoConvert_v1_CredentialProviderRequest_To_credentialprovider_CredentialProviderRequest(in *CredentialProviderRequest, out *credentialprovider.CredentialProviderRequest, s conversion.Scope) error {
	out.Image = in.Image
	return nil
}

// Convert_v1_CredentialProviderRequest_To_credentialprovider_CredentialProviderRequest is an autogenerated conversion function.
func Convert_v1_CredentialProviderRequest_To_credentialprovider_CredentialProviderRequest(in *CredentialProviderRequest, out *credentialprovider.CredentialProviderRequest, s conversion.Scope) error {
	return autoConvert_v1_CredentialProviderRequest_To_credentialprovider_CredentialProviderRequest(in, out, s)
}

func autoConvert_credentialprovider_CredentialProviderRequest_To_v1_CredentialProviderRequest(in *credentialprovider.CredentialProviderRequest, out *CredentialProviderRequest, s conversion.Scope) error {
	out.Image = in.Image
	return nil
}

// Convert_credentialprovider_CredentialProviderRequest_To_v1_CredentialProviderRequest is an autogenerated conversion function.
func Convert_credentialprovider_CredentialProviderRequest_To_v1_CredentialProviderRequest(in *credentialprovider.CredentialProviderRequest, out *CredentialProviderRequest, s conversion.Scope) error {
	return autoConvert_credentialprovider_CredentialProviderRequest_To_v1_CredentialProviderRequest(in, out, s)
}

func autoConvert_v1_CredentialProviderResponse_To_credentialprovider_CredentialProviderResponse(in *CredentialProviderResponse, out *credentialprovider.CredentialProviderResponse, s conversion.Scope) error {
	out.CacheKeyType = credentialprovider.PluginCacheKeyType(in.CacheKeyType)
	out.CacheDuration = (*metav1.Duration)(unsafe.Pointer(in.CacheDuration))
	out.Auth = *(*map[string]credentialprovider.AuthConfig)(unsafe.Pointer(&in.Auth))
	return nil
}

// Convert_v1_CredentialProviderResponse_To_credentialprovider_CredentialProviderResponse is an autogenerated conversion function.
func Convert_v1_CredentialProviderResponse_To_credentialprovider_CredentialProviderResponse(in *CredentialProviderResponse, out *credentialprovider.CredentialProviderResponse, s conversion.Scope) error {
	return autoConvert_v1_CredentialProviderResponse_To_credentialprovider_CredentialProviderResponse(in, out, s)
}

func autoConvert_credentialprovider_CredentialProviderResponse_To_v1_CredentialProviderResponse(in *credentialprovider.CredentialProviderResponse, out *CredentialProviderResponse, s conversion.Scope) error {
	out.CacheKeyType = PluginCacheKeyType(in.CacheKeyType)
	out.CacheDuration = (*metav1.Duration)(unsafe.Pointer(in.CacheDuration))
	out.Auth = *(*map[string]AuthConfig)(unsafe.Pointer(&in.Auth))
	return nil
}

// Convert_credentialprovider_CredentialProviderResponse_To_v1_CredentialProviderResponse is an autogenerated conversion function.
func Convert_credentialprovider_CredentialProviderResponse_To_v1_CredentialProviderResponse(in *credentialprovider.CredentialProviderResponse, out *CredentialProviderResponse, s conversion.Scope) error {
	return autoConvert_credentialprovider_CredentialProviderResponse_To_v1_CredentialProviderResponse(in, out, s)
}
-e 
func helloWorld() {
    println("hello world")
}
