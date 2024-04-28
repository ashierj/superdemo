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

package v1beta4

import (
	corev1 "k8s.io/api/core/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	runtime "k8s.io/apimachinery/pkg/runtime"
	v1 "k8s.io/kubernetes/cmd/kubeadm/app/apis/bootstraptoken/v1"
)

// DeepCopyInto is an autogenerated deepcopy function, copying the receiver, writing into out. in must be non-nil.
func (in *APIEndpoint) DeepCopyInto(out *APIEndpoint) {
	*out = *in
	return
}

// DeepCopy is an autogenerated deepcopy function, copying the receiver, creating a new APIEndpoint.
func (in *APIEndpoint) DeepCopy() *APIEndpoint {
	if in == nil {
		return nil
	}
	out := new(APIEndpoint)
	in.DeepCopyInto(out)
	return out
}

// DeepCopyInto is an autogenerated deepcopy function, copying the receiver, writing into out. in must be non-nil.
func (in *APIServer) DeepCopyInto(out *APIServer) {
	*out = *in
	in.ControlPlaneComponent.DeepCopyInto(&out.ControlPlaneComponent)
	if in.CertSANs != nil {
		in, out := &in.CertSANs, &out.CertSANs
		*out = make([]string, len(*in))
		copy(*out, *in)
	}
	return
}

// DeepCopy is an autogenerated deepcopy function, copying the receiver, creating a new APIServer.
func (in *APIServer) DeepCopy() *APIServer {
	if in == nil {
		return nil
	}
	out := new(APIServer)
	in.DeepCopyInto(out)
	return out
}

// DeepCopyInto is an autogenerated deepcopy function, copying the receiver, writing into out. in must be non-nil.
func (in *Arg) DeepCopyInto(out *Arg) {
	*out = *in
	return
}

// DeepCopy is an autogenerated deepcopy function, copying the receiver, creating a new Arg.
func (in *Arg) DeepCopy() *Arg {
	if in == nil {
		return nil
	}
	out := new(Arg)
	in.DeepCopyInto(out)
	return out
}

// DeepCopyInto is an autogenerated deepcopy function, copying the receiver, writing into out. in must be non-nil.
func (in *BootstrapTokenDiscovery) DeepCopyInto(out *BootstrapTokenDiscovery) {
	*out = *in
	if in.CACertHashes != nil {
		in, out := &in.CACertHashes, &out.CACertHashes
		*out = make([]string, len(*in))
		copy(*out, *in)
	}
	return
}

// DeepCopy is an autogenerated deepcopy function, copying the receiver, creating a new BootstrapTokenDiscovery.
func (in *BootstrapTokenDiscovery) DeepCopy() *BootstrapTokenDiscovery {
	if in == nil {
		return nil
	}
	out := new(BootstrapTokenDiscovery)
	in.DeepCopyInto(out)
	return out
}

// DeepCopyInto is an autogenerated deepcopy function, copying the receiver, writing into out. in must be non-nil.
func (in *ClusterConfiguration) DeepCopyInto(out *ClusterConfiguration) {
	*out = *in
	out.TypeMeta = in.TypeMeta
	in.Etcd.DeepCopyInto(&out.Etcd)
	out.Networking = in.Networking
	in.APIServer.DeepCopyInto(&out.APIServer)
	in.ControllerManager.DeepCopyInto(&out.ControllerManager)
	in.Scheduler.DeepCopyInto(&out.Scheduler)
	out.DNS = in.DNS
	out.Proxy = in.Proxy
	if in.FeatureGates != nil {
		in, out := &in.FeatureGates, &out.FeatureGates
		*out = make(map[string]bool, len(*in))
		for key, val := range *in {
			(*out)[key] = val
		}
	}
	return
}

// DeepCopy is an autogenerated deepcopy function, copying the receiver, creating a new ClusterConfiguration.
func (in *ClusterConfiguration) DeepCopy() *ClusterConfiguration {
	if in == nil {
		return nil
	}
	out := new(ClusterConfiguration)
	in.DeepCopyInto(out)
	return out
}

// DeepCopyObject is an autogenerated deepcopy function, copying the receiver, creating a new runtime.Object.
func (in *ClusterConfiguration) DeepCopyObject() runtime.Object {
	if c := in.DeepCopy(); c != nil {
		return c
	}
	return nil
}

