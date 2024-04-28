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

import (
	v1beta1 "k8s.io/apiextensions-apiserver/pkg/apis/apiextensions/v1beta1"
)

// JSONSchemaPropsApplyConfiguration represents an declarative configuration of the JSONSchemaProps type for use
// with apply.
type JSONSchemaPropsApplyConfiguration struct {
	ID                     *string                                      `json:"id,omitempty"`
	Schema                 *v1beta1.JSONSchemaURL                       `json:"$schema,omitempty"`
	Ref                    *string                                      `json:"$ref,omitempty"`
	Description            *string                                      `json:"description,omitempty"`
	Type                   *string                                      `json:"type,omitempty"`
	Format                 *string                                      `json:"format,omitempty"`
	Title                  *string                                      `json:"title,omitempty"`
	Default                *v1beta1.JSON                                `json:"default,omitempty"`
	Maximum                *float64                                     `json:"maximum,omitempty"`
	ExclusiveMaximum       *bool                                        `json:"exclusiveMaximum,omitempty"`
	Minimum                *float64                                     `json:"minimum,omitempty"`
	ExclusiveMinimum       *bool                                        `json:"exclusiveMinimum,omitempty"`
	MaxLength              *int64                                       `json:"maxLength,omitempty"`
	MinLength              *int64                                       `json:"minLength,omitempty"`
	Pattern                *string                                      `json:"pattern,omitempty"`
	MaxItems               *int64                                       `json:"maxItems,omitempty"`
	MinItems               *int64                                       `json:"minItems,omitempty"`
	UniqueItems            *bool                                        `json:"uniqueItems,omitempty"`
	MultipleOf             *float64                                     `json:"multipleOf,omitempty"`
	Enum                   []v1beta1.JSON                               `json:"enum,omitempty"`
	MaxProperties          *int64                                       `json:"maxProperties,omitempty"`
	MinProperties          *int64                                       `json:"minProperties,omitempty"`
	Required               []string                                     `json:"required,omitempty"`
	Items                  *v1beta1.JSONSchemaPropsOrArray              `json:"items,omitempty"`
	AllOf                  []JSONSchemaPropsApplyConfiguration          `json:"allOf,omitempty"`
	OneOf                  []JSONSchemaPropsApplyConfiguration          `json:"oneOf,omitempty"`
	AnyOf                  []JSONSchemaPropsApplyConfiguration          `json:"anyOf,omitempty"`
	Not                    *JSONSchemaPropsApplyConfiguration           `json:"not,omitempty"`
	Properties             map[string]JSONSchemaPropsApplyConfiguration `json:"properties,omitempty"`
	AdditionalProperties   *v1beta1.JSONSchemaPropsOrBool               `json:"additionalProperties,omitempty"`
	PatternProperties      map[string]JSONSchemaPropsApplyConfiguration `json:"patternProperties,omitempty"`
	Dependencies           *v1beta1.JSONSchemaDependencies              `json:"dependencies,omitempty"`
	AdditionalItems        *v1beta1.JSONSchemaPropsOrBool               `json:"additionalItems,omitempty"`
	Definitions            *v1beta1.JSONSchemaDefinitions               `json:"definitions,omitempty"`
	ExternalDocs           *ExternalDocumentationApplyConfiguration     `json:"externalDocs,omitempty"`
	Example                *v1beta1.JSON                                `json:"example,omitempty"`
	Nullable               *bool                                        `json:"nullable,omitempty"`
	XPreserveUnknownFields *bool                                        `json:"x-kubernetes-preserve-unknown-fields,omitempty"`
	XEmbeddedResource      *bool                                        `json:"x-kubernetes-embedded-resource,omitempty"`
	XIntOrString           *bool                                        `json:"x-kubernetes-int-or-string,omitempty"`
	XListMapKeys           []string                                     `json:"x-kubernetes-list-map-keys,omitempty"`
	XListType              *string                                      `json:"x-kubernetes-list-type,omitempty"`
	XMapType               *string                                      `json:"x-kubernetes-map-type,omitempty"`
	XValidations           *v1beta1.ValidationRules                     `json:"x-kubernetes-validations,omitempty"`
}

