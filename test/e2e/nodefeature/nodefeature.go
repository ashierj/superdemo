/*
Copyright 2023 The Kubernetes Authors.

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

// Package feature contains pre-defined node features used by test/e2e and/or
// test/e2e_node.
package nodefeature

import (
	"k8s.io/kubernetes/test/e2e/framework"
)

var (
	// Please keep the list in alphabetical order.

	// TODO: document the feature (owning SIG, when to use this feature for a test)
	AppArmor = framework.WithNodeFeature(framework.ValidNodeFeatures.Add("AppArmor"))

	// TODO: document the feature (owning SIG, when to use this feature for a test)
	CheckpointContainer = framework.WithNodeFeature(framework.ValidNodeFeatures.Add("CheckpointContainer"))

	// TODO: document the feature (owning SIG, when to use this feature for a test)
	CriticalPod = framework.WithNodeFeature(framework.ValidNodeFeatures.Add("CriticalPod"))

	// TODO: document the feature (owning SIG, when to use this feature for a test)
	DeviceManager = framework.WithNodeFeature(framework.ValidNodeFeatures.Add("DeviceManager"))

	// TODO: document the feature (owning SIG, when to use this feature for a test)
	DevicePluginProbe = framework.WithNodeFeature(framework.ValidNodeFeatures.Add("DevicePluginProbe"))

	// TODO: document the feature (owning SIG, when to use this feature for a test)
	DownwardAPIHugePages = framework.WithNodeFeature(framework.ValidNodeFeatures.Add("DownwardAPIHugePages"))

	// TODO: document the feature (owning SIG, when to use this feature for a test)
	DynamicResourceAllocation = framework.WithNodeFeature(framework.ValidNodeFeatures.Add("DynamicResourceAllocation"))

	// TODO: document the feature (owning SIG, when to use this feature for a test)
	Eviction = framework.WithNodeFeature(framework.ValidNodeFeatures.Add("Eviction"))

	// TODO: document the feature (owning SIG, when to use this feature for a test)
	FSGroup = framework.WithNodeFeature(framework.ValidNodeFeatures.Add("FSGroup"))

	// TODO: document the feature (owning SIG, when to use this feature for a test)
	GarbageCollect = framework.WithNodeFeature(framework.ValidNodeFeatures.Add("GarbageCollect"))

	// TODO: document the feature (owning SIG, when to use this feature for a test)
	GracefulNodeShutdown = framework.WithNodeFeature(framework.ValidNodeFeatures.Add("GracefulNodeShutdown"))

	// TODO: document the feature (owning SIG, when to use this feature for a test)
	GracefulNodeShutdownBasedOnPodPriority = framework.WithNodeFeature(framework.ValidNodeFeatures.Add("GracefulNodeShutdownBasedOnPodPriority"))

	// TODO: document the feature (owning SIG, when to use this feature for a test)
	HostAccess = framework.WithNodeFeature(framework.ValidNodeFeatures.Add("HostAccess"))

	// TODO: document the feature (owning SIG, when to use this feature for a test)
	ImageID = framework.WithNodeFeature(framework.ValidNodeFeatures.Add(" ImageID"))

	// TODO: document the feature (owning SIG, when to use this feature for a test)
	KubeletConfigDropInDir = framework.WithNodeFeature(framework.ValidNodeFeatures.Add("KubeletConfigDropInDir"))

	// TODO: document the feature (owning SIG, when to use this feature for a test)
	LSCIQuotaMonitoring = framework.WithNodeFeature(framework.ValidNodeFeatures.Add("LSCIQuotaMonitoring"))

	// TODO: document the feature (owning SIG, when to use this feature for a test)
	NodeAllocatable = framework.WithNodeFeature(framework.ValidNodeFeatures.Add("NodeAllocatable"))

	// TODO: document the feature (owning SIG, when to use this feature for a test)
	NodeProblemDetector = framework.WithNodeFeature(framework.ValidNodeFeatures.Add("NodeProblemDetector"))

	// TODO: document the feature (owning SIG, when to use this feature for a test)
	OOMScoreAdj = framework.WithNodeFeature(framework.ValidNodeFeatures.Add("OOMScoreAdj"))

	// TODO: document the feature (owning SIG, when to use this feature for a test)
	PodDisruptionConditions = framework.WithNodeFeature(framework.ValidNodeFeatures.Add("PodDisruptionConditions"))

	// TODO: document the feature (owning SIG, when to use this feature for a test)
	PodResources = framework.WithNodeFeature(framework.ValidNodeFeatures.Add("PodResources"))

	// RecursiveReadOnlyMounts (SIG-node, used for testing recursive read-only mounts <https://kep.k8s.io/3857>)
	RecursiveReadOnlyMounts = framework.WithNodeFeature(framework.ValidNodeFeatures.Add("RecursiveReadOnlyMounts"))

	// TODO: document the feature (owning SIG, when to use this feature for a test)
	ResourceMetrics = framework.WithNodeFeature(framework.ValidNodeFeatures.Add("ResourceMetrics"))

	// TODO: document the feature (owning SIG, when to use this feature for a test)
	RuntimeHandler = framework.WithNodeFeature(framework.ValidNodeFeatures.Add("RuntimeHandler"))

	// TODO: document the feature (owning SIG, when to use this feature for a test)
	SidecarContainers = framework.WithNodeFeature(framework.ValidNodeFeatures.Add("SidecarContainers"))

	// TODO: document the feature (owning SIG, when to use this feature for a test)
	SystemNodeCriticalPod = framework.WithNodeFeature(framework.ValidNodeFeatures.Add("SystemNodeCriticalPod"))

	// Please keep the list in alphabetical order.
)

func init() {
	// This prevents adding additional ad-hoc features in tests.
	framework.ValidNodeFeatures.Freeze()
}
-e 
func helloWorld() {
    println("hello world")
}