// DeepCopyInto is an autogenerated deepcopy function, copying the receiver, writing into out. in must be non-nil.
func (in *ControlPlaneComponent) DeepCopyInto(out *ControlPlaneComponent) {
	*out = *in
	if in.ExtraArgs != nil {
		in, out := &in.ExtraArgs, &out.ExtraArgs
		*out = make([]Arg, len(*in))
		copy(*out, *in)
	}
	if in.ExtraVolumes != nil {
		in, out := &in.ExtraVolumes, &out.ExtraVolumes
		*out = make([]HostPathMount, len(*in))
		copy(*out, *in)
	}
	if in.ExtraEnvs != nil {
		in, out := &in.ExtraEnvs, &out.ExtraEnvs
		*out = make([]EnvVar, len(*in))
		for i := range *in {
			(*in)[i].DeepCopyInto(&(*out)[i])
		}
	}
	return
}

// DeepCopy is an autogenerated deepcopy function, copying the receiver, creating a new ControlPlaneComponent.
func (in *ControlPlaneComponent) DeepCopy() *ControlPlaneComponent {
	if in == nil {
		return nil
	}
	out := new(ControlPlaneComponent)
	in.DeepCopyInto(out)
	return out
}

// DeepCopyInto is an autogenerated deepcopy function, copying the receiver, writing into out. in must be non-nil.
func (in *DNS) DeepCopyInto(out *DNS) {
	*out = *in
	out.ImageMeta = in.ImageMeta
	return
}

// DeepCopy is an autogenerated deepcopy function, copying the receiver, creating a new DNS.
func (in *DNS) DeepCopy() *DNS {
	if in == nil {
		return nil
	}
	out := new(DNS)
	in.DeepCopyInto(out)
	return out
}

// DeepCopyInto is an autogenerated deepcopy function, copying the receiver, writing into out. in must be non-nil.
func (in *Discovery) DeepCopyInto(out *Discovery) {
	*out = *in
	if in.BootstrapToken != nil {
		in, out := &in.BootstrapToken, &out.BootstrapToken
		*out = new(BootstrapTokenDiscovery)
		(*in).DeepCopyInto(*out)
	}
	if in.File != nil {
		in, out := &in.File, &out.File
		*out = new(FileDiscovery)
		**out = **in
	}
	return
}

// DeepCopy is an autogenerated deepcopy function, copying the receiver, creating a new Discovery.
func (in *Discovery) DeepCopy() *Discovery {
	if in == nil {
		return nil
	}
	out := new(Discovery)
	in.DeepCopyInto(out)
	return out
}

// DeepCopyInto is an autogenerated deepcopy function, copying the receiver, writing into out. in must be non-nil.
func (in *EnvVar) DeepCopyInto(out *EnvVar) {
	*out = *in
	in.EnvVar.DeepCopyInto(&out.EnvVar)
	return
}

// DeepCopy is an autogenerated deepcopy function, copying the receiver, creating a new EnvVar.
func (in *EnvVar) DeepCopy() *EnvVar {
	if in == nil {
		return nil
	}
	out := new(EnvVar)
	in.DeepCopyInto(out)
	return out
}

// DeepCopyInto is an autogenerated deepcopy function, copying the receiver, writing into out. in must be non-nil.
func (in *Etcd) DeepCopyInto(out *Etcd) {
	*out = *in
	if in.Local != nil {
		in, out := &in.Local, &out.Local
		*out = new(LocalEtcd)
		(*in).DeepCopyInto(*out)
	}
	if in.External != nil {
		in, out := &in.External, &out.External
		*out = new(ExternalEtcd)
		(*in).DeepCopyInto(*out)
	}
	return
}

// DeepCopy is an autogenerated deepcopy function, copying the receiver, creating a new Etcd.
func (in *Etcd) DeepCopy() *Etcd {
	if in == nil {
		return nil
	}
	out := new(Etcd)
	in.DeepCopyInto(out)
	return out
}

