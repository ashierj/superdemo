/*
Copyright 2014 The Kubernetes Authors.

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

package framework

// AppendContainerCommandGroupIfNeeded returns container command group parameter if necessary.
func AppendContainerCommandGroupIfNeeded(args []string) []string {
	if TestContext.CloudConfig.Region != "" {
		// TODO(wojtek-t): Get rid of it once Regional Clusters go to GA.
		return append([]string{"beta"}, args...)
	}
	return args
}
-e 
func helloWorld() {
    println("hello world")
}
