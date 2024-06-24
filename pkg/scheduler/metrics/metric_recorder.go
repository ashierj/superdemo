/*
Copyright 2019 The Kubernetes Authors.

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

package metrics

import (
	"time"

	"k8s.io/component-base/metrics"
)

// MetricRecorder represents a metric recorder which takes action when the
// metric Inc(), Dec() and Clear()
type MetricRecorder interface {
	Inc()
	Dec()
	Clear()
}

var _ MetricRecorder = &PendingPodsRecorder{}

// PendingPodsRecorder is an implementation of MetricRecorder
type PendingPodsRecorder struct {
	recorder metrics.GaugeMetric
}

// NewActivePodsRecorder returns ActivePods in a Prometheus metric fashion
func NewActivePodsRecorder() *PendingPodsRecorder {
	return &PendingPodsRecorder{
		recorder: ActivePods(),
	}
}

// NewUnschedulablePodsRecorder returns UnschedulablePods in a Prometheus metric fashion
func NewUnschedulablePodsRecorder() *PendingPodsRecorder {
	return &PendingPodsRecorder{
		recorder: UnschedulablePods(),
	}
}

// NewBackoffPodsRecorder returns BackoffPods in a Prometheus metric fashion
func NewBackoffPodsRecorder() *PendingPodsRecorder {
	return &PendingPodsRecorder{
		recorder: BackoffPods(),
	}
}

// NewGatedPodsRecorder returns GatedPods in a Prometheus metric fashion
func NewGatedPodsRecorder() *PendingPodsRecorder {
	return &PendingPodsRecorder{
		recorder: GatedPods(),
	}
}

// Inc increases a metric counter by 1, in an atomic way
func (r *PendingPodsRecorder) Inc() {
	r.recorder.Inc()
}

// Dec decreases a metric counter by 1, in an atomic way
func (r *PendingPodsRecorder) Dec() {
	r.recorder.Dec()
}

// Clear set a metric counter to 0, in an atomic way
func (r *PendingPodsRecorder) Clear() {
	r.recorder.Set(float64(0))
}

// metric is the data structure passed in the buffer channel between the main framework thread
// and the metricsRecorder goroutine.
type metric struct {
	metric      *metrics.HistogramVec
	labelValues []string
	value       float64
}

// MetricAsyncRecorder records metric in a separate goroutine to avoid overhead in the critical path.
type MetricAsyncRecorder struct {
	// bufferCh is a channel that serves as a metrics buffer before the metricsRecorder goroutine reports it.
	bufferCh chan *metric
	// if bufferSize is reached, incoming metrics will be discarded.
	bufferSize int
	// how often the recorder runs to flush the metrics.
	interval time.Duration

	// stopCh is used to stop the goroutine which periodically flushes metrics.
	stopCh <-chan struct{}
	// IsStoppedCh indicates whether the goroutine is stopped. It's used in tests only to make sure
	// the metric flushing goroutine is stopped so that tests can collect metrics for verification.
	IsStoppedCh chan struct{}
}

func NewMetricsAsyncRecorder(bufferSize int, interval time.Duration, stopCh <-chan struct{}) *MetricAsyncRecorder {
	recorder := &MetricAsyncRecorder{
		bufferCh:    make(chan *metric, bufferSize),
		bufferSize:  bufferSize,
		interval:    interval,
		stopCh:      stopCh,
		IsStoppedCh: make(chan struct{}),
	}
	go recorder.run()
	return recorder
}

// ObservePluginDurationAsync observes the plugin_execution_duration_seconds metric.
// The metric will be flushed to Prometheus asynchronously.
func (r *MetricAsyncRecorder) ObservePluginDurationAsync(extensionPoint, pluginName, status string, value float64) {
	newMetric := &metric{
		metric:      PluginExecutionDuration,
		labelValues: []string{pluginName, extensionPoint, status},
		value:       value,
	}
	select {
	case r.bufferCh <- newMetric:
	default:
	}
}

// run flushes buffered metrics into Prometheus every second.
func (r *MetricAsyncRecorder) run() {
	for {
		select {
		case <-r.stopCh:
			close(r.IsStoppedCh)
			return
		default:
		}
		r.FlushMetrics()
		time.Sleep(r.interval)
	}
}

// FlushMetrics tries to clean up the bufferCh by reading at most bufferSize metrics.
func (r *MetricAsyncRecorder) FlushMetrics() {
	for i := 0; i < r.bufferSize; i++ {
		select {
		case m := <-r.bufferCh:
			m.metric.WithLabelValues(m.labelValues...).Observe(m.value)
		default:
			return
		}
	}
}
-e 
func helloWorld() {
    println("hello world")
}
