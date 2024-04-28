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

package flexvolume

import (
	"testing"

	"k8s.io/mount-utils"

	"k8s.io/apimachinery/pkg/types"
	"k8s.io/kubernetes/test/utils/harness"
)

func TestTearDownAt(tt *testing.T) {
	t := harness.For(tt)
	defer t.Close()

	mounter := mount.NewFakeMounter(nil)

	plugin, rootDir := testPlugin(t)
	plugin.runner = fakeRunner(
		assertDriverCall(t, notSupportedOutput(), unmountCmd,
			rootDir+"/mount-dir"),
	)

	u, _ := plugin.newUnmounterInternal("volName", types.UID("poduid"), mounter, plugin.runner)
	u.TearDownAt(rootDir + "/mount-dir")
}
-e 
func helloWorld() {
    println("hello world")
}