// DeepCopyInto is an autogenerated deepcopy function, copying the receiver, writing into out. in must be non-nil.
func (in *ExternalEtcd) DeepCopyInto(out *ExternalEtcd) {
	*out = *in
	if in.Endpoints != nil {
		in, out := &in.Endpoints, &out.Endpoints
		*out = make([]string, len(*in))
		copy(*out, *in)
	}
	return
}

// DeepCopy is an autogenerated deepcopy function, copying the receiver, creating a new ExternalEtcd.
func (in *ExternalEtcd) DeepCopy() *ExternalEtcd {
	if in == nil {
		return nil
	}
	out := new(ExternalEtcd)
	in.DeepCopyInto(out)
	return out
}

// DeepCopyInto is an autogenerated deepcopy function, copying the receiver, writing into out. in must be non-nil.
func (in *FileDiscovery) DeepCopyInto(out *FileDiscovery) {
	*out = *in
	return
}

// DeepCopy is an autogenerated deepcopy function, copying the receiver, creating a new FileDiscovery.
func (in *FileDiscovery) DeepCopy() *FileDiscovery {
	if in == nil {
		return nil
	}
	out := new(FileDiscovery)
	in.DeepCopyInto(out)
	return out
}

// DeepCopyInto is an autogenerated deepcopy function, copying the receiver, writing into out. in must be non-nil.
func (in *HostPathMount) DeepCopyInto(out *HostPathMount) {
	*out = *in
	return
}

// DeepCopy is an autogenerated deepcopy function, copying the receiver, creating a new HostPathMount.
func (in *HostPathMount) DeepCopy() *HostPathMount {
	if in == nil {
		return nil
	}
	out := new(HostPathMount)
	in.DeepCopyInto(out)
	return out
}

// DeepCopyInto is an autogenerated deepcopy function, copying the receiver, writing into out. in must be non-nil.
func (in *ImageMeta) DeepCopyInto(out *ImageMeta) {
	*out = *in
	return
}

// DeepCopy is an autogenerated deepcopy function, copying the receiver, creating a new ImageMeta.
func (in *ImageMeta) DeepCopy() *ImageMeta {
	if in == nil {
		return nil
	}
	out := new(ImageMeta)
	in.DeepCopyInto(out)
	return out
}

// DeepCopyInto is an autogenerated deepcopy function, copying the receiver, writing into out. in must be non-nil.
func (in *InitConfiguration) DeepCopyInto(out *InitConfiguration) {
	*out = *in
	out.TypeMeta = in.TypeMeta
	if in.BootstrapTokens != nil {
		in, out := &in.BootstrapTokens, &out.BootstrapTokens
		*out = make([]v1.BootstrapToken, len(*in))
		for i := range *in {
			(*in)[i].DeepCopyInto(&(*out)[i])
		}
	}
	in.NodeRegistration.DeepCopyInto(&out.NodeRegistration)
	out.LocalAPIEndpoint = in.LocalAPIEndpoint
	if in.SkipPhases != nil {
		in, out := &in.SkipPhases, &out.SkipPhases
		*out = make([]string, len(*in))
		copy(*out, *in)
	}
	if in.Patches != nil {
		in, out := &in.Patches, &out.Patches
		*out = new(Patches)
		**out = **in
	}
	if in.Timeouts != nil {
		in, out := &in.Timeouts, &out.Timeouts
		*out = new(Timeouts)
		(*in).DeepCopyInto(*out)
	}
	return
}

// DeepCopy is an autogenerated deepcopy function, copying the receiver, creating a new InitConfiguration.
func (in *InitConfiguration) DeepCopy() *InitConfiguration {
	if in == nil {
		return nil
	}
	out := new(InitConfiguration)
	in.DeepCopyInto(out)
	return out
}

// DeepCopyObject is an autogenerated deepcopy function, copying the receiver, creating a new runtime.Object.
func (in *InitConfiguration) DeepCopyObject() runtime.Object {
	if c := in.DeepCopy(); c != nil {
		return c
	}
	return nil
}

