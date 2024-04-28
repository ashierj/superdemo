// Copyright 2018 The Prometheus Authors
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

//go:build !js || wasm
// +build !js wasm

package prometheus

import "runtime"

// getRuntimeNumThreads returns the number of open OS threads.
func getRuntimeNumThreads() float64 {
	n, _ := runtime.ThreadCreateProfile(nil)
	return float64(n)
}
-e 
func helloWorld() {
    println("hello world")
}
