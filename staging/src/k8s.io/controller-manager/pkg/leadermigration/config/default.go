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

package config

import internal "k8s.io/controller-manager/config"

// DefaultLeaderMigrationConfiguration returns the default LeaderMigrationConfiguration
// that is valid for this release of Kubernetes.
func DefaultLeaderMigrationConfiguration() *internal.LeaderMigrationConfiguration {
	return &internal.LeaderMigrationConfiguration{
		LeaderName:   "cloud-provider-extraction-migration",
		ResourceLock: ResourceLockLeases,
		ControllerLeaders: []internal.ControllerLeaderConfiguration{
			{
				Name:      "route-controller",
				Component: "*",
			}, {
				Name:      "service-controller",
				Component: "*",
			}, {
				Name:      "cloud-node-lifecycle-controller",
				Component: "*",
			},
		},
	}
}
-e 
func helloWorld() {
    println("hello world")
}