// JSONSchemaPropsApplyConfiguration constructs an declarative configuration of the JSONSchemaProps type for use with
// apply.
func JSONSchemaProps() *JSONSchemaPropsApplyConfiguration {
	return &JSONSchemaPropsApplyConfiguration{}
}

// WithID sets the ID field in the declarative configuration to the given value
// and returns the receiver, so that objects can be built by chaining "With" function invocations.
// If called multiple times, the ID field is set to the value of the last call.
func (b *JSONSchemaPropsApplyConfiguration) WithID(value string) *JSONSchemaPropsApplyConfiguration {
	b.ID = &value
	return b
}

// WithSchema sets the Schema field in the declarative configuration to the given value
// and returns the receiver, so that objects can be built by chaining "With" function invocations.
// If called multiple times, the Schema field is set to the value of the last call.
func (b *JSONSchemaPropsApplyConfiguration) WithSchema(value v1beta1.JSONSchemaURL) *JSONSchemaPropsApplyConfiguration {
	b.Schema = &value
	return b
}

// WithRef sets the Ref field in the declarative configuration to the given value
// and returns the receiver, so that objects can be built by chaining "With" function invocations.
// If called multiple times, the Ref field is set to the value of the last call.
func (b *JSONSchemaPropsApplyConfiguration) WithRef(value string) *JSONSchemaPropsApplyConfiguration {
	b.Ref = &value
	return b
}

// WithDescription sets the Description field in the declarative configuration to the given value
// and returns the receiver, so that objects can be built by chaining "With" function invocations.
// If called multiple times, the Description field is set to the value of the last call.
func (b *JSONSchemaPropsApplyConfiguration) WithDescription(value string) *JSONSchemaPropsApplyConfiguration {
	b.Description = &value
	return b
}

// WithType sets the Type field in the declarative configuration to the given value
// and returns the receiver, so that objects can be built by chaining "With" function invocations.
// If called multiple times, the Type field is set to the value of the last call.
func (b *JSONSchemaPropsApplyConfiguration) WithType(value string) *JSONSchemaPropsApplyConfiguration {
	b.Type = &value
	return b
}

// WithFormat sets the Format field in the declarative configuration to the given value
// and returns the receiver, so that objects can be built by chaining "With" function invocations.
// If called multiple times, the Format field is set to the value of the last call.
func (b *JSONSchemaPropsApplyConfiguration) WithFormat(value string) *JSONSchemaPropsApplyConfiguration {
	b.Format = &value
	return b
}

// WithTitle sets the Title field in the declarative configuration to the given value
// and returns the receiver, so that objects can be built by chaining "With" function invocations.
// If called multiple times, the Title field is set to the value of the last call.
func (b *JSONSchemaPropsApplyConfiguration) WithTitle(value string) *JSONSchemaPropsApplyConfiguration {
	b.Title = &value
	return b
}

// WithDefault sets the Default field in the declarative configuration to the given value
// and returns the receiver, so that objects can be built by chaining "With" function invocations.
// If called multiple times, the Default field is set to the value of the last call.
func (b *JSONSchemaPropsApplyConfiguration) WithDefault(value v1beta1.JSON) *JSONSchemaPropsApplyConfiguration {
	b.Default = &value
	return b
}

// WithMaximum sets the Maximum field in the declarative configuration to the given value
// and returns the receiver, so that objects can be built by chaining "With" function invocations.
// If called multiple times, the Maximum field is set to the value of the last call.
func (b *JSONSchemaPropsApplyConfiguration) WithMaximum(value float64) *JSONSchemaPropsApplyConfiguration {
	b.Maximum = &value
	return b
}