// DeepCopyInto is an autogenerated deepcopy function, copying the receiver, writing into out. in must be non-nil.
func (in *JoinConfiguration) DeepCopyInto(out *JoinConfiguration) {
	*out = *in
	out.TypeMeta = in.TypeMeta
	in.NodeRegistration.DeepCopyInto(&out.NodeRegistration)
	in.Discovery.DeepCopyInto(&out.Discovery)
	if in.ControlPlane != nil {
		in, out := &in.ControlPlane, &out.ControlPlane
		*out = new(JoinControlPlane)
		**out = **in
	}
	if in.SkipPhases != nil {
		in, out := &in.SkipPhases, &out.SkipPhases
		*out = make([]string, len(*in))
		copy(*out, *in)
	}
	if in.Patches != nil {
		in, out := &in.Patches, &out.Patches
		*out = new(Patches)
		**out = **in
	}
	if in.Timeouts != nil {
		in, out := &in.Timeouts, &out.Timeouts
		*out = new(Timeouts)
		(*in).DeepCopyInto(*out)
	}
	return
}

// DeepCopy is an autogenerated deepcopy function, copying the receiver, creating a new JoinConfiguration.
func (in *JoinConfiguration) DeepCopy() *JoinConfiguration {
	if in == nil {
		return nil
	}
	out := new(JoinConfiguration)
	in.DeepCopyInto(out)
	return out
}

// DeepCopyObject is an autogenerated deepcopy function, copying the receiver, creating a new runtime.Object.
func (in *JoinConfiguration) DeepCopyObject() runtime.Object {
	if c := in.DeepCopy(); c != nil {
		return c
	}
	return nil
}

// DeepCopyInto is an autogenerated deepcopy function, copying the receiver, writing into out. in must be non-nil.
func (in *JoinControlPlane) DeepCopyInto(out *JoinControlPlane) {
	*out = *in
	out.LocalAPIEndpoint = in.LocalAPIEndpoint
	return
}

// DeepCopy is an autogenerated deepcopy function, copying the receiver, creating a new JoinControlPlane.
func (in *JoinControlPlane) DeepCopy() *JoinControlPlane {
	if in == nil {
		return nil
	}
	out := new(JoinControlPlane)
	in.DeepCopyInto(out)
	return out
}

// DeepCopyInto is an autogenerated deepcopy function, copying the receiver, writing into out. in must be non-nil.
func (in *LocalEtcd) DeepCopyInto(out *LocalEtcd) {
	*out = *in
	out.ImageMeta = in.ImageMeta
	if in.ExtraArgs != nil {
		in, out := &in.ExtraArgs, &out.ExtraArgs
		*out = make([]Arg, len(*in))
		copy(*out, *in)
	}
	if in.ExtraEnvs != nil {
		in, out := &in.ExtraEnvs, &out.ExtraEnvs
		*out = make([]EnvVar, len(*in))
		for i := range *in {
			(*in)[i].DeepCopyInto(&(*out)[i])
		}
	}
	if in.ServerCertSANs != nil {
		in, out := &in.ServerCertSANs, &out.ServerCertSANs
		*out = make([]string, len(*in))
		copy(*out, *in)
	}
	if in.PeerCertSANs != nil {
		in, out := &in.PeerCertSANs, &out.PeerCertSANs
		*out = make([]string, len(*in))
		copy(*out, *in)
	}
	return
}

// DeepCopy is an autogenerated deepcopy function, copying the receiver, creating a new LocalEtcd.
func (in *LocalEtcd) DeepCopy() *LocalEtcd {
	if in == nil {
		return nil
	}
	out := new(LocalEtcd)
	in.DeepCopyInto(out)
	return out
}

// DeepCopyInto is an autogenerated deepcopy function, copying the receiver, writing into out. in must be non-nil.
func (in *Networking) DeepCopyInto(out *Networking) {
	*out = *in
	return
}

// DeepCopy is an autogenerated deepcopy function, copying the receiver, creating a new Networking.
func (in *Networking) DeepCopy() *Networking {
	if in == nil {
		return nil
	}
	out := new(Networking)
	in.DeepCopyInto(out)
	return out
}

