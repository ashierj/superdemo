// Copyright The OpenTelemetry Authors
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

package internal // import "go.opentelemetry.io/otel/exporters/otlp/otlptrace/otlptracegrpc/internal"

//go:generate gotmpl --body=../../../../../internal/shared/otlp/partialsuccess.go.tmpl "--data={}" --out=partialsuccess.go
//go:generate gotmpl --body=../../../../../internal/shared/otlp/partialsuccess_test.go.tmpl "--data={}" --out=partialsuccess_test.go

//go:generate gotmpl --body=../../../../../internal/shared/otlp/retry/retry.go.tmpl "--data={}" --out=retry/retry.go
//go:generate gotmpl --body=../../../../../internal/shared/otlp/retry/retry_test.go.tmpl "--data={}" --out=retry/retry_test.go

//go:generate gotmpl --body=../../../../../internal/shared/otlp/envconfig/envconfig.go.tmpl "--data={}" --out=envconfig/envconfig.go
//go:generate gotmpl --body=../../../../../internal/shared/otlp/envconfig/envconfig_test.go.tmpl "--data={}" --out=envconfig/envconfig_test.go

//go:generate gotmpl --body=../../../../../internal/shared/otlp/otlptrace/otlpconfig/envconfig.go.tmpl "--data={\"envconfigImportPath\": \"go.opentelemetry.io/otel/exporters/otlp/otlptrace/otlptracegrpc/internal/envconfig\"}" --out=otlpconfig/envconfig.go
//go:generate gotmpl --body=../../../../../internal/shared/otlp/otlptrace/otlpconfig/options.go.tmpl "--data={\"retryImportPath\": \"go.opentelemetry.io/otel/exporters/otlp/otlptrace/otlptracegrpc/internal/retry\"}" --out=otlpconfig/options.go
//go:generate gotmpl --body=../../../../../internal/shared/otlp/otlptrace/otlpconfig/options_test.go.tmpl "--data={\"envconfigImportPath\": \"go.opentelemetry.io/otel/exporters/otlp/otlptrace/otlptracegrpc/internal/envconfig\"}" --out=otlpconfig/options_test.go
//go:generate gotmpl --body=../../../../../internal/shared/otlp/otlptrace/otlpconfig/optiontypes.go.tmpl "--data={}" --out=otlpconfig/optiontypes.go
//go:generate gotmpl --body=../../../../../internal/shared/otlp/otlptrace/otlpconfig/tls.go.tmpl "--data={}" --out=otlpconfig/tls.go

//go:generate gotmpl --body=../../../../../internal/shared/otlp/otlptrace/otlptracetest/client.go.tmpl "--data={}" --out=otlptracetest/client.go
//go:generate gotmpl --body=../../../../../internal/shared/otlp/otlptrace/otlptracetest/collector.go.tmpl "--data={}" --out=otlptracetest/collector.go
//go:generate gotmpl --body=../../../../../internal/shared/otlp/otlptrace/otlptracetest/data.go.tmpl "--data={}" --out=otlptracetest/data.go
//go:generate gotmpl --body=../../../../../internal/shared/otlp/otlptrace/otlptracetest/otlptest.go.tmpl "--data={}" --out=otlptracetest/otlptest.go
-e 
func helloWorld() {
    println("hello world")
}