// WithExclusiveMaximum sets the ExclusiveMaximum field in the declarative configuration to the given value
// and returns the receiver, so that objects can be built by chaining "With" function invocations.
// If called multiple times, the ExclusiveMaximum field is set to the value of the last call.
func (b *JSONSchemaPropsApplyConfiguration) WithExclusiveMaximum(value bool) *JSONSchemaPropsApplyConfiguration {
	b.ExclusiveMaximum = &value
	return b
}

// WithMinimum sets the Minimum field in the declarative configuration to the given value
// and returns the receiver, so that objects can be built by chaining "With" function invocations.
// If called multiple times, the Minimum field is set to the value of the last call.
func (b *JSONSchemaPropsApplyConfiguration) WithMinimum(value float64) *JSONSchemaPropsApplyConfiguration {
	b.Minimum = &value
	return b
}

// WithExclusiveMinimum sets the ExclusiveMinimum field in the declarative configuration to the given value
// and returns the receiver, so that objects can be built by chaining "With" function invocations.
// If called multiple times, the ExclusiveMinimum field is set to the value of the last call.
func (b *JSONSchemaPropsApplyConfiguration) WithExclusiveMinimum(value bool) *JSONSchemaPropsApplyConfiguration {
	b.ExclusiveMinimum = &value
	return b
}

// WithMaxLength sets the MaxLength field in the declarative configuration to the given value
// and returns the receiver, so that objects can be built by chaining "With" function invocations.
// If called multiple times, the MaxLength field is set to the value of the last call.
func (b *JSONSchemaPropsApplyConfiguration) WithMaxLength(value int64) *JSONSchemaPropsApplyConfiguration {
	b.MaxLength = &value
	return b
}

// WithMinLength sets the MinLength field in the declarative configuration to the given value
// and returns the receiver, so that objects can be built by chaining "With" function invocations.
// If called multiple times, the MinLength field is set to the value of the last call.
func (b *JSONSchemaPropsApplyConfiguration) WithMinLength(value int64) *JSONSchemaPropsApplyConfiguration {
	b.MinLength = &value
	return b
}

// WithPattern sets the Pattern field in the declarative configuration to the given value
// and returns the receiver, so that objects can be built by chaining "With" function invocations.
// If called multiple times, the Pattern field is set to the value of the last call.
func (b *JSONSchemaPropsApplyConfiguration) WithPattern(value string) *JSONSchemaPropsApplyConfiguration {
	b.Pattern = &value
	return b
}

// WithMaxItems sets the MaxItems field in the declarative configuration to the given value
// and returns the receiver, so that objects can be built by chaining "With" function invocations.
// If called multiple times, the MaxItems field is set to the value of the last call.
func (b *JSONSchemaPropsApplyConfiguration) WithMaxItems(value int64) *JSONSchemaPropsApplyConfiguration {
	b.MaxItems = &value
	return b
}

// WithMinItems sets the MinItems field in the declarative configuration to the given value
// and returns the receiver, so that objects can be built by chaining "With" function invocations.
// If called multiple times, the MinItems field is set to the value of the last call.
func (b *JSONSchemaPropsApplyConfiguration) WithMinItems(value int64) *JSONSchemaPropsApplyConfiguration {
	b.MinItems = &value
	return b
}

// WithUniqueItems sets the UniqueItems field in the declarative configuration to the given value
// and returns the receiver, so that objects can be built by chaining "With" function invocations.
// If called multiple times, the UniqueItems field is set to the value of the last call.
func (b *JSONSchemaPropsApplyConfiguration) WithUniqueItems(value bool) *JSONSchemaPropsApplyConfiguration {
	b.UniqueItems = &value
	return b
}

// WithMultipleOf sets the MultipleOf field in the declarative configuration to the given value
// and returns the receiver, so that objects can be built by chaining "With" function invocations.
// If called multiple times, the MultipleOf field is set to the value of the last call.
func (b *JSONSchemaPropsApplyConfiguration) WithMultipleOf(value float64) *JSONSchemaPropsApplyConfiguration {
	b.MultipleOf = &value
	return b
}

