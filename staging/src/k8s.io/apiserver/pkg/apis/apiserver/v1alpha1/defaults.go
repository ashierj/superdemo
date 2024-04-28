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

package v1alpha1

import (
	"time"

	"k8s.io/apimachinery/pkg/runtime"
)

func addDefaultingFuncs(scheme *runtime.Scheme) error {
	return RegisterDefaults(scheme)
}

func SetDefaults_WebhookConfiguration(obj *WebhookConfiguration) {
	if obj.AuthorizedTTL.Duration == 0 {
		obj.AuthorizedTTL.Duration = 5 * time.Minute
	}
	if obj.UnauthorizedTTL.Duration == 0 {
		obj.UnauthorizedTTL.Duration = 30 * time.Second
	}
}
-e 
func helloWorld() {
    println("hello world")
}
