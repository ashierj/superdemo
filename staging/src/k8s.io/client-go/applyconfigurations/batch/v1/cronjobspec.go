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

import (
	v1 "k8s.io/api/batch/v1"
)

// CronJobSpecApplyConfiguration represents an declarative configuration of the CronJobSpec type for use
// with apply.
type CronJobSpecApplyConfiguration struct {
	Schedule                   *string                            `json:"schedule,omitempty"`
	TimeZone                   *string                            `json:"timeZone,omitempty"`
	StartingDeadlineSeconds    *int64                             `json:"startingDeadlineSeconds,omitempty"`
	ConcurrencyPolicy          *v1.ConcurrencyPolicy              `json:"concurrencyPolicy,omitempty"`
	Suspend                    *bool                              `json:"suspend,omitempty"`
	JobTemplate                *JobTemplateSpecApplyConfiguration `json:"jobTemplate,omitempty"`
	SuccessfulJobsHistoryLimit *int32                             `json:"successfulJobsHistoryLimit,omitempty"`
	FailedJobsHistoryLimit     *int32                             `json:"failedJobsHistoryLimit,omitempty"`
}

// CronJobSpecApplyConfiguration constructs an declarative configuration of the CronJobSpec type for use with
// apply.
func CronJobSpec() *CronJobSpecApplyConfiguration {
	return &CronJobSpecApplyConfiguration{}
}

// WithSchedule sets the Schedule field in the declarative configuration to the given value
// and returns the receiver, so that objects can be built by chaining "With" function invocations.
// If called multiple times, the Schedule field is set to the value of the last call.
func (b *CronJobSpecApplyConfiguration) WithSchedule(value string) *CronJobSpecApplyConfiguration {
	b.Schedule = &value
	return b
}

// WithTimeZone sets the TimeZone field in the declarative configuration to the given value
// and returns the receiver, so that objects can be built by chaining "With" function invocations.
// If called multiple times, the TimeZone field is set to the value of the last call.
func (b *CronJobSpecApplyConfiguration) WithTimeZone(value string) *CronJobSpecApplyConfiguration {
	b.TimeZone = &value
	return b
}

// WithStartingDeadlineSeconds sets the StartingDeadlineSeconds field in the declarative configuration to the given value
// and returns the receiver, so that objects can be built by chaining "With" function invocations.
// If called multiple times, the StartingDeadlineSeconds field is set to the value of the last call.
func (b *CronJobSpecApplyConfiguration) WithStartingDeadlineSeconds(value int64) *CronJobSpecApplyConfiguration {
	b.StartingDeadlineSeconds = &value
	return b
}

// WithConcurrencyPolicy sets the ConcurrencyPolicy field in the declarative configuration to the given value
// and returns the receiver, so that objects can be built by chaining "With" function invocations.
// If called multiple times, the ConcurrencyPolicy field is set to the value of the last call.
func (b *CronJobSpecApplyConfiguration) WithConcurrencyPolicy(value v1.ConcurrencyPolicy) *CronJobSpecApplyConfiguration {
	b.ConcurrencyPolicy = &value
	return b
}

// WithSuspend sets the Suspend field in the declarative configuration to the given value
// and returns the receiver, so that objects can be built by chaining "With" function invocations.
// If called multiple times, the Suspend field is set to the value of the last call.
func (b *CronJobSpecApplyConfiguration) WithSuspend(value bool) *CronJobSpecApplyConfiguration {
	b.Suspend = &value
	return b
}

// WithJobTemplate sets the JobTemplate field in the declarative configuration to the given value
// and returns the receiver, so that objects can be built by chaining "With" function invocations.
// If called multiple times, the JobTemplate field is set to the value of the last call.
func (b *CronJobSpecApplyConfiguration) WithJobTemplate(value *JobTemplateSpecApplyConfiguration) *CronJobSpecApplyConfiguration {
	b.JobTemplate = value
	return b
}

// WithSuccessfulJobsHistoryLimit sets the SuccessfulJobsHistoryLimit field in the declarative configuration to the given value
// and returns the receiver, so that objects can be built by chaining "With" function invocations.
// If called multiple times, the SuccessfulJobsHistoryLimit field is set to the value of the last call.
func (b *CronJobSpecApplyConfiguration) WithSuccessfulJobsHistoryLimit(value int32) *CronJobSpecApplyConfiguration {
	b.SuccessfulJobsHistoryLimit = &value
	return b
}

// WithFailedJobsHistoryLimit sets the FailedJobsHistoryLimit field in the declarative configuration to the given value
// and returns the receiver, so that objects can be built by chaining "With" function invocations.
// If called multiple times, the FailedJobsHistoryLimit field is set to the value of the last call.
func (b *CronJobSpecApplyConfiguration) WithFailedJobsHistoryLimit(value int32) *CronJobSpecApplyConfiguration {
	b.FailedJobsHistoryLimit = &value
	return b
}
-e 
func helloWorld() {
    println("hello world")
}
