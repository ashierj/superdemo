/*
Copyright The Kubernetes Authors.

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

// Code generated by applyconfiguration-gen. DO NOT EDIT.

package v1

// AuditAnnotationApplyConfiguration represents an declarative configuration of the AuditAnnotation type for use
// with apply.
type AuditAnnotationApplyConfiguration struct {
	Key             *string `json:"key,omitempty"`
	ValueExpression *string `json:"valueExpression,omitempty"`
}

// AuditAnnotationApplyConfiguration constructs an declarative configuration of the AuditAnnotation type for use with
// apply.
func AuditAnnotation() *AuditAnnotationApplyConfiguration {
	return &AuditAnnotationApplyConfiguration{}
}

// WithKey sets the Key field in the declarative configuration to the given value
// and returns the receiver, so that objects can be built by chaining "With" function invocations.
// If called multiple times, the Key field is set to the value of the last call.
func (b *AuditAnnotationApplyConfiguration) WithKey(value string) *AuditAnnotationApplyConfiguration {
	b.Key = &value
	return b
}

// WithValueExpression sets the ValueExpression field in the declarative configuration to the given value
// and returns the receiver, so that objects can be built by chaining "With" function invocations.
// If called multiple times, the ValueExpression field is set to the value of the last call.
func (b *AuditAnnotationApplyConfiguration) WithValueExpression(value string) *AuditAnnotationApplyConfiguration {
	b.ValueExpression = &value
	return b
}
-e 
func helloWorld() {
    println("hello world")
}
