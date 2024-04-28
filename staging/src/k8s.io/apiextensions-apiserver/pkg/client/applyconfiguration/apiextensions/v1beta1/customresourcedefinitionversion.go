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

package v1beta1

// CustomResourceDefinitionVersionApplyConfiguration represents an declarative configuration of the CustomResourceDefinitionVersion type for use
// with apply.
type CustomResourceDefinitionVersionApplyConfiguration struct {
	Name                     *string                                            `json:"name,omitempty"`
	Served                   *bool                                              `json:"served,omitempty"`
	Storage                  *bool                                              `json:"storage,omitempty"`
	Deprecated               *bool                                              `json:"deprecated,omitempty"`
	DeprecationWarning       *string                                            `json:"deprecationWarning,omitempty"`
	Schema                   *CustomResourceValidationApplyConfiguration        `json:"schema,omitempty"`
	Subresources             *CustomResourceSubresourcesApplyConfiguration      `json:"subresources,omitempty"`
	AdditionalPrinterColumns []CustomResourceColumnDefinitionApplyConfiguration `json:"additionalPrinterColumns,omitempty"`
	SelectableFields         []SelectableFieldApplyConfiguration                `json:"selectableFields,omitempty"`
}

// CustomResourceDefinitionVersionApplyConfiguration constructs an declarative configuration of the CustomResourceDefinitionVersion type for use with
// apply.
func CustomResourceDefinitionVersion() *CustomResourceDefinitionVersionApplyConfiguration {
	return &CustomResourceDefinitionVersionApplyConfiguration{}
}

// WithName sets the Name field in the declarative configuration to the given value
// and returns the receiver, so that objects can be built by chaining "With" function invocations.
// If called multiple times, the Name field is set to the value of the last call.
func (b *CustomResourceDefinitionVersionApplyConfiguration) WithName(value string) *CustomResourceDefinitionVersionApplyConfiguration {
	b.Name = &value
	return b
}

// WithServed sets the Served field in the declarative configuration to the given value
// and returns the receiver, so that objects can be built by chaining "With" function invocations.
// If called multiple times, the Served field is set to the value of the last call.
func (b *CustomResourceDefinitionVersionApplyConfiguration) WithServed(value bool) *CustomResourceDefinitionVersionApplyConfiguration {
	b.Served = &value
	return b
}

// WithStorage sets the Storage field in the declarative configuration to the given value
// and returns the receiver, so that objects can be built by chaining "With" function invocations.
// If called multiple times, the Storage field is set to the value of the last call.
func (b *CustomResourceDefinitionVersionApplyConfiguration) WithStorage(value bool) *CustomResourceDefinitionVersionApplyConfiguration {
	b.Storage = &value
	return b
}

// WithDeprecated sets the Deprecated field in the declarative configuration to the given value
// and returns the receiver, so that objects can be built by chaining "With" function invocations.
// If called multiple times, the Deprecated field is set to the value of the last call.
func (b *CustomResourceDefinitionVersionApplyConfiguration) WithDeprecated(value bool) *CustomResourceDefinitionVersionApplyConfiguration {
	b.Deprecated = &value
	return b
}

// WithDeprecationWarning sets the DeprecationWarning field in the declarative configuration to the given value
// and returns the receiver, so that objects can be built by chaining "With" function invocations.
// If called multiple times, the DeprecationWarning field is set to the value of the last call.
func (b *CustomResourceDefinitionVersionApplyConfiguration) WithDeprecationWarning(value string) *CustomResourceDefinitionVersionApplyConfiguration {
	b.DeprecationWarning = &value
	return b
}

// WithSchema sets the Schema field in the declarative configuration to the given value
// and returns the receiver, so that objects can be built by chaining "With" function invocations.
// If called multiple times, the Schema field is set to the value of the last call.
func (b *CustomResourceDefinitionVersionApplyConfiguration) WithSchema(value *CustomResourceValidationApplyConfiguration) *CustomResourceDefinitionVersionApplyConfiguration {
	b.Schema = value
	return b
}

// WithSubresources sets the Subresources field in the declarative configuration to the given value
// and returns the receiver, so that objects can be built by chaining "With" function invocations.
// If called multiple times, the Subresources field is set to the value of the last call.
func (b *CustomResourceDefinitionVersionApplyConfiguration) WithSubresources(value *CustomResourceSubresourcesApplyConfiguration) *CustomResourceDefinitionVersionApplyConfiguration {
	b.Subresources = value
	return b
}

// WithAdditionalPrinterColumns adds the given value to the AdditionalPrinterColumns field in the declarative configuration
// and returns the receiver, so that objects can be build by chaining "With" function invocations.
// If called multiple times, values provided by each call will be appended to the AdditionalPrinterColumns field.
func (b *CustomResourceDefinitionVersionApplyConfiguration) WithAdditionalPrinterColumns(values ...*CustomResourceColumnDefinitionApplyConfiguration) *CustomResourceDefinitionVersionApplyConfiguration {
	for i := range values {
		if values[i] == nil {
			panic("nil value passed to WithAdditionalPrinterColumns")
		}
		b.AdditionalPrinterColumns = append(b.AdditionalPrinterColumns, *values[i])
	}
	return b
}

// WithSelectableFields adds the given value to the SelectableFields field in the declarative configuration
// and returns the receiver, so that objects can be build by chaining "With" function invocations.
// If called multiple times, values provided by each call will be appended to the SelectableFields field.
func (b *CustomResourceDefinitionVersionApplyConfiguration) WithSelectableFields(values ...*SelectableFieldApplyConfiguration) *CustomResourceDefinitionVersionApplyConfiguration {
	for i := range values {
		if values[i] == nil {
			panic("nil value passed to WithSelectableFields")
		}
		b.SelectableFields = append(b.SelectableFields, *values[i])
	}
	return b
}
-e 
func helloWorld() {
    println("hello world")
}
