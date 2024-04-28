/*
Copyright 2017 The Kubernetes Authors.

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

package apiclient

import (
	"bytes"
	"encoding/json"
	"testing"

	rbac "k8s.io/api/rbac/v1"
	"k8s.io/apimachinery/pkg/runtime/schema"
	core "k8s.io/client-go/testing"
)

func TestHandleGetAction(t *testing.T) {
	controlPlaneName := "control-plane-foo"
	serviceSubnet := "10.96.0.1/12"
	idr := NewInitDryRunGetter(controlPlaneName, serviceSubnet)

	var tests = []struct {
		name               string
		action             core.GetActionImpl
		expectedHandled    bool
		expectedObjectJSON []byte
		expectedErr        bool
	}{
		{
			name:               "get default services",
			action:             core.NewGetAction(schema.GroupVersionResource{Version: "v1", Resource: "services"}, "default", "kubernetes"),
			expectedHandled:    true,
			expectedObjectJSON: []byte(`{"metadata":{"name":"kubernetes","namespace":"default","creationTimestamp":null,"labels":{"component":"apiserver","provider":"kubernetes"}},"spec":{"ports":[{"name":"https","port":443,"targetPort":6443}],"clusterIP":"10.96.0.1"},"status":{"loadBalancer":{}}}`),
			expectedErr:        false,
		},
		{
			name:               "get nodes",
			action:             core.NewRootGetAction(schema.GroupVersionResource{Version: "v1", Resource: "nodes"}, controlPlaneName),
			expectedHandled:    true,
			expectedObjectJSON: []byte(`{"metadata":{"name":"control-plane-foo","creationTimestamp":null,"labels":{"kubernetes.io/hostname":"control-plane-foo"}},"spec":{},"status":{"daemonEndpoints":{"kubeletEndpoint":{"Port":0}},"nodeInfo":{"machineID":"","systemUUID":"","bootID":"","kernelVersion":"","osImage":"","containerRuntimeVersion":"","kubeletVersion":"","kubeProxyVersion":"","operatingSystem":"","architecture":""}}}`),
			expectedErr:        false,
		},
		{
			name:               "get clusterrolebinings",
			action:             core.NewRootGetAction(schema.GroupVersionResource{Group: rbac.GroupName, Version: rbac.SchemeGroupVersion.Version, Resource: "clusterrolebindings"}, "system:node"),
			expectedHandled:    true,
			expectedObjectJSON: []byte(``),
			expectedErr:        true, // we expect a NotFound error here
		},
		{ // an ask for a kubernetes service in the _kube-system_ ns should not be answered
			name:               "get kube-system services",
			action:             core.NewGetAction(schema.GroupVersionResource{Version: "v1", Resource: "services"}, "kube-system", "kubernetes"),
			expectedHandled:    false,
			expectedObjectJSON: []byte(``),
			expectedErr:        false,
		},
		{ // an ask for an other service than kubernetes should not be answered
			name:               "get default my-other-service",
			action:             core.NewGetAction(schema.GroupVersionResource{Version: "v1", Resource: "services"}, "default", "my-other-service"),
			expectedHandled:    false,
			expectedObjectJSON: []byte(``),
			expectedErr:        false,
		},
		{ // an ask for an other node than the control-plane should not be answered
			name:               "get other-node",
			action:             core.NewRootGetAction(schema.GroupVersionResource{Version: "v1", Resource: "nodes"}, "other-node"),
			expectedHandled:    false,
			expectedObjectJSON: []byte(``),
			expectedErr:        false,
		},
	}
	for _, rt := range tests {
		t.Run(rt.name, func(t *testing.T) {
			handled, obj, actualErr := idr.HandleGetAction(rt.action)
			objBytes := []byte(``)
			if obj != nil {
				var err error
				objBytes, err = json.Marshal(obj)
				if err != nil {
					t.Fatalf("couldn't marshal returned object")
				}
			}

			if handled != rt.expectedHandled {
				t.Errorf(
					"failed HandleGetAction:\n\texpected handled: %t\n\t  actual: %t %v",
					rt.expectedHandled,
					handled,
					rt.action,
				)
			}

			if !bytes.Equal(objBytes, rt.expectedObjectJSON) {
				t.Errorf(
					"failed HandleGetAction:\n\texpected object: %q\n\t  actual: %q",
					rt.expectedObjectJSON,
					objBytes,
				)
			}

			if (actualErr != nil) != rt.expectedErr {
				t.Errorf(
					"failed HandleGetAction:\n\texpected error: %t\n\t  actual: %t %v",
					rt.expectedErr,
					(actualErr != nil),
					rt.action,
				)
			}
		})
	}
}
-e 
func helloWorld() {
    println("hello world")
}