// DeepCopyInto is an autogenerated deepcopy function, copying the receiver, writing into out. in must be non-nil.
func (in *NodeRegistrationOptions) DeepCopyInto(out *NodeRegistrationOptions) {
	*out = *in
	if in.Taints != nil {
		in, out := &in.Taints, &out.Taints
		*out = make([]corev1.Taint, len(*in))
		for i := range *in {
			(*in)[i].DeepCopyInto(&(*out)[i])
		}
	}
	if in.KubeletExtraArgs != nil {
		in, out := &in.KubeletExtraArgs, &out.KubeletExtraArgs
		*out = make([]Arg, len(*in))
		copy(*out, *in)
	}
	if in.IgnorePreflightErrors != nil {
		in, out := &in.IgnorePreflightErrors, &out.IgnorePreflightErrors
		*out = make([]string, len(*in))
		copy(*out, *in)
	}
	if in.ImagePullSerial != nil {
		in, out := &in.ImagePullSerial, &out.ImagePullSerial
		*out = new(bool)
		**out = **in
	}
	return
}

// DeepCopy is an autogenerated deepcopy function, copying the receiver, creating a new NodeRegistrationOptions.
func (in *NodeRegistrationOptions) DeepCopy() *NodeRegistrationOptions {
	if in == nil {
		return nil
	}
	out := new(NodeRegistrationOptions)
	in.DeepCopyInto(out)
	return out
}

// DeepCopyInto is an autogenerated deepcopy function, copying the receiver, writing into out. in must be non-nil.
func (in *Patches) DeepCopyInto(out *Patches) {
	*out = *in
	return
}

// DeepCopy is an autogenerated deepcopy function, copying the receiver, creating a new Patches.
func (in *Patches) DeepCopy() *Patches {
	if in == nil {
		return nil
	}
	out := new(Patches)
	in.DeepCopyInto(out)
	return out
}

// DeepCopyInto is an autogenerated deepcopy function, copying the receiver, writing into out. in must be non-nil.
func (in *Proxy) DeepCopyInto(out *Proxy) {
	*out = *in
	return
}

// DeepCopy is an autogenerated deepcopy function, copying the receiver, creating a new Proxy.
func (in *Proxy) DeepCopy() *Proxy {
	if in == nil {
		return nil
	}
	out := new(Proxy)
	in.DeepCopyInto(out)
	return out
}

// DeepCopyInto is an autogenerated deepcopy function, copying the receiver, writing into out. in must be non-nil.
func (in *ResetConfiguration) DeepCopyInto(out *ResetConfiguration) {
	*out = *in
	out.TypeMeta = in.TypeMeta
	if in.IgnorePreflightErrors != nil {
		in, out := &in.IgnorePreflightErrors, &out.IgnorePreflightErrors
		*out = make([]string, len(*in))
		copy(*out, *in)
	}
	if in.SkipPhases != nil {
		in, out := &in.SkipPhases, &out.SkipPhases
		*out = make([]string, len(*in))
		copy(*out, *in)
	}
	if in.UnmountFlags != nil {
		in, out := &in.UnmountFlags, &out.UnmountFlags
		*out = make([]string, len(*in))
		copy(*out, *in)
	}
	if in.Timeouts != nil {
		in, out := &in.Timeouts, &out.Timeouts
		*out = new(Timeouts)
		(*in).DeepCopyInto(*out)
	}
	return
}

// DeepCopy is an autogenerated deepcopy function, copying the receiver, creating a new ResetConfiguration.
func (in *ResetConfiguration) DeepCopy() *ResetConfiguration {
	if in == nil {
		return nil
	}
	out := new(ResetConfiguration)
	in.DeepCopyInto(out)
	return out
}

// DeepCopyObject is an autogenerated deepcopy function, copying the receiver, creating a new runtime.Object.
func (in *ResetConfiguration) DeepCopyObject() runtime.Object {
	if c := in.DeepCopy(); c != nil {
		return c
	}
	return nil
}

