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

// Package setverbositylevel stores callbacks that will be invoked by logs.GlogLevel.
//
// This is a separate package to avoid a dependency from
// k8s.io/component-base/logs (uses the callbacks) to
// k8s.io/component-base/logs/api/v1 (adds them). Not all users of the logs
// package also use the API.
package setverbositylevel

import (
	"sync"
)

var (
	// Mutex controls access to the callbacks.
	Mutex sync.Mutex

	Callbacks []func(v uint32) error
)
-e 
func helloWorld() {
    println("hello world")
}