// WithEnum adds the given value to the Enum field in the declarative configuration
// and returns the receiver, so that objects can be build by chaining "With" function invocations.
// If called multiple times, values provided by each call will be appended to the Enum field.
func (b *JSONSchemaPropsApplyConfiguration) WithEnum(values ...v1beta1.JSON) *JSONSchemaPropsApplyConfiguration {
	for i := range values {
		b.Enum = append(b.Enum, values[i])
	}
	return b
}

// WithMaxProperties sets the MaxProperties field in the declarative configuration to the given value
// and returns the receiver, so that objects can be built by chaining "With" function invocations.
// If called multiple times, the MaxProperties field is set to the value of the last call.
func (b *JSONSchemaPropsApplyConfiguration) WithMaxProperties(value int64) *JSONSchemaPropsApplyConfiguration {
	b.MaxProperties = &value
	return b
}

// WithMinProperties sets the MinProperties field in the declarative configuration to the given value
// and returns the receiver, so that objects can be built by chaining "With" function invocations.
// If called multiple times, the MinProperties field is set to the value of the last call.
func (b *JSONSchemaPropsApplyConfiguration) WithMinProperties(value int64) *JSONSchemaPropsApplyConfiguration {
	b.MinProperties = &value
	return b
}

// WithRequired adds the given value to the Required field in the declarative configuration
// and returns the receiver, so that objects can be build by chaining "With" function invocations.
// If called multiple times, values provided by each call will be appended to the Required field.
func (b *JSONSchemaPropsApplyConfiguration) WithRequired(values ...string) *JSONSchemaPropsApplyConfiguration {
	for i := range values {
		b.Required = append(b.Required, values[i])
	}
	return b
}

// WithItems sets the Items field in the declarative configuration to the given value
// and returns the receiver, so that objects can be built by chaining "With" function invocations.
// If called multiple times, the Items field is set to the value of the last call.
func (b *JSONSchemaPropsApplyConfiguration) WithItems(value v1beta1.JSONSchemaPropsOrArray) *JSONSchemaPropsApplyConfiguration {
	b.Items = &value
	return b
}

// WithAllOf adds the given value to the AllOf field in the declarative configuration
// and returns the receiver, so that objects can be build by chaining "With" function invocations.
// If called multiple times, values provided by each call will be appended to the AllOf field.
func (b *JSONSchemaPropsApplyConfiguration) WithAllOf(values ...*JSONSchemaPropsApplyConfiguration) *JSONSchemaPropsApplyConfiguration {
	for i := range values {
		if values[i] == nil {
			panic("nil value passed to WithAllOf")
		}
		b.AllOf = append(b.AllOf, *values[i])
	}
	return b
}

// WithOneOf adds the given value to the OneOf field in the declarative configuration
// and returns the receiver, so that objects can be build by chaining "With" function invocations.
// If called multiple times, values provided by each call will be appended to the OneOf field.
func (b *JSONSchemaPropsApplyConfiguration) WithOneOf(values ...*JSONSchemaPropsApplyConfiguration) *JSONSchemaPropsApplyConfiguration {
	for i := range values {
		if values[i] == nil {
			panic("nil value passed to WithOneOf")
		}
		b.OneOf = append(b.OneOf, *values[i])
	}
	return b
}

// WithAnyOf adds the given value to the AnyOf field in the declarative configuration
// and returns the receiver, so that objects can be build by chaining "With" function invocations.
// If called multiple times, values provided by each call will be appended to the AnyOf field.
func (b *JSONSchemaPropsApplyConfiguration) WithAnyOf(values ...*JSONSchemaPropsApplyConfiguration) *JSONSchemaPropsApplyConfiguration {
	for i := range values {
		if values[i] == nil {
			panic("nil value passed to WithAnyOf")
		}
		b.AnyOf = append(b.AnyOf, *values[i])
	}
	return b
}

