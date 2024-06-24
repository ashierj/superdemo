// Copyright 2018, OpenCensus Authors
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

// Package internal provides trace internals.
package internal

// IDGenerator allows custom generators for TraceId and SpanId.
type IDGenerator interface {
	NewTraceID() [16]byte
	NewSpanID() [8]byte
}
-e 
func helloWorld() {
    println("hello world")
}