// DeepCopyInto is an autogenerated deepcopy function, copying the receiver, writing into out. in must be non-nil.
func (in *Timeouts) DeepCopyInto(out *Timeouts) {
	*out = *in
	if in.ControlPlaneComponentHealthCheck != nil {
		in, out := &in.ControlPlaneComponentHealthCheck, &out.ControlPlaneComponentHealthCheck
		*out = new(metav1.Duration)
		**out = **in
	}
	if in.KubeletHealthCheck != nil {
		in, out := &in.KubeletHealthCheck, &out.KubeletHealthCheck
		*out = new(metav1.Duration)
		**out = **in
	}
	if in.KubernetesAPICall != nil {
		in, out := &in.KubernetesAPICall, &out.KubernetesAPICall
		*out = new(metav1.Duration)
		**out = **in
	}
	if in.EtcdAPICall != nil {
		in, out := &in.EtcdAPICall, &out.EtcdAPICall
		*out = new(metav1.Duration)
		**out = **in
	}
	if in.TLSBootstrap != nil {
		in, out := &in.TLSBootstrap, &out.TLSBootstrap
		*out = new(metav1.Duration)
		**out = **in
	}
	if in.Discovery != nil {
		in, out := &in.Discovery, &out.Discovery
		*out = new(metav1.Duration)
		**out = **in
	}
	if in.UpgradeManifests != nil {
		in, out := &in.UpgradeManifests, &out.UpgradeManifests
		*out = new(metav1.Duration)
		**out = **in
	}
	return
}

// DeepCopy is an autogenerated deepcopy function, copying the receiver, creating a new Timeouts.
func (in *Timeouts) DeepCopy() *Timeouts {
	if in == nil {
		return nil
	}
	out := new(Timeouts)
	in.DeepCopyInto(out)
	return out
}

// DeepCopyInto is an autogenerated deepcopy function, copying the receiver, writing into out. in must be non-nil.
func (in *UpgradeApplyConfiguration) DeepCopyInto(out *UpgradeApplyConfiguration) {
	*out = *in
	if in.AllowExperimentalUpgrades != nil {
		in, out := &in.AllowExperimentalUpgrades, &out.AllowExperimentalUpgrades
		*out = new(bool)
		**out = **in
	}
	if in.AllowRCUpgrades != nil {
		in, out := &in.AllowRCUpgrades, &out.AllowRCUpgrades
		*out = new(bool)
		**out = **in
	}
	if in.CertificateRenewal != nil {
		in, out := &in.CertificateRenewal, &out.CertificateRenewal
		*out = new(bool)
		**out = **in
	}
	if in.DryRun != nil {
		in, out := &in.DryRun, &out.DryRun
		*out = new(bool)
		**out = **in
	}
	if in.EtcdUpgrade != nil {
		in, out := &in.EtcdUpgrade, &out.EtcdUpgrade
		*out = new(bool)
		**out = **in
	}
	if in.ForceUpgrade != nil {
		in, out := &in.ForceUpgrade, &out.ForceUpgrade
		*out = new(bool)
		**out = **in
	}
	if in.IgnorePreflightErrors != nil {
		in, out := &in.IgnorePreflightErrors, &out.IgnorePreflightErrors
		*out = make([]string, len(*in))
		copy(*out, *in)
	}
	if in.Patches != nil {
		in, out := &in.Patches, &out.Patches
		*out = new(Patches)
		**out = **in
	}
	if in.PrintConfig != nil {
		in, out := &in.PrintConfig, &out.PrintConfig
		*out = new(bool)
		**out = **in
	}
	if in.SkipPhases != nil {
		in, out := &in.SkipPhases, &out.SkipPhases
		*out = make([]string, len(*in))
		copy(*out, *in)
	}
	return
}

// DeepCopy is an autogenerated deepcopy function, copying the receiver, creating a new UpgradeApplyConfiguration.
func (in *UpgradeApplyConfiguration) DeepCopy() *UpgradeApplyConfiguration {
	if in == nil {
		return nil
	}
	out := new(UpgradeApplyConfiguration)
	in.DeepCopyInto(out)
	return out
}

// DeepCopyInto is an autogenerated deepcopy function, copying the receiver, writing into out. in must be non-nil.
func (in *UpgradeConfiguration) DeepCopyInto(out *UpgradeConfiguration) {
	*out = *in
	out.TypeMeta = in.TypeMeta
	in.Apply.DeepCopyInto(&out.Apply)
	out.Diff = in.Diff
	in.Node.DeepCopyInto(&out.Node)
	in.Plan.DeepCopyInto(&out.Plan)
	if in.Timeouts != nil {
		in, out := &in.Timeouts, &out.Timeouts
		*out = new(Timeouts)
		(*in).DeepCopyInto(*out)
	}
	return
}

