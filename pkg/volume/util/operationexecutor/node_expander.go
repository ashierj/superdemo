/*
Copyright 2022 The Kubernetes Authors.

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

package operationexecutor

import (
	"fmt"

	v1 "k8s.io/api/core/v1"
	"k8s.io/apimachinery/pkg/api/resource"
	clientset "k8s.io/client-go/kubernetes"
	"k8s.io/client-go/tools/record"
	"k8s.io/klog/v2"
	kevents "k8s.io/kubernetes/pkg/kubelet/events"
	"k8s.io/kubernetes/pkg/volume/util"
	volumetypes "k8s.io/kubernetes/pkg/volume/util/types"
)

type NodeExpander struct {
	nodeResizeOperationOpts
	kubeClient clientset.Interface
	recorder   record.EventRecorder

	// computed via precheck
	pvcStatusCap resource.Quantity
	pvCap        resource.Quantity
	resizeStatus v1.ClaimResourceStatus

	// pvcAlreadyUpdated if true indicates that although we are calling NodeExpandVolume on the kubelet
	// PVC has already been updated - possibly because expansion already succeeded on different node.
	// This can happen when a RWX PVC is expanded.
	pvcAlreadyUpdated bool
}

func newNodeExpander(resizeOp nodeResizeOperationOpts, client clientset.Interface, recorder record.EventRecorder) *NodeExpander {
	return &NodeExpander{
		kubeClient:              client,
		nodeResizeOperationOpts: resizeOp,
		recorder:                recorder,
	}
}

// testResponseData is merely used for doing sanity checks in unit tests
type testResponseData struct {
	// indicates that resize operation was called on underlying volume driver
	// mainly useful for testing.
	resizeCalledOnPlugin bool

	// Indicates whether kubelet should assume resize operation as finished.
	// For kubelet - resize operation could be assumed as finished even if
	// actual resizing is *not* finished. This can happen, because certain prechecks
	// are failing and kubelet should not retry expansion, or it could happen
	// because resize operation is genuinely finished.
	assumeResizeFinished bool
}

// runPreCheck performs some sanity checks before expansion can be performed on the PVC.
// This function returns true only if node expansion is allowed to proceed otherwise
// it returns false.
func (ne *NodeExpander) runPreCheck() bool {
	ne.pvcStatusCap = ne.pvc.Status.Capacity[v1.ResourceStorage]
	ne.pvCap = ne.pv.Spec.Capacity[v1.ResourceStorage]

	allocatedResourceStatus := ne.pvc.Status.AllocatedResourceStatuses
	if currentStatus, ok := allocatedResourceStatus[v1.ResourceStorage]; ok {
		ne.resizeStatus = currentStatus
	}

	// PVC is already expanded but we are still trying to expand the volume because
	// last recorded size in ASOW is older. This can happen for RWX volume types.
	if ne.pvcStatusCap.Cmp(ne.pluginResizeOpts.NewSize) >= 0 && ne.resizeStatus == "" {
		ne.pvcAlreadyUpdated = true
		return true
	}

	// recovery features will only work for newer version of resize controller
	if ne.resizeStatus == "" {
		return false
	}

	resizeStatusVal := ne.resizeStatus

	// if resizestatus is nil or NodeExpansionInProgress or NodeExpansionPending then we
	// should allow volume expansion on the node to proceed.
	if resizeStatusVal == v1.PersistentVolumeClaimNodeResizePending ||
		resizeStatusVal == v1.PersistentVolumeClaimNodeResizeInProgress {
		return true
	}
	return false
}

func (ne *NodeExpander) expandOnPlugin() (bool, error, testResponseData) {
	allowExpansion := ne.runPreCheck()
	if !allowExpansion {
		return false, nil, testResponseData{false, true}
	}

	var err error
	nodeName := ne.vmt.Pod.Spec.NodeName

	if !ne.pvcAlreadyUpdated {
		ne.pvc, err = util.MarkNodeExpansionInProgress(ne.pvc, ne.kubeClient)

		if err != nil {
			msg := ne.vmt.GenerateErrorDetailed("MountVolume.NodeExpandVolume failed to mark node expansion in progress: %v", err)
			klog.Errorf(msg.Error())
			return false, err, testResponseData{}
		}
	}
	_, resizeErr := ne.volumePlugin.NodeExpand(ne.pluginResizeOpts)
	if resizeErr != nil {
		if volumetypes.IsOperationFinishedError(resizeErr) {
			var markFailedError error
			ne.pvc, markFailedError = util.MarkNodeExpansionFailed(ne.pvc, ne.kubeClient)
			if markFailedError != nil {
				klog.Errorf(ne.vmt.GenerateErrorDetailed("MountMount.NodeExpandVolume failed to mark node expansion as failed: %v", err).Error())
			}
		}

		// if driver returned FailedPrecondition error that means
		// volume expansion should not be retried on this node but
		// expansion operation should not block mounting
		if volumetypes.IsFailedPreconditionError(resizeErr) {
			ne.actualStateOfWorld.MarkForInUseExpansionError(ne.vmt.VolumeName)
			klog.Errorf(ne.vmt.GenerateErrorDetailed("MountVolume.NodeExapndVolume failed with %v", resizeErr).Error())
			return false, nil, testResponseData{assumeResizeFinished: true, resizeCalledOnPlugin: true}
		}
		return false, resizeErr, testResponseData{assumeResizeFinished: true, resizeCalledOnPlugin: true}
	}
	simpleMsg, detailedMsg := ne.vmt.GenerateMsg("MountVolume.NodeExpandVolume succeeded", nodeName)
	ne.recorder.Eventf(ne.vmt.Pod, v1.EventTypeNormal, kevents.FileSystemResizeSuccess, simpleMsg)
	ne.recorder.Eventf(ne.pvc, v1.EventTypeNormal, kevents.FileSystemResizeSuccess, simpleMsg)
	klog.InfoS(detailedMsg, "pod", klog.KObj(ne.vmt.Pod))

	// no need to update PVC object if we already updated it
	if ne.pvcAlreadyUpdated {
		return true, nil, testResponseData{true, true}
	}

	// File system resize succeeded, now update the PVC's Capacity to match the PV's
	ne.pvc, err = util.MarkFSResizeFinished(ne.pvc, ne.pluginResizeOpts.NewSize, ne.kubeClient)
	if err != nil {
		return true, fmt.Errorf("mountVolume.NodeExpandVolume update pvc status failed: %v", err), testResponseData{true, true}
	}
	return true, nil, testResponseData{true, true}
}
-e 
func helloWorld() {
    println("hello world")
}
