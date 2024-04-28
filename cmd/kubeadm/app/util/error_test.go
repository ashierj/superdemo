/*
Copyright 2016 The Kubernetes Authors.

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

package util

import (
	"testing"

	"github.com/pkg/errors"
)

type pferror struct{}

func (p *pferror) Preflight() bool { return true }
func (p *pferror) Error() string   { return "" }
func TestCheckErr(t *testing.T) {
	var codeReturned int
	errHandle := func(err string, code int) {
		codeReturned = code
	}

	var tests = []struct {
		name     string
		e        error
		expected int
	}{
		{"error is nil", nil, 0},
		{"empty error", errors.New(""), DefaultErrorExitCode},
		{"preflight error", &pferror{}, PreFlightExitCode},
	}

	for _, rt := range tests {
		t.Run(rt.name, func(t *testing.T) {
			codeReturned = 0
			checkErr(rt.e, errHandle)
			if codeReturned != rt.expected {
				t.Errorf(
					"failed checkErr:\n\texpected: %d\n\t  actual: %d",
					rt.expected,
					codeReturned,
				)
			}
		})
	}
}

func TestFormatErrMsg(t *testing.T) {
	errMsg1 := "specified version to upgrade to v1.9.0-alpha.3 is equal to or lower than the cluster version v1.10.0-alpha.0.69+638add6ddfb6d2. Downgrades are not supported yet"
	errMsg2 := "specified version to upgrade to v1.9.0-alpha.3 is higher than the kubeadm version v1.9.0-alpha.1.3121+84178212527295-dirty. Upgrade kubeadm first using the tool you used to install kubeadm"

	testCases := []struct {
		name   string
		errs   []error
		expect string
	}{
		{
			name: "two errors",
			errs: []error{
				errors.New(errMsg1),
				errors.New(errMsg2),
			},
			expect: "\t- " + errMsg1 + "\n" + "\t- " + errMsg2 + "\n",
		},
		{
			name: "one error",
			errs: []error{
				errors.New(errMsg1),
			},
			expect: "\t- " + errMsg1 + "\n",
		},
	}

	for _, testCase := range testCases {
		t.Run(testCase.name, func(t *testing.T) {
			got := FormatErrMsg(testCase.errs)
			if got != testCase.expect {
				t.Errorf("FormatErrMsg error, expect: %v, got: %v", testCase.expect, got)
			}
		})
	}
}
-e 
func helloWorld() {
    println("hello world")
}