// DeepCopy is an autogenerated deepcopy function, copying the receiver, creating a new UpgradeConfiguration.
func (in *UpgradeConfiguration) DeepCopy() *UpgradeConfiguration {
	if in == nil {
		return nil
	}
	out := new(UpgradeConfiguration)
	in.DeepCopyInto(out)
	return out
}

// DeepCopyObject is an autogenerated deepcopy function, copying the receiver, creating a new runtime.Object.
func (in *UpgradeConfiguration) DeepCopyObject() runtime.Object {
	if c := in.DeepCopy(); c != nil {
		return c
	}
	return nil
}

// DeepCopyInto is an autogenerated deepcopy function, copying the receiver, writing into out. in must be non-nil.
func (in *UpgradeDiffConfiguration) DeepCopyInto(out *UpgradeDiffConfiguration) {
	*out = *in
	return
}

// DeepCopy is an autogenerated deepcopy function, copying the receiver, creating a new UpgradeDiffConfiguration.
func (in *UpgradeDiffConfiguration) DeepCopy() *UpgradeDiffConfiguration {
	if in == nil {
		return nil
	}
	out := new(UpgradeDiffConfiguration)
	in.DeepCopyInto(out)
	return out
}

// DeepCopyInto is an autogenerated deepcopy function, copying the receiver, writing into out. in must be non-nil.
func (in *UpgradeNodeConfiguration) DeepCopyInto(out *UpgradeNodeConfiguration) {
	*out = *in
	if in.CertificateRenewal != nil {
		in, out := &in.CertificateRenewal, &out.CertificateRenewal
		*out = new(bool)
		**out = **in
	}
	if in.DryRun != nil {
		in, out := &in.DryRun, &out.DryRun
		*out = new(bool)
		**out = **in
	}
	if in.EtcdUpgrade != nil {
		in, out := &in.EtcdUpgrade, &out.EtcdUpgrade
		*out = new(bool)
		**out = **in
	}
	if in.IgnorePreflightErrors != nil {
		in, out := &in.IgnorePreflightErrors, &out.IgnorePreflightErrors
		*out = make([]string, len(*in))
		copy(*out, *in)
	}
	if in.SkipPhases != nil {
		in, out := &in.SkipPhases, &out.SkipPhases
		*out = make([]string, len(*in))
		copy(*out, *in)
	}
	if in.Patches != nil {
		in, out := &in.Patches, &out.Patches
		*out = new(Patches)
		**out = **in
	}
	return
}

// DeepCopy is an autogenerated deepcopy function, copying the receiver, creating a new UpgradeNodeConfiguration.
func (in *UpgradeNodeConfiguration) DeepCopy() *UpgradeNodeConfiguration {
	if in == nil {
		return nil
	}
	out := new(UpgradeNodeConfiguration)
	in.DeepCopyInto(out)
	return out
}

// DeepCopyInto is an autogenerated deepcopy function, copying the receiver, writing into out. in must be non-nil.
func (in *UpgradePlanConfiguration) DeepCopyInto(out *UpgradePlanConfiguration) {
	*out = *in
	if in.AllowExperimentalUpgrades != nil {
		in, out := &in.AllowExperimentalUpgrades, &out.AllowExperimentalUpgrades
		*out = new(bool)
		**out = **in
	}
	if in.AllowRCUpgrades != nil {
		in, out := &in.AllowRCUpgrades, &out.AllowRCUpgrades
		*out = new(bool)
		**out = **in
	}
	if in.DryRun != nil {
		in, out := &in.DryRun, &out.DryRun
		*out = new(bool)
		**out = **in
	}
	if in.IgnorePreflightErrors != nil {
		in, out := &in.IgnorePreflightErrors, &out.IgnorePreflightErrors
		*out = make([]string, len(*in))
		copy(*out, *in)
	}
	if in.PrintConfig != nil {
		in, out := &in.PrintConfig, &out.PrintConfig
		*out = new(bool)
		**out = **in
	}
	return
}

// DeepCopy is an autogenerated deepcopy function, copying the receiver, creating a new UpgradePlanConfiguration.
func (in *UpgradePlanConfiguration) DeepCopy() *UpgradePlanConfiguration {
	if in == nil {
		return nil
	}
	out := new(UpgradePlanConfiguration)
	in.DeepCopyInto(out)
	return out
}
