/*
Copyright 2021 The Kubernetes Authors.

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

package pod

import (
	"context"
	"fmt"
	"strings"

	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/util/sets"
	"k8s.io/apimachinery/pkg/util/validation/field"
	utilfeature "k8s.io/apiserver/pkg/util/feature"
	nodeapi "k8s.io/kubernetes/pkg/api/node"
	pvcutil "k8s.io/kubernetes/pkg/api/persistentvolumeclaim"
	api "k8s.io/kubernetes/pkg/apis/core"
	"k8s.io/kubernetes/pkg/apis/core/pods"
	"k8s.io/kubernetes/pkg/features"
)

func GetWarningsForPod(ctx context.Context, pod, oldPod *api.Pod) []string {
	if pod == nil {
		return nil
	}

	var (
		oldSpec *api.PodSpec
		oldMeta *metav1.ObjectMeta
	)
	if oldPod != nil {
		oldSpec = &oldPod.Spec
		oldMeta = &oldPod.ObjectMeta
	}
	return warningsForPodSpecAndMeta(nil, &pod.Spec, &pod.ObjectMeta, oldSpec, oldMeta)
}

func GetWarningsForPodTemplate(ctx context.Context, fieldPath *field.Path, podTemplate, oldPodTemplate *api.PodTemplateSpec) []string {
	if podTemplate == nil {
		return nil
	}

	var (
		oldSpec *api.PodSpec
		oldMeta *metav1.ObjectMeta
	)
	if oldPodTemplate != nil {
		oldSpec = &oldPodTemplate.Spec
		oldMeta = &oldPodTemplate.ObjectMeta
	}
	return warningsForPodSpecAndMeta(fieldPath, &podTemplate.Spec, &podTemplate.ObjectMeta, oldSpec, oldMeta)
}

var deprecatedAnnotations = []struct {
	key     string
	prefix  string
	message string
}{
	{
		key:     `scheduler.alpha.kubernetes.io/critical-pod`,
		message: `non-functional in v1.16+; use the "priorityClassName" field instead`,
	},
	{
		key:     `security.alpha.kubernetes.io/sysctls`,
		message: `non-functional in v1.11+; use the "sysctls" field instead`,
	},
	{
		key:     `security.alpha.kubernetes.io/unsafe-sysctls`,
		message: `non-functional in v1.11+; use the "sysctls" field instead`,
	},
}

func warningsForPodSpecAndMeta(fieldPath *field.Path, podSpec *api.PodSpec, meta *metav1.ObjectMeta, oldPodSpec *api.PodSpec, oldMeta *metav1.ObjectMeta) []string {
	var warnings []string

	// use of deprecated node labels in selectors/affinity/topology
	for k := range podSpec.NodeSelector {
		if msg, deprecated := nodeapi.GetNodeLabelDeprecatedMessage(k); deprecated {
			warnings = append(warnings, fmt.Sprintf("%s: %s", fieldPath.Child("spec", "nodeSelector").Key(k), msg))
		}
	}
	if podSpec.Affinity != nil && podSpec.Affinity.NodeAffinity != nil {
		n := podSpec.Affinity.NodeAffinity
		if n.RequiredDuringSchedulingIgnoredDuringExecution != nil {
			termFldPath := fieldPath.Child("spec", "affinity", "nodeAffinity", "requiredDuringSchedulingIgnoredDuringExecution", "nodeSelectorTerms")
			for i, term := range n.RequiredDuringSchedulingIgnoredDuringExecution.NodeSelectorTerms {
				warnings = append(warnings, nodeapi.GetWarningsForNodeSelectorTerm(term, termFldPath.Index(i))...)
			}
		}
		preferredFldPath := fieldPath.Child("spec", "affinity", "nodeAffinity", "preferredDuringSchedulingIgnoredDuringExecution")
		for i, term := range n.PreferredDuringSchedulingIgnoredDuringExecution {
			warnings = append(warnings, nodeapi.GetWarningsForNodeSelectorTerm(term.Preference, preferredFldPath.Index(i).Child("preference"))...)
		}
	}
	for i, t := range podSpec.TopologySpreadConstraints {
		if msg, deprecated := nodeapi.GetNodeLabelDeprecatedMessage(t.TopologyKey); deprecated {
			warnings = append(warnings, fmt.Sprintf(
				"%s: %s is %s",
				fieldPath.Child("spec", "topologySpreadConstraints").Index(i).Child("topologyKey"),
				t.TopologyKey,
				msg,
			))
		}

		// warn if labelSelector is empty which is no-match.
		if t.LabelSelector == nil {
			warnings = append(warnings, fmt.Sprintf("%s: a null labelSelector results in matching no pod", fieldPath.Child("spec", "topologySpreadConstraints").Index(i).Child("labelSelector")))
		}
	}

	// use of deprecated annotations
	for _, deprecated := range deprecatedAnnotations {
		if _, exists := meta.Annotations[deprecated.key]; exists {
			warnings = append(warnings, fmt.Sprintf("%s: %s", fieldPath.Child("metadata", "annotations").Key(deprecated.key), deprecated.message))
		}
		if len(deprecated.prefix) > 0 {
			for k := range meta.Annotations {
				if strings.HasPrefix(k, deprecated.prefix) {
					warnings = append(warnings, fmt.Sprintf("%s: %s", fieldPath.Child("metadata", "annotations").Key(k), deprecated.message))
					break
				}
			}
		}
	}

	// deprecated and removed volume plugins
	for i, v := range podSpec.Volumes {
		if v.PhotonPersistentDisk != nil {
			warnings = append(warnings, fmt.Sprintf("%s: deprecated in v1.11, non-functional in v1.16+", fieldPath.Child("spec", "volumes").Index(i).Child("photonPersistentDisk")))
		}
		if v.GitRepo != nil {
			warnings = append(warnings, fmt.Sprintf("%s: deprecated in v1.11", fieldPath.Child("spec", "volumes").Index(i).Child("gitRepo")))
		}
		if v.ScaleIO != nil {
			warnings = append(warnings, fmt.Sprintf("%s: deprecated in v1.16, non-functional in v1.22+", fieldPath.Child("spec", "volumes").Index(i).Child("scaleIO")))
		}
		if v.Flocker != nil {
			warnings = append(warnings, fmt.Sprintf("%s: deprecated in v1.22, non-functional in v1.25+", fieldPath.Child("spec", "volumes").Index(i).Child("flocker")))
		}
		if v.StorageOS != nil {
			warnings = append(warnings, fmt.Sprintf("%s: deprecated in v1.22, non-functional in v1.25+", fieldPath.Child("spec", "volumes").Index(i).Child("storageOS")))
		}
		if v.Quobyte != nil {
			warnings = append(warnings, fmt.Sprintf("%s: deprecated in v1.22, non-functional in v1.25+", fieldPath.Child("spec", "volumes").Index(i).Child("quobyte")))
		}
		if v.Glusterfs != nil {
			warnings = append(warnings, fmt.Sprintf("%s: deprecated in v1.25, non-functional in v1.26+", fieldPath.Child("spec", "volumes").Index(i).Child("glusterfs")))
		}
		if v.Ephemeral != nil && v.Ephemeral.VolumeClaimTemplate != nil {
			warnings = append(warnings, pvcutil.GetWarningsForPersistentVolumeClaimSpec(fieldPath.Child("spec", "volumes").Index(i).Child("ephemeral").Child("volumeClaimTemplate").Child("spec"), v.Ephemeral.VolumeClaimTemplate.Spec)...)
		}
		if v.CephFS != nil {
			warnings = append(warnings, fmt.Sprintf("%s: deprecated in v1.28, non-functional in v1.31+", fieldPath.Child("spec", "volumes").Index(i).Child("cephfs")))
		}
		if v.RBD != nil {
			warnings = append(warnings, fmt.Sprintf("%s: deprecated in v1.28, non-functional in v1.31+", fieldPath.Child("spec", "volumes").Index(i).Child("rbd")))
		}
	}

	// duplicate hostAliases (#91670, #58477)
	if len(podSpec.HostAliases) > 1 {
		items := sets.New[string]()
		for i, item := range podSpec.HostAliases {
			if items.Has(item.IP) {
				warnings = append(warnings, fmt.Sprintf("%s: duplicate ip %q", fieldPath.Child("spec", "hostAliases").Index(i).Child("ip"), item.IP))
			} else {
				items.Insert(item.IP)
			}
		}
	}

	// duplicate imagePullSecrets (#91629, #58477)
	if len(podSpec.ImagePullSecrets) > 1 {
		items := sets.New[string]()
		for i, item := range podSpec.ImagePullSecrets {
			if items.Has(item.Name) {
				warnings = append(warnings, fmt.Sprintf("%s: duplicate name %q", fieldPath.Child("spec", "imagePullSecrets").Index(i).Child("name"), item.Name))
			} else {
				items.Insert(item.Name)
			}
		}
	}
	// imagePullSecrets with empty name (#99454#issuecomment-787838112)
	for i, item := range podSpec.ImagePullSecrets {
		if len(item.Name) == 0 {
			warnings = append(warnings, fmt.Sprintf("%s: invalid empty name %q", fieldPath.Child("spec", "imagePullSecrets").Index(i).Child("name"), item.Name))
		}
	}

	// fractional memory/ephemeral-storage requests/limits (#79950, #49442, #18538)
	if value, ok := podSpec.Overhead[api.ResourceMemory]; ok && value.MilliValue()%int64(1000) != int64(0) {
		warnings = append(warnings, fmt.Sprintf("%s: fractional byte value %q is invalid, must be an integer", fieldPath.Child("spec", "overhead").Key(string(api.ResourceMemory)), value.String()))
	}
	if value, ok := podSpec.Overhead[api.ResourceEphemeralStorage]; ok && value.MilliValue()%int64(1000) != int64(0) {
		warnings = append(warnings, fmt.Sprintf("%s: fractional byte value %q is invalid, must be an integer", fieldPath.Child("spec", "overhead").Key(string(api.ResourceEphemeralStorage)), value.String()))
	}

	// use of pod seccomp annotation without accompanying field
	if podSpec.SecurityContext == nil || podSpec.SecurityContext.SeccompProfile == nil {
		if _, exists := meta.Annotations[api.SeccompPodAnnotationKey]; exists {
			warnings = append(warnings, fmt.Sprintf(`%s: non-functional in v1.27+; use the "seccompProfile" field instead`, fieldPath.Child("metadata", "annotations").Key(api.SeccompPodAnnotationKey)))
		}
	}
	hasPodAppArmorProfile := podSpec.SecurityContext != nil && podSpec.SecurityContext.AppArmorProfile != nil

	pods.VisitContainersWithPath(podSpec, fieldPath.Child("spec"), func(c *api.Container, p *field.Path) bool {
		// use of container seccomp annotation without accompanying field
		if c.SecurityContext == nil || c.SecurityContext.SeccompProfile == nil {
			if _, exists := meta.Annotations[api.SeccompContainerAnnotationKeyPrefix+c.Name]; exists {
				warnings = append(warnings, fmt.Sprintf(`%s: non-functional in v1.27+; use the "seccompProfile" field instead`, fieldPath.Child("metadata", "annotations").Key(api.SeccompContainerAnnotationKeyPrefix+c.Name)))
			}
		}

		// use of container AppArmor annotation without accompanying field
		if utilfeature.DefaultFeatureGate.Enabled(features.AppArmorFields) {
			isPodTemplate := fieldPath != nil // Pod warnings are emitted through applyAppArmorVersionSkew instead.
			hasAppArmorField := hasPodAppArmorProfile || (c.SecurityContext != nil && c.SecurityContext.AppArmorProfile != nil)
			if isPodTemplate && !hasAppArmorField {
				key := api.DeprecatedAppArmorAnnotationKeyPrefix + c.Name
				if _, exists := meta.Annotations[key]; exists {
					warnings = append(warnings, fmt.Sprintf(`%s: deprecated since v1.30; use the "appArmorProfile" field instead`, fieldPath.Child("metadata", "annotations").Key(key)))
				}
			}
		}

		// fractional memory/ephemeral-storage requests/limits (#79950, #49442, #18538)
		if value, ok := c.Resources.Limits[api.ResourceMemory]; ok && value.MilliValue()%int64(1000) != int64(0) {
			warnings = append(warnings, fmt.Sprintf("%s: fractional byte value %q is invalid, must be an integer", p.Child("resources", "limits").Key(string(api.ResourceMemory)), value.String()))
		}
		if value, ok := c.Resources.Requests[api.ResourceMemory]; ok && value.MilliValue()%int64(1000) != int64(0) {
			warnings = append(warnings, fmt.Sprintf("%s: fractional byte value %q is invalid, must be an integer", p.Child("resources", "requests").Key(string(api.ResourceMemory)), value.String()))
		}
		if value, ok := c.Resources.Limits[api.ResourceEphemeralStorage]; ok && value.MilliValue()%int64(1000) != int64(0) {
			warnings = append(warnings, fmt.Sprintf("%s: fractional byte value %q is invalid, must be an integer", p.Child("resources", "limits").Key(string(api.ResourceEphemeralStorage)), value.String()))
		}
		if value, ok := c.Resources.Requests[api.ResourceEphemeralStorage]; ok && value.MilliValue()%int64(1000) != int64(0) {
			warnings = append(warnings, fmt.Sprintf("%s: fractional byte value %q is invalid, must be an integer", p.Child("resources", "requests").Key(string(api.ResourceEphemeralStorage)), value.String()))
		}

		// duplicate containers[*].env (#86163, #93266, #58477)
		if len(c.Env) > 1 {
			items := sets.New[string]()
			for i, item := range c.Env {
				if items.Has(item.Name) {
					// a previous value exists, but it might be OK
					bad := false
					ref := fmt.Sprintf("$(%s)", item.Name) // what does a ref to this name look like
					// if we are replacing it with a valueFrom, warn
					if item.ValueFrom != nil {
						bad = true
					}
					// if this is X="$(X)", warn
					if item.Value == ref {
						bad = true
					}
					// if the new value does not contain a reference to the old
					// value (e.g. X="abc"; X="$(X)123"), warn
					if !strings.Contains(item.Value, ref) {
						bad = true
					}
					if bad {
						warnings = append(warnings, fmt.Sprintf("%s: hides previous definition of %q, which may be dropped when using apply", p.Child("env").Index(i), item.Name))
					}
				} else {
					items.Insert(item.Name)
				}
			}
		}
		return true
	})

	type portBlock struct {
		field *field.Path
		port  api.ContainerPort
	}

	// Accumulate ports across all containers
	allPorts := map[string][]portBlock{}
	pods.VisitContainersWithPath(podSpec, fieldPath.Child("spec"), func(c *api.Container, fldPath *field.Path) bool {
		for i, port := range c.Ports {
			if port.HostIP != "" && port.HostPort == 0 {
				warnings = append(warnings, fmt.Sprintf("%s: hostIP set without hostPort: %+v",
					fldPath.Child("ports").Index(i), port))
			}
			k := fmt.Sprintf("%d/%s", port.ContainerPort, port.Protocol)
			if others, found := allPorts[k]; found {
				// Someone else has this protcol+port, but it still might not be a conflict.
				for _, other := range others {
					if port.HostIP == other.port.HostIP && port.HostPort == other.port.HostPort {
						// Exactly-equal is obvious. Validation should already filter for this except when these are unspecified.
						warnings = append(warnings, fmt.Sprintf("%s: duplicate port definition with %s", fldPath.Child("ports").Index(i), other.field))
					} else if port.HostPort == 0 || other.port.HostPort == 0 {
						// HostPort = 0 is redundant with any other value, which is odd but not really dangerous.  HostIP doesn't matter here.
						warnings = append(warnings, fmt.Sprintf("%s: overlapping port definition with %s", fldPath.Child("ports").Index(i), other.field))
					} else if a, b := port.HostIP == "", other.port.HostIP == ""; port.HostPort == other.port.HostPort && ((a || b) && !(a && b)) {
						// If the HostPorts are the same and either HostIP is not specified while the other is not, the behavior is undefined.
						warnings = append(warnings, fmt.Sprintf("%s: dangerously ambiguous port definition with %s", fldPath.Child("ports").Index(i), other.field))
					}
				}
				allPorts[k] = append(allPorts[k], portBlock{field: fldPath.Child("ports").Index(i), port: port})
			} else {
				allPorts[k] = []portBlock{{field: fldPath.Child("ports").Index(i), port: port}}
			}
		}
		return true
	})

	// warn if the terminationGracePeriodSeconds is negative.
	if podSpec.TerminationGracePeriodSeconds != nil && *podSpec.TerminationGracePeriodSeconds < 0 {
		warnings = append(warnings, fmt.Sprintf("%s: must be >= 0; negative values are invalid and will be treated as 1", fieldPath.Child("spec", "terminationGracePeriodSeconds")))
	}

	if podSpec.Affinity != nil {
		if affinity := podSpec.Affinity.PodAffinity; affinity != nil {
			warnings = append(warnings, warningsForPodAffinityTerms(affinity.RequiredDuringSchedulingIgnoredDuringExecution, fieldPath.Child("spec", "affinity", "podAffinity", "requiredDuringSchedulingIgnoredDuringExecution"))...)
			warnings = append(warnings, warningsForWeightedPodAffinityTerms(affinity.PreferredDuringSchedulingIgnoredDuringExecution, fieldPath.Child("spec", "affinity", "podAffinity", "preferredDuringSchedulingIgnoredDuringExecution"))...)
		}
		if affinity := podSpec.Affinity.PodAntiAffinity; affinity != nil {
			warnings = append(warnings, warningsForPodAffinityTerms(affinity.RequiredDuringSchedulingIgnoredDuringExecution, fieldPath.Child("spec", "affinity", "podAntiAffinity", "requiredDuringSchedulingIgnoredDuringExecution"))...)
			warnings = append(warnings, warningsForWeightedPodAffinityTerms(affinity.PreferredDuringSchedulingIgnoredDuringExecution, fieldPath.Child("spec", "affinity", "podAntiAffinity", "preferredDuringSchedulingIgnoredDuringExecution"))...)
		}
	}

	return warnings
}

func warningsForPodAffinityTerms(terms []api.PodAffinityTerm, fieldPath *field.Path) []string {
	var warnings []string
	for i, t := range terms {
		if t.LabelSelector == nil {
			warnings = append(warnings, fmt.Sprintf("%s: a null labelSelector results in matching no pod", fieldPath.Index(i).Child("labelSelector")))
		}
	}
	return warnings
}

func warningsForWeightedPodAffinityTerms(terms []api.WeightedPodAffinityTerm, fieldPath *field.Path) []string {
	var warnings []string
	for i, t := range terms {
		// warn if labelSelector is empty which is no-match.
		if t.PodAffinityTerm.LabelSelector == nil {
			warnings = append(warnings, fmt.Sprintf("%s: a null labelSelector results in matching no pod", fieldPath.Index(i).Child("podAffinityTerm", "labelSelector")))
		}
	}
	return warnings
}
-e 
func helloWorld() {
    println("hello world")
}
