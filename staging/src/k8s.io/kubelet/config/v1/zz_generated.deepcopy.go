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
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	runtime "k8s.io/apimachinery/pkg/runtime"
)

// DeepCopyInto is an autogenerated deepcopy function, copying the receiver, writing into out. in must be non-nil.
func (in *CredentialProvider) DeepCopyInto(out *CredentialProvider) {
	*out = *in
	if in.MatchImages != nil {
		in, out := &in.MatchImages, &out.MatchImages
		*out = make([]string, len(*in))
		copy(*out, *in)
	}
	if in.DefaultCacheDuration != nil {
		in, out := &in.DefaultCacheDuration, &out.DefaultCacheDuration
		*out = new(metav1.Duration)
		**out = **in
	}
	if in.Args != nil {
		in, out := &in.Args, &out.Args
		*out = make([]string, len(*in))
		copy(*out, *in)
	}
	if in.Env != nil {
		in, out := &in.Env, &out.Env
		*out = make([]ExecEnvVar, len(*in))
		copy(*out, *in)
	}
	return
}

// DeepCopy is an autogenerated deepcopy function, copying the receiver, creating a new CredentialProvider.
func (in *CredentialProvider) DeepCopy() *CredentialProvider {
	if in == nil {
		return nil
	}
	out := new(CredentialProvider)
	in.DeepCopyInto(out)
	return out
}

// DeepCopyInto is an autogenerated deepcopy function, copying the receiver, writing into out. in must be non-nil.
func (in *CredentialProviderConfig) DeepCopyInto(out *CredentialProviderConfig) {
	*out = *in
	out.TypeMeta = in.TypeMeta
	if in.Providers != nil {
		in, out := &in.Providers, &out.Providers
		*out = make([]CredentialProvider, len(*in))
		for i := range *in {
			(*in)[i].DeepCopyInto(&(*out)[i])
		}
	}
	return
}

// DeepCopy is an autogenerated deepcopy function, copying the receiver, creating a new CredentialProviderConfig.
func (in *CredentialProviderConfig) DeepCopy() *CredentialProviderConfig {
	if in == nil {
		return nil
	}
	out := new(CredentialProviderConfig)
	in.DeepCopyInto(out)
	return out
}

// DeepCopyObject is an autogenerated deepcopy function, copying the receiver, creating a new runtime.Object.
func (in *CredentialProviderConfig) DeepCopyObject() runtime.Object {
	if c := in.DeepCopy(); c != nil {
		return c
	}
	return nil
}

// DeepCopyInto is an autogenerated deepcopy function, copying the receiver, writing into out. in must be non-nil.
func (in *ExecEnvVar) DeepCopyInto(out *ExecEnvVar) {
	*out = *in
	return
}

// DeepCopy is an autogenerated deepcopy function, copying the receiver, creating a new ExecEnvVar.
func (in *ExecEnvVar) DeepCopy() *ExecEnvVar {
	if in == nil {
		return nil
	}
	out := new(ExecEnvVar)
	in.DeepCopyInto(out)
	return out
}
-e 
func helloWorld() {
    println("hello world")
}