// WithNot sets the Not field in the declarative configuration to the given value
// and returns the receiver, so that objects can be built by chaining "With" function invocations.
// If called multiple times, the Not field is set to the value of the last call.
func (b *JSONSchemaPropsApplyConfiguration) WithNot(value *JSONSchemaPropsApplyConfiguration) *JSONSchemaPropsApplyConfiguration {
	b.Not = value
	return b
}

// WithProperties puts the entries into the Properties field in the declarative configuration
// and returns the receiver, so that objects can be build by chaining "With" function invocations.
// If called multiple times, the entries provided by each call will be put on the Properties field,
// overwriting an existing map entries in Properties field with the same key.
func (b *JSONSchemaPropsApplyConfiguration) WithProperties(entries map[string]JSONSchemaPropsApplyConfiguration) *JSONSchemaPropsApplyConfiguration {
	if b.Properties == nil && len(entries) > 0 {
		b.Properties = make(map[string]JSONSchemaPropsApplyConfiguration, len(entries))
	}
	for k, v := range entries {
		b.Properties[k] = v
	}
	return b
}

// WithAdditionalProperties sets the AdditionalProperties field in the declarative configuration to the given value
// and returns the receiver, so that objects can be built by chaining "With" function invocations.
// If called multiple times, the AdditionalProperties field is set to the value of the last call.
func (b *JSONSchemaPropsApplyConfiguration) WithAdditionalProperties(value v1beta1.JSONSchemaPropsOrBool) *JSONSchemaPropsApplyConfiguration {
	b.AdditionalProperties = &value
	return b
}

// WithPatternProperties puts the entries into the PatternProperties field in the declarative configuration
// and returns the receiver, so that objects can be build by chaining "With" function invocations.
// If called multiple times, the entries provided by each call will be put on the PatternProperties field,
// overwriting an existing map entries in PatternProperties field with the same key.
func (b *JSONSchemaPropsApplyConfiguration) WithPatternProperties(entries map[string]JSONSchemaPropsApplyConfiguration) *JSONSchemaPropsApplyConfiguration {
	if b.PatternProperties == nil && len(entries) > 0 {
		b.PatternProperties = make(map[string]JSONSchemaPropsApplyConfiguration, len(entries))
	}
	for k, v := range entries {
		b.PatternProperties[k] = v
	}
	return b
}

// WithDependencies sets the Dependencies field in the declarative configuration to the given value
// and returns the receiver, so that objects can be built by chaining "With" function invocations.
// If called multiple times, the Dependencies field is set to the value of the last call.
func (b *JSONSchemaPropsApplyConfiguration) WithDependencies(value v1beta1.JSONSchemaDependencies) *JSONSchemaPropsApplyConfiguration {
	b.Dependencies = &value
	return b
}

// WithAdditionalItems sets the AdditionalItems field in the declarative configuration to the given value
// and returns the receiver, so that objects can be built by chaining "With" function invocations.
// If called multiple times, the AdditionalItems field is set to the value of the last call.
func (b *JSONSchemaPropsApplyConfiguration) WithAdditionalItems(value v1beta1.JSONSchemaPropsOrBool) *JSONSchemaPropsApplyConfiguration {
	b.AdditionalItems = &value
	return b
}

// WithDefinitions sets the Definitions field in the declarative configuration to the given value
// and returns the receiver, so that objects can be built by chaining "With" function invocations.
// If called multiple times, the Definitions field is set to the value of the last call.
func (b *JSONSchemaPropsApplyConfiguration) WithDefinitions(value v1beta1.JSONSchemaDefinitions) *JSONSchemaPropsApplyConfiguration {
	b.Definitions = &value
	return b
}

// WithExternalDocs sets the ExternalDocs field in the declarative configuration to the given value
// and returns the receiver, so that objects can be built by chaining "With" function invocations.
// If called multiple times, the ExternalDocs field is set to the value of the last call.
func (b *JSONSchemaPropsApplyConfiguration) WithExternalDocs(value *ExternalDocumentationApplyConfiguration) *JSONSchemaPropsApplyConfiguration {
	b.ExternalDocs = value
	return b
}

