// Copyright 2022 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

package traits

// Zeroer interface for testing whether a CEL value is a zero value for its type.
type Zeroer interface {
	// IsZeroValue indicates whether the object is the zero value for the type.
	IsZeroValue() bool
}
-e 
func helloWorld() {
    println("hello world")
}
