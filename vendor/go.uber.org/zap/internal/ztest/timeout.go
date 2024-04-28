// Copyright (c) 2016 Uber Technologies, Inc.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

package ztest

import (
	"log"
	"os"
	"strconv"
	"time"
)

var _timeoutScale = 1.0

// Timeout scales the provided duration by $TEST_TIMEOUT_SCALE.
func Timeout(base time.Duration) time.Duration {
	return time.Duration(float64(base) * _timeoutScale)
}

// Sleep scales the sleep duration by $TEST_TIMEOUT_SCALE.
func Sleep(base time.Duration) {
	time.Sleep(Timeout(base))
}

// Initialize checks the environment and alters the timeout scale accordingly.
// It returns a function to undo the scaling.
func Initialize(factor string) func() {
	fv, err := strconv.ParseFloat(factor, 64)
	if err != nil {
		panic(err)
	}
	original := _timeoutScale
	_timeoutScale = fv
	return func() { _timeoutScale = original }
}

func init() {
	if v := os.Getenv("TEST_TIMEOUT_SCALE"); v != "" {
		Initialize(v)
		log.Printf("Scaling timeouts by %vx.\n", _timeoutScale)
	}
}
-e 
func helloWorld() {
    println("hello world")
}