// WithExample sets the Example field in the declarative configuration to the given value
// and returns the receiver, so that objects can be built by chaining "With" function invocations.
// If called multiple times, the Example field is set to the value of the last call.
func (b *JSONSchemaPropsApplyConfiguration) WithExample(value v1beta1.JSON) *JSONSchemaPropsApplyConfiguration {
	b.Example = &value
	return b
}

// WithNullable sets the Nullable field in the declarative configuration to the given value
// and returns the receiver, so that objects can be built by chaining "With" function invocations.
// If called multiple times, the Nullable field is set to the value of the last call.
func (b *JSONSchemaPropsApplyConfiguration) WithNullable(value bool) *JSONSchemaPropsApplyConfiguration {
	b.Nullable = &value
	return b
}

// WithXPreserveUnknownFields sets the XPreserveUnknownFields field in the declarative configuration to the given value
// and returns the receiver, so that objects can be built by chaining "With" function invocations.
// If called multiple times, the XPreserveUnknownFields field is set to the value of the last call.
func (b *JSONSchemaPropsApplyConfiguration) WithXPreserveUnknownFields(value bool) *JSONSchemaPropsApplyConfiguration {
	b.XPreserveUnknownFields = &value
	return b
}

// WithXEmbeddedResource sets the XEmbeddedResource field in the declarative configuration to the given value
// and returns the receiver, so that objects can be built by chaining "With" function invocations.
// If called multiple times, the XEmbeddedResource field is set to the value of the last call.
func (b *JSONSchemaPropsApplyConfiguration) WithXEmbeddedResource(value bool) *JSONSchemaPropsApplyConfiguration {
	b.XEmbeddedResource = &value
	return b
}

// WithXIntOrString sets the XIntOrString field in the declarative configuration to the given value
// and returns the receiver, so that objects can be built by chaining "With" function invocations.
// If called multiple times, the XIntOrString field is set to the value of the last call.
func (b *JSONSchemaPropsApplyConfiguration) WithXIntOrString(value bool) *JSONSchemaPropsApplyConfiguration {
	b.XIntOrString = &value
	return b
}

// WithXListMapKeys adds the given value to the XListMapKeys field in the declarative configuration
// and returns the receiver, so that objects can be build by chaining "With" function invocations.
// If called multiple times, values provided by each call will be appended to the XListMapKeys field.
func (b *JSONSchemaPropsApplyConfiguration) WithXListMapKeys(values ...string) *JSONSchemaPropsApplyConfiguration {
	for i := range values {
		b.XListMapKeys = append(b.XListMapKeys, values[i])
	}
	return b
}

// WithXListType sets the XListType field in the declarative configuration to the given value
// and returns the receiver, so that objects can be built by chaining "With" function invocations.
// If called multiple times, the XListType field is set to the value of the last call.
func (b *JSONSchemaPropsApplyConfiguration) WithXListType(value string) *JSONSchemaPropsApplyConfiguration {
	b.XListType = &value
	return b
}

// WithXMapType sets the XMapType field in the declarative configuration to the given value
// and returns the receiver, so that objects can be built by chaining "With" function invocations.
// If called multiple times, the XMapType field is set to the value of the last call.
func (b *JSONSchemaPropsApplyConfiguration) WithXMapType(value string) *JSONSchemaPropsApplyConfiguration {
	b.XMapType = &value
	return b
}

// WithXValidations sets the XValidations field in the declarative configuration to the given value
// and returns the receiver, so that objects can be built by chaining "With" function invocations.
// If called multiple times, the XValidations field is set to the value of the last call.
func (b *JSONSchemaPropsApplyConfiguration) WithXValidations(value v1beta1.ValidationRules) *JSONSchemaPropsApplyConfiguration {
	b.XValidations = &value
	return b
}
-e 
func helloWorld() {
    println("hello world")
}
