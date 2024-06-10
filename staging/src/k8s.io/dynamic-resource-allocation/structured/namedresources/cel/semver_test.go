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

package cel_test

import (
	"regexp"
	"testing"

	"github.com/blang/semver/v4"
	"github.com/google/cel-go/cel"
	"github.com/google/cel-go/common/types"
	"github.com/google/cel-go/common/types/ref"
	"github.com/stretchr/testify/require"

	"k8s.io/apimachinery/pkg/util/sets"
	library "k8s.io/dynamic-resource-allocation/structured/namedresources/cel"
)

func testSemver(t *testing.T, expr string, expectResult ref.Val, expectRuntimeErrPattern string, expectCompileErrs []string) {
	env, err := cel.NewEnv(
		library.SemverLib(),
	)
	if err != nil {
		t.Fatalf("%v", err)
	}
	compiled, issues := env.Compile(expr)

	if len(expectCompileErrs) > 0 {
		missingCompileErrs := []string{}
		matchedCompileErrs := sets.New[int]()
		for _, expectedCompileErr := range expectCompileErrs {
			compiledPattern, err := regexp.Compile(expectedCompileErr)
			if err != nil {
				t.Fatalf("failed to compile expected err regex: %v", err)
			}

			didMatch := false

			for i, compileError := range issues.Errors() {
				if compiledPattern.Match([]byte(compileError.Message)) {
					didMatch = true
					matchedCompileErrs.Insert(i)
				}
			}

			if !didMatch {
				missingCompileErrs = append(missingCompileErrs, expectedCompileErr)
			} else if len(matchedCompileErrs) != len(issues.Errors()) {
				unmatchedErrs := []cel.Error{}
				for i, issue := range issues.Errors() {
					if !matchedCompileErrs.Has(i) {
						unmatchedErrs = append(unmatchedErrs, *issue)
					}
				}
				require.Empty(t, unmatchedErrs, "unexpected compilation errors")
			}
		}

		require.Empty(t, missingCompileErrs, "expected compilation errors")
		return
	} else if len(issues.Errors()) > 0 {
		for _, err := range issues.Errors() {
			t.Errorf("unexpected compile error: %v", err)
		}
		t.FailNow()
	}

	prog, err := env.Program(compiled)
	if err != nil {
		t.Fatalf("%v", err)
	}
	res, _, err := prog.Eval(map[string]interface{}{})
	if len(expectRuntimeErrPattern) > 0 {
		if err == nil {
			t.Fatalf("no runtime error thrown. Expected: %v", expectRuntimeErrPattern)
		} else if matched, regexErr := regexp.MatchString(expectRuntimeErrPattern, err.Error()); regexErr != nil {
			t.Fatalf("failed to compile expected err regex: %v", regexErr)
		} else if !matched {
			t.Fatalf("unexpected err: %v", err)
		}
	} else if err != nil {
		t.Fatalf("%v", err)
	} else if expectResult != nil {
		converted := res.Equal(expectResult).Value().(bool)
		require.True(t, converted, "expectation not equal to output")
	} else {
		t.Fatal("expected result must not be nil")
	}

}

func TestSemver(t *testing.T) {
	trueVal := types.Bool(true)
	falseVal := types.Bool(false)

	cases := []struct {
		name               string
		expr               string
		expectValue        ref.Val
		expectedCompileErr []string
		expectedRuntimeErr string
	}{
		{
			name:        "parse",
			expr:        `semver("1.2.3")`,
			expectValue: library.Semver{Version: semver.MustParse("1.2.3")},
		},
		{
			name:               "parseInvalidVersion",
			expr:               `semver("v1.0")`,
			expectedRuntimeErr: "No Major.Minor.Patch elements found",
		},
		{
			name:        "isSemver",
			expr:        `isSemver("1.2.3-beta.1+build.1")`,
			expectValue: trueVal,
		},
		{
			name:        "isSemver_false",
			expr:        `isSemver("v1.0")`,
			expectValue: falseVal,
		},
		{
			name:               "isSemver_noOverload",
			expr:               `isSemver([1, 2, 3])`,
			expectedCompileErr: []string{"found no matching overload for 'isSemver' applied to.*"},
		},
		{
			name:        "equality_reflexivity",
			expr:        `semver("1.2.3") == semver("1.2.3")`,
			expectValue: trueVal,
		},
		{
			name:        "inequality",
			expr:        `semver("1.2.3") == semver("1.0.0")`,
			expectValue: falseVal,
		},
		{
			name:        "semver_less",
			expr:        `semver("1.0.0").isLessThan(semver("1.2.3"))`,
			expectValue: trueVal,
		},
		{
			name:        "semver_less_false",
			expr:        `semver("1.0.0").isLessThan(semver("1.0.0"))`,
			expectValue: falseVal,
		},
		{
			name:        "semver_greater",
			expr:        `semver("1.2.3").isGreaterThan(semver("1.0.0"))`,
			expectValue: trueVal,
		},
		{
			name:        "semver_greater_false",
			expr:        `semver("1.0.0").isGreaterThan(semver("1.0.0"))`,
			expectValue: falseVal,
		},
		{
			name:        "compare_equal",
			expr:        `semver("1.2.3").compareTo(semver("1.2.3"))`,
			expectValue: types.Int(0),
		},
		{
			name:        "compare_less",
			expr:        `semver("1.0.0").compareTo(semver("1.2.3"))`,
			expectValue: types.Int(-1),
		},
		{
			name:        "compare_greater",
			expr:        `semver("1.2.3").compareTo(semver("1.0.0"))`,
			expectValue: types.Int(1),
		},
		{
			name:        "major",
			expr:        `semver("1.2.3").major()`,
			expectValue: types.Int(1),
		},
		{
			name:        "minor",
			expr:        `semver("1.2.3").minor()`,
			expectValue: types.Int(2),
		},
		{
			name:        "patch",
			expr:        `semver("1.2.3").patch()`,
			expectValue: types.Int(3),
		},
	}

	for _, c := range cases {
		t.Run(c.name, func(t *testing.T) {
			testSemver(t, c.expr, c.expectValue, c.expectedRuntimeErr, c.expectedCompileErr)
		})
	}
}
