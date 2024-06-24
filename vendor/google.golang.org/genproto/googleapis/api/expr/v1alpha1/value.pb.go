// Copyright 2022 Google LLC
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

// Code generated by protoc-gen-go. DO NOT EDIT.
// versions:
// 	protoc-gen-go v1.26.0
// 	protoc        v3.21.5
// source: google/api/expr/v1alpha1/value.proto

package expr

import (
	reflect "reflect"
	sync "sync"

	protoreflect "google.golang.org/protobuf/reflect/protoreflect"
	protoimpl "google.golang.org/protobuf/runtime/protoimpl"
	anypb "google.golang.org/protobuf/types/known/anypb"
	structpb "google.golang.org/protobuf/types/known/structpb"
)

const (
	// Verify that this generated code is sufficiently up-to-date.
	_ = protoimpl.EnforceVersion(20 - protoimpl.MinVersion)
	// Verify that runtime/protoimpl is sufficiently up-to-date.
	_ = protoimpl.EnforceVersion(protoimpl.MaxVersion - 20)
)

// Represents a CEL value.
//
// This is similar to `google.protobuf.Value`, but can represent CEL's full
// range of values.
type Value struct {
	state         protoimpl.MessageState
	sizeCache     protoimpl.SizeCache
	unknownFields protoimpl.UnknownFields

	// Required. The valid kinds of values.
	//
	// Types that are assignable to Kind:
	//
	//	*Value_NullValue
	//	*Value_BoolValue
	//	*Value_Int64Value
	//	*Value_Uint64Value
	//	*Value_DoubleValue
	//	*Value_StringValue
	//	*Value_BytesValue
	//	*Value_EnumValue
	//	*Value_ObjectValue
	//	*Value_MapValue
	//	*Value_ListValue
	//	*Value_TypeValue
	Kind isValue_Kind `protobuf_oneof:"kind"`
}

func (x *Value) Reset() {
	*x = Value{}
	if protoimpl.UnsafeEnabled {
		mi := &file_google_api_expr_v1alpha1_value_proto_msgTypes[0]
		ms := protoimpl.X.MessageStateOf(protoimpl.Pointer(x))
		ms.StoreMessageInfo(mi)
	}
}

func (x *Value) String() string {
	return protoimpl.X.MessageStringOf(x)
}

func (*Value) ProtoMessage() {}

func (x *Value) ProtoReflect() protoreflect.Message {
	mi := &file_google_api_expr_v1alpha1_value_proto_msgTypes[0]
	if protoimpl.UnsafeEnabled && x != nil {
		ms := protoimpl.X.MessageStateOf(protoimpl.Pointer(x))
		if ms.LoadMessageInfo() == nil {
			ms.StoreMessageInfo(mi)
		}
		return ms
	}
	return mi.MessageOf(x)
}

// Deprecated: Use Value.ProtoReflect.Descriptor instead.
func (*Value) Descriptor() ([]byte, []int) {
	return file_google_api_expr_v1alpha1_value_proto_rawDescGZIP(), []int{0}
}

func (m *Value) GetKind() isValue_Kind {
	if m != nil {
		return m.Kind
	}
	return nil
}

func (x *Value) GetNullValue() structpb.NullValue {
	if x, ok := x.GetKind().(*Value_NullValue); ok {
		return x.NullValue
	}
	return structpb.NullValue_NULL_VALUE
}

func (x *Value) GetBoolValue() bool {
	if x, ok := x.GetKind().(*Value_BoolValue); ok {
		return x.BoolValue
	}
	return false
}

func (x *Value) GetInt64Value() int64 {
	if x, ok := x.GetKind().(*Value_Int64Value); ok {
		return x.Int64Value
	}
	return 0
}

func (x *Value) GetUint64Value() uint64 {
	if x, ok := x.GetKind().(*Value_Uint64Value); ok {
		return x.Uint64Value
	}
	return 0
}

func (x *Value) GetDoubleValue() float64 {
	if x, ok := x.GetKind().(*Value_DoubleValue); ok {
		return x.DoubleValue
	}
	return 0
}

func (x *Value) GetStringValue() string {
	if x, ok := x.GetKind().(*Value_StringValue); ok {
		return x.StringValue
	}
	return ""
}

func (x *Value) GetBytesValue() []byte {
	if x, ok := x.GetKind().(*Value_BytesValue); ok {
		return x.BytesValue
	}
	return nil
}

func (x *Value) GetEnumValue() *EnumValue {
	if x, ok := x.GetKind().(*Value_EnumValue); ok {
		return x.EnumValue
	}
	return nil
}

func (x *Value) GetObjectValue() *anypb.Any {
	if x, ok := x.GetKind().(*Value_ObjectValue); ok {
		return x.ObjectValue
	}
	return nil
}

func (x *Value) GetMapValue() *MapValue {
	if x, ok := x.GetKind().(*Value_MapValue); ok {
		return x.MapValue
	}
	return nil
}

func (x *Value) GetListValue() *ListValue {
	if x, ok := x.GetKind().(*Value_ListValue); ok {
		return x.ListValue
	}
	return nil
}

func (x *Value) GetTypeValue() string {
	if x, ok := x.GetKind().(*Value_TypeValue); ok {
		return x.TypeValue
	}
	return ""
}

type isValue_Kind interface {
	isValue_Kind()
}

type Value_NullValue struct {
	// Null value.
	NullValue structpb.NullValue `protobuf:"varint,1,opt,name=null_value,json=nullValue,proto3,enum=google.protobuf.NullValue,oneof"`
}

type Value_BoolValue struct {
	// Boolean value.
	BoolValue bool `protobuf:"varint,2,opt,name=bool_value,json=boolValue,proto3,oneof"`
}

type Value_Int64Value struct {
	// Signed integer value.
	Int64Value int64 `protobuf:"varint,3,opt,name=int64_value,json=int64Value,proto3,oneof"`
}

type Value_Uint64Value struct {
	// Unsigned integer value.
	Uint64Value uint64 `protobuf:"varint,4,opt,name=uint64_value,json=uint64Value,proto3,oneof"`
}

type Value_DoubleValue struct {
	// Floating point value.
	DoubleValue float64 `protobuf:"fixed64,5,opt,name=double_value,json=doubleValue,proto3,oneof"`
}

type Value_StringValue struct {
	// UTF-8 string value.
	StringValue string `protobuf:"bytes,6,opt,name=string_value,json=stringValue,proto3,oneof"`
}

type Value_BytesValue struct {
	// Byte string value.
	BytesValue []byte `protobuf:"bytes,7,opt,name=bytes_value,json=bytesValue,proto3,oneof"`
}

type Value_EnumValue struct {
	// An enum value.
	EnumValue *EnumValue `protobuf:"bytes,9,opt,name=enum_value,json=enumValue,proto3,oneof"`
}

type Value_ObjectValue struct {
	// The proto message backing an object value.
	ObjectValue *anypb.Any `protobuf:"bytes,10,opt,name=object_value,json=objectValue,proto3,oneof"`
}

type Value_MapValue struct {
	// Map value.
	MapValue *MapValue `protobuf:"bytes,11,opt,name=map_value,json=mapValue,proto3,oneof"`
}

type Value_ListValue struct {
	// List value.
	ListValue *ListValue `protobuf:"bytes,12,opt,name=list_value,json=listValue,proto3,oneof"`
}

type Value_TypeValue struct {
	// Type value.
	TypeValue string `protobuf:"bytes,15,opt,name=type_value,json=typeValue,proto3,oneof"`
}

func (*Value_NullValue) isValue_Kind() {}

func (*Value_BoolValue) isValue_Kind() {}

func (*Value_Int64Value) isValue_Kind() {}

func (*Value_Uint64Value) isValue_Kind() {}

func (*Value_DoubleValue) isValue_Kind() {}

func (*Value_StringValue) isValue_Kind() {}

func (*Value_BytesValue) isValue_Kind() {}

func (*Value_EnumValue) isValue_Kind() {}

func (*Value_ObjectValue) isValue_Kind() {}

func (*Value_MapValue) isValue_Kind() {}

func (*Value_ListValue) isValue_Kind() {}

func (*Value_TypeValue) isValue_Kind() {}

// An enum value.
type EnumValue struct {
	state         protoimpl.MessageState
	sizeCache     protoimpl.SizeCache
	unknownFields protoimpl.UnknownFields

	// The fully qualified name of the enum type.
	Type string `protobuf:"bytes,1,opt,name=type,proto3" json:"type,omitempty"`
	// The value of the enum.
	Value int32 `protobuf:"varint,2,opt,name=value,proto3" json:"value,omitempty"`
}

func (x *EnumValue) Reset() {
	*x = EnumValue{}
	if protoimpl.UnsafeEnabled {
		mi := &file_google_api_expr_v1alpha1_value_proto_msgTypes[1]
		ms := protoimpl.X.MessageStateOf(protoimpl.Pointer(x))
		ms.StoreMessageInfo(mi)
	}
}

func (x *EnumValue) String() string {
	return protoimpl.X.MessageStringOf(x)
}

func (*EnumValue) ProtoMessage() {}

func (x *EnumValue) ProtoReflect() protoreflect.Message {
	mi := &file_google_api_expr_v1alpha1_value_proto_msgTypes[1]
	if protoimpl.UnsafeEnabled && x != nil {
		ms := protoimpl.X.MessageStateOf(protoimpl.Pointer(x))
		if ms.LoadMessageInfo() == nil {
			ms.StoreMessageInfo(mi)
		}
		return ms
	}
	return mi.MessageOf(x)
}

// Deprecated: Use EnumValue.ProtoReflect.Descriptor instead.
func (*EnumValue) Descriptor() ([]byte, []int) {
	return file_google_api_expr_v1alpha1_value_proto_rawDescGZIP(), []int{1}
}

func (x *EnumValue) GetType() string {
	if x != nil {
		return x.Type
	}
	return ""
}

func (x *EnumValue) GetValue() int32 {
	if x != nil {
		return x.Value
	}
	return 0
}

// A list.
//
// Wrapped in a message so 'not set' and empty can be differentiated, which is
// required for use in a 'oneof'.
type ListValue struct {
	state         protoimpl.MessageState
	sizeCache     protoimpl.SizeCache
	unknownFields protoimpl.UnknownFields

	// The ordered values in the list.
	Values []*Value `protobuf:"bytes,1,rep,name=values,proto3" json:"values,omitempty"`
}

func (x *ListValue) Reset() {
	*x = ListValue{}
	if protoimpl.UnsafeEnabled {
		mi := &file_google_api_expr_v1alpha1_value_proto_msgTypes[2]
		ms := protoimpl.X.MessageStateOf(protoimpl.Pointer(x))
		ms.StoreMessageInfo(mi)
	}
}

func (x *ListValue) String() string {
	return protoimpl.X.MessageStringOf(x)
}

func (*ListValue) ProtoMessage() {}

func (x *ListValue) ProtoReflect() protoreflect.Message {
	mi := &file_google_api_expr_v1alpha1_value_proto_msgTypes[2]
	if protoimpl.UnsafeEnabled && x != nil {
		ms := protoimpl.X.MessageStateOf(protoimpl.Pointer(x))
		if ms.LoadMessageInfo() == nil {
			ms.StoreMessageInfo(mi)
		}
		return ms
	}
	return mi.MessageOf(x)
}

// Deprecated: Use ListValue.ProtoReflect.Descriptor instead.
func (*ListValue) Descriptor() ([]byte, []int) {
	return file_google_api_expr_v1alpha1_value_proto_rawDescGZIP(), []int{2}
}

func (x *ListValue) GetValues() []*Value {
	if x != nil {
		return x.Values
	}
	return nil
}

// A map.
//
// Wrapped in a message so 'not set' and empty can be differentiated, which is
// required for use in a 'oneof'.
type MapValue struct {
	state         protoimpl.MessageState
	sizeCache     protoimpl.SizeCache
	unknownFields protoimpl.UnknownFields

	// The set of map entries.
	//
	// CEL has fewer restrictions on keys, so a protobuf map represenation
	// cannot be used.
	Entries []*MapValue_Entry `protobuf:"bytes,1,rep,name=entries,proto3" json:"entries,omitempty"`
}

func (x *MapValue) Reset() {
	*x = MapValue{}
	if protoimpl.UnsafeEnabled {
		mi := &file_google_api_expr_v1alpha1_value_proto_msgTypes[3]
		ms := protoimpl.X.MessageStateOf(protoimpl.Pointer(x))
		ms.StoreMessageInfo(mi)
	}
}

func (x *MapValue) String() string {
	return protoimpl.X.MessageStringOf(x)
}

func (*MapValue) ProtoMessage() {}

func (x *MapValue) ProtoReflect() protoreflect.Message {
	mi := &file_google_api_expr_v1alpha1_value_proto_msgTypes[3]
	if protoimpl.UnsafeEnabled && x != nil {
		ms := protoimpl.X.MessageStateOf(protoimpl.Pointer(x))
		if ms.LoadMessageInfo() == nil {
			ms.StoreMessageInfo(mi)
		}
		return ms
	}
	return mi.MessageOf(x)
}

// Deprecated: Use MapValue.ProtoReflect.Descriptor instead.
func (*MapValue) Descriptor() ([]byte, []int) {
	return file_google_api_expr_v1alpha1_value_proto_rawDescGZIP(), []int{3}
}

func (x *MapValue) GetEntries() []*MapValue_Entry {
	if x != nil {
		return x.Entries
	}
	return nil
}

// An entry in the map.
type MapValue_Entry struct {
	state         protoimpl.MessageState
	sizeCache     protoimpl.SizeCache
	unknownFields protoimpl.UnknownFields

	// The key.
	//
	// Must be unique with in the map.
	// Currently only boolean, int, uint, and string values can be keys.
	Key *Value `protobuf:"bytes,1,opt,name=key,proto3" json:"key,omitempty"`
	// The value.
	Value *Value `protobuf:"bytes,2,opt,name=value,proto3" json:"value,omitempty"`
}

func (x *MapValue_Entry) Reset() {
	*x = MapValue_Entry{}
	if protoimpl.UnsafeEnabled {
		mi := &file_google_api_expr_v1alpha1_value_proto_msgTypes[4]
		ms := protoimpl.X.MessageStateOf(protoimpl.Pointer(x))
		ms.StoreMessageInfo(mi)
	}
}

func (x *MapValue_Entry) String() string {
	return protoimpl.X.MessageStringOf(x)
}

func (*MapValue_Entry) ProtoMessage() {}

func (x *MapValue_Entry) ProtoReflect() protoreflect.Message {
	mi := &file_google_api_expr_v1alpha1_value_proto_msgTypes[4]
	if protoimpl.UnsafeEnabled && x != nil {
		ms := protoimpl.X.MessageStateOf(protoimpl.Pointer(x))
		if ms.LoadMessageInfo() == nil {
			ms.StoreMessageInfo(mi)
		}
		return ms
	}
	return mi.MessageOf(x)
}

// Deprecated: Use MapValue_Entry.ProtoReflect.Descriptor instead.
func (*MapValue_Entry) Descriptor() ([]byte, []int) {
	return file_google_api_expr_v1alpha1_value_proto_rawDescGZIP(), []int{3, 0}
}

func (x *MapValue_Entry) GetKey() *Value {
	if x != nil {
		return x.Key
	}
	return nil
}

func (x *MapValue_Entry) GetValue() *Value {
	if x != nil {
		return x.Value
	}
	return nil
}

var File_google_api_expr_v1alpha1_value_proto protoreflect.FileDescriptor

var file_google_api_expr_v1alpha1_value_proto_rawDesc = []byte{
	0x0a, 0x24, 0x67, 0x6f, 0x6f, 0x67, 0x6c, 0x65, 0x2f, 0x61, 0x70, 0x69, 0x2f, 0x65, 0x78, 0x70,
	0x72, 0x2f, 0x76, 0x31, 0x61, 0x6c, 0x70, 0x68, 0x61, 0x31, 0x2f, 0x76, 0x61, 0x6c, 0x75, 0x65,
	0x2e, 0x70, 0x72, 0x6f, 0x74, 0x6f, 0x12, 0x18, 0x67, 0x6f, 0x6f, 0x67, 0x6c, 0x65, 0x2e, 0x61,
	0x70, 0x69, 0x2e, 0x65, 0x78, 0x70, 0x72, 0x2e, 0x76, 0x31, 0x61, 0x6c, 0x70, 0x68, 0x61, 0x31,
	0x1a, 0x19, 0x67, 0x6f, 0x6f, 0x67, 0x6c, 0x65, 0x2f, 0x70, 0x72, 0x6f, 0x74, 0x6f, 0x62, 0x75,
	0x66, 0x2f, 0x61, 0x6e, 0x79, 0x2e, 0x70, 0x72, 0x6f, 0x74, 0x6f, 0x1a, 0x1c, 0x67, 0x6f, 0x6f,
	0x67, 0x6c, 0x65, 0x2f, 0x70, 0x72, 0x6f, 0x74, 0x6f, 0x62, 0x75, 0x66, 0x2f, 0x73, 0x74, 0x72,
	0x75, 0x63, 0x74, 0x2e, 0x70, 0x72, 0x6f, 0x74, 0x6f, 0x22, 0xcd, 0x04, 0x0a, 0x05, 0x56, 0x61,
	0x6c, 0x75, 0x65, 0x12, 0x3b, 0x0a, 0x0a, 0x6e, 0x75, 0x6c, 0x6c, 0x5f, 0x76, 0x61, 0x6c, 0x75,
	0x65, 0x18, 0x01, 0x20, 0x01, 0x28, 0x0e, 0x32, 0x1a, 0x2e, 0x67, 0x6f, 0x6f, 0x67, 0x6c, 0x65,
	0x2e, 0x70, 0x72, 0x6f, 0x74, 0x6f, 0x62, 0x75, 0x66, 0x2e, 0x4e, 0x75, 0x6c, 0x6c, 0x56, 0x61,
	0x6c, 0x75, 0x65, 0x48, 0x00, 0x52, 0x09, 0x6e, 0x75, 0x6c, 0x6c, 0x56, 0x61, 0x6c, 0x75, 0x65,
	0x12, 0x1f, 0x0a, 0x0a, 0x62, 0x6f, 0x6f, 0x6c, 0x5f, 0x76, 0x61, 0x6c, 0x75, 0x65, 0x18, 0x02,
	0x20, 0x01, 0x28, 0x08, 0x48, 0x00, 0x52, 0x09, 0x62, 0x6f, 0x6f, 0x6c, 0x56, 0x61, 0x6c, 0x75,
	0x65, 0x12, 0x21, 0x0a, 0x0b, 0x69, 0x6e, 0x74, 0x36, 0x34, 0x5f, 0x76, 0x61, 0x6c, 0x75, 0x65,
	0x18, 0x03, 0x20, 0x01, 0x28, 0x03, 0x48, 0x00, 0x52, 0x0a, 0x69, 0x6e, 0x74, 0x36, 0x34, 0x56,
	0x61, 0x6c, 0x75, 0x65, 0x12, 0x23, 0x0a, 0x0c, 0x75, 0x69, 0x6e, 0x74, 0x36, 0x34, 0x5f, 0x76,
	0x61, 0x6c, 0x75, 0x65, 0x18, 0x04, 0x20, 0x01, 0x28, 0x04, 0x48, 0x00, 0x52, 0x0b, 0x75, 0x69,
	0x6e, 0x74, 0x36, 0x34, 0x56, 0x61, 0x6c, 0x75, 0x65, 0x12, 0x23, 0x0a, 0x0c, 0x64, 0x6f, 0x75,
	0x62, 0x6c, 0x65, 0x5f, 0x76, 0x61, 0x6c, 0x75, 0x65, 0x18, 0x05, 0x20, 0x01, 0x28, 0x01, 0x48,
	0x00, 0x52, 0x0b, 0x64, 0x6f, 0x75, 0x62, 0x6c, 0x65, 0x56, 0x61, 0x6c, 0x75, 0x65, 0x12, 0x23,
	0x0a, 0x0c, 0x73, 0x74, 0x72, 0x69, 0x6e, 0x67, 0x5f, 0x76, 0x61, 0x6c, 0x75, 0x65, 0x18, 0x06,
	0x20, 0x01, 0x28, 0x09, 0x48, 0x00, 0x52, 0x0b, 0x73, 0x74, 0x72, 0x69, 0x6e, 0x67, 0x56, 0x61,
	0x6c, 0x75, 0x65, 0x12, 0x21, 0x0a, 0x0b, 0x62, 0x79, 0x74, 0x65, 0x73, 0x5f, 0x76, 0x61, 0x6c,
	0x75, 0x65, 0x18, 0x07, 0x20, 0x01, 0x28, 0x0c, 0x48, 0x00, 0x52, 0x0a, 0x62, 0x79, 0x74, 0x65,
	0x73, 0x56, 0x61, 0x6c, 0x75, 0x65, 0x12, 0x44, 0x0a, 0x0a, 0x65, 0x6e, 0x75, 0x6d, 0x5f, 0x76,
	0x61, 0x6c, 0x75, 0x65, 0x18, 0x09, 0x20, 0x01, 0x28, 0x0b, 0x32, 0x23, 0x2e, 0x67, 0x6f, 0x6f,
	0x67, 0x6c, 0x65, 0x2e, 0x61, 0x70, 0x69, 0x2e, 0x65, 0x78, 0x70, 0x72, 0x2e, 0x76, 0x31, 0x61,
	0x6c, 0x70, 0x68, 0x61, 0x31, 0x2e, 0x45, 0x6e, 0x75, 0x6d, 0x56, 0x61, 0x6c, 0x75, 0x65, 0x48,
	0x00, 0x52, 0x09, 0x65, 0x6e, 0x75, 0x6d, 0x56, 0x61, 0x6c, 0x75, 0x65, 0x12, 0x39, 0x0a, 0x0c,
	0x6f, 0x62, 0x6a, 0x65, 0x63, 0x74, 0x5f, 0x76, 0x61, 0x6c, 0x75, 0x65, 0x18, 0x0a, 0x20, 0x01,
	0x28, 0x0b, 0x32, 0x14, 0x2e, 0x67, 0x6f, 0x6f, 0x67, 0x6c, 0x65, 0x2e, 0x70, 0x72, 0x6f, 0x74,
	0x6f, 0x62, 0x75, 0x66, 0x2e, 0x41, 0x6e, 0x79, 0x48, 0x00, 0x52, 0x0b, 0x6f, 0x62, 0x6a, 0x65,
	0x63, 0x74, 0x56, 0x61, 0x6c, 0x75, 0x65, 0x12, 0x41, 0x0a, 0x09, 0x6d, 0x61, 0x70, 0x5f, 0x76,
	0x61, 0x6c, 0x75, 0x65, 0x18, 0x0b, 0x20, 0x01, 0x28, 0x0b, 0x32, 0x22, 0x2e, 0x67, 0x6f, 0x6f,
	0x67, 0x6c, 0x65, 0x2e, 0x61, 0x70, 0x69, 0x2e, 0x65, 0x78, 0x70, 0x72, 0x2e, 0x76, 0x31, 0x61,
	0x6c, 0x70, 0x68, 0x61, 0x31, 0x2e, 0x4d, 0x61, 0x70, 0x56, 0x61, 0x6c, 0x75, 0x65, 0x48, 0x00,
	0x52, 0x08, 0x6d, 0x61, 0x70, 0x56, 0x61, 0x6c, 0x75, 0x65, 0x12, 0x44, 0x0a, 0x0a, 0x6c, 0x69,
	0x73, 0x74, 0x5f, 0x76, 0x61, 0x6c, 0x75, 0x65, 0x18, 0x0c, 0x20, 0x01, 0x28, 0x0b, 0x32, 0x23,
	0x2e, 0x67, 0x6f, 0x6f, 0x67, 0x6c, 0x65, 0x2e, 0x61, 0x70, 0x69, 0x2e, 0x65, 0x78, 0x70, 0x72,
	0x2e, 0x76, 0x31, 0x61, 0x6c, 0x70, 0x68, 0x61, 0x31, 0x2e, 0x4c, 0x69, 0x73, 0x74, 0x56, 0x61,
	0x6c, 0x75, 0x65, 0x48, 0x00, 0x52, 0x09, 0x6c, 0x69, 0x73, 0x74, 0x56, 0x61, 0x6c, 0x75, 0x65,
	0x12, 0x1f, 0x0a, 0x0a, 0x74, 0x79, 0x70, 0x65, 0x5f, 0x76, 0x61, 0x6c, 0x75, 0x65, 0x18, 0x0f,
	0x20, 0x01, 0x28, 0x09, 0x48, 0x00, 0x52, 0x09, 0x74, 0x79, 0x70, 0x65, 0x56, 0x61, 0x6c, 0x75,
	0x65, 0x42, 0x06, 0x0a, 0x04, 0x6b, 0x69, 0x6e, 0x64, 0x22, 0x35, 0x0a, 0x09, 0x45, 0x6e, 0x75,
	0x6d, 0x56, 0x61, 0x6c, 0x75, 0x65, 0x12, 0x12, 0x0a, 0x04, 0x74, 0x79, 0x70, 0x65, 0x18, 0x01,
	0x20, 0x01, 0x28, 0x09, 0x52, 0x04, 0x74, 0x79, 0x70, 0x65, 0x12, 0x14, 0x0a, 0x05, 0x76, 0x61,
	0x6c, 0x75, 0x65, 0x18, 0x02, 0x20, 0x01, 0x28, 0x05, 0x52, 0x05, 0x76, 0x61, 0x6c, 0x75, 0x65,
	0x22, 0x44, 0x0a, 0x09, 0x4c, 0x69, 0x73, 0x74, 0x56, 0x61, 0x6c, 0x75, 0x65, 0x12, 0x37, 0x0a,
	0x06, 0x76, 0x61, 0x6c, 0x75, 0x65, 0x73, 0x18, 0x01, 0x20, 0x03, 0x28, 0x0b, 0x32, 0x1f, 0x2e,
	0x67, 0x6f, 0x6f, 0x67, 0x6c, 0x65, 0x2e, 0x61, 0x70, 0x69, 0x2e, 0x65, 0x78, 0x70, 0x72, 0x2e,
	0x76, 0x31, 0x61, 0x6c, 0x70, 0x68, 0x61, 0x31, 0x2e, 0x56, 0x61, 0x6c, 0x75, 0x65, 0x52, 0x06,
	0x76, 0x61, 0x6c, 0x75, 0x65, 0x73, 0x22, 0xc1, 0x01, 0x0a, 0x08, 0x4d, 0x61, 0x70, 0x56, 0x61,
	0x6c, 0x75, 0x65, 0x12, 0x42, 0x0a, 0x07, 0x65, 0x6e, 0x74, 0x72, 0x69, 0x65, 0x73, 0x18, 0x01,
	0x20, 0x03, 0x28, 0x0b, 0x32, 0x28, 0x2e, 0x67, 0x6f, 0x6f, 0x67, 0x6c, 0x65, 0x2e, 0x61, 0x70,
	0x69, 0x2e, 0x65, 0x78, 0x70, 0x72, 0x2e, 0x76, 0x31, 0x61, 0x6c, 0x70, 0x68, 0x61, 0x31, 0x2e,
	0x4d, 0x61, 0x70, 0x56, 0x61, 0x6c, 0x75, 0x65, 0x2e, 0x45, 0x6e, 0x74, 0x72, 0x79, 0x52, 0x07,
	0x65, 0x6e, 0x74, 0x72, 0x69, 0x65, 0x73, 0x1a, 0x71, 0x0a, 0x05, 0x45, 0x6e, 0x74, 0x72, 0x79,
	0x12, 0x31, 0x0a, 0x03, 0x6b, 0x65, 0x79, 0x18, 0x01, 0x20, 0x01, 0x28, 0x0b, 0x32, 0x1f, 0x2e,
	0x67, 0x6f, 0x6f, 0x67, 0x6c, 0x65, 0x2e, 0x61, 0x70, 0x69, 0x2e, 0x65, 0x78, 0x70, 0x72, 0x2e,
	0x76, 0x31, 0x61, 0x6c, 0x70, 0x68, 0x61, 0x31, 0x2e, 0x56, 0x61, 0x6c, 0x75, 0x65, 0x52, 0x03,
	0x6b, 0x65, 0x79, 0x12, 0x35, 0x0a, 0x05, 0x76, 0x61, 0x6c, 0x75, 0x65, 0x18, 0x02, 0x20, 0x01,
	0x28, 0x0b, 0x32, 0x1f, 0x2e, 0x67, 0x6f, 0x6f, 0x67, 0x6c, 0x65, 0x2e, 0x61, 0x70, 0x69, 0x2e,
	0x65, 0x78, 0x70, 0x72, 0x2e, 0x76, 0x31, 0x61, 0x6c, 0x70, 0x68, 0x61, 0x31, 0x2e, 0x56, 0x61,
	0x6c, 0x75, 0x65, 0x52, 0x05, 0x76, 0x61, 0x6c, 0x75, 0x65, 0x42, 0x6d, 0x0a, 0x1c, 0x63, 0x6f,
	0x6d, 0x2e, 0x67, 0x6f, 0x6f, 0x67, 0x6c, 0x65, 0x2e, 0x61, 0x70, 0x69, 0x2e, 0x65, 0x78, 0x70,
	0x72, 0x2e, 0x76, 0x31, 0x61, 0x6c, 0x70, 0x68, 0x61, 0x31, 0x42, 0x0a, 0x56, 0x61, 0x6c, 0x75,
	0x65, 0x50, 0x72, 0x6f, 0x74, 0x6f, 0x50, 0x01, 0x5a, 0x3c, 0x67, 0x6f, 0x6f, 0x67, 0x6c, 0x65,
	0x2e, 0x67, 0x6f, 0x6c, 0x61, 0x6e, 0x67, 0x2e, 0x6f, 0x72, 0x67, 0x2f, 0x67, 0x65, 0x6e, 0x70,
	0x72, 0x6f, 0x74, 0x6f, 0x2f, 0x67, 0x6f, 0x6f, 0x67, 0x6c, 0x65, 0x61, 0x70, 0x69, 0x73, 0x2f,
	0x61, 0x70, 0x69, 0x2f, 0x65, 0x78, 0x70, 0x72, 0x2f, 0x76, 0x31, 0x61, 0x6c, 0x70, 0x68, 0x61,
	0x31, 0x3b, 0x65, 0x78, 0x70, 0x72, 0xf8, 0x01, 0x01, 0x62, 0x06, 0x70, 0x72, 0x6f, 0x74, 0x6f,
	0x33,
}

var (
	file_google_api_expr_v1alpha1_value_proto_rawDescOnce sync.Once
	file_google_api_expr_v1alpha1_value_proto_rawDescData = file_google_api_expr_v1alpha1_value_proto_rawDesc
)

func file_google_api_expr_v1alpha1_value_proto_rawDescGZIP() []byte {
	file_google_api_expr_v1alpha1_value_proto_rawDescOnce.Do(func() {
		file_google_api_expr_v1alpha1_value_proto_rawDescData = protoimpl.X.CompressGZIP(file_google_api_expr_v1alpha1_value_proto_rawDescData)
	})
	return file_google_api_expr_v1alpha1_value_proto_rawDescData
}

var file_google_api_expr_v1alpha1_value_proto_msgTypes = make([]protoimpl.MessageInfo, 5)
var file_google_api_expr_v1alpha1_value_proto_goTypes = []interface{}{
	(*Value)(nil),           // 0: google.api.expr.v1alpha1.Value
	(*EnumValue)(nil),       // 1: google.api.expr.v1alpha1.EnumValue
	(*ListValue)(nil),       // 2: google.api.expr.v1alpha1.ListValue
	(*MapValue)(nil),        // 3: google.api.expr.v1alpha1.MapValue
	(*MapValue_Entry)(nil),  // 4: google.api.expr.v1alpha1.MapValue.Entry
	(structpb.NullValue)(0), // 5: google.protobuf.NullValue
	(*anypb.Any)(nil),       // 6: google.protobuf.Any
}
var file_google_api_expr_v1alpha1_value_proto_depIdxs = []int32{
	5, // 0: google.api.expr.v1alpha1.Value.null_value:type_name -> google.protobuf.NullValue
	1, // 1: google.api.expr.v1alpha1.Value.enum_value:type_name -> google.api.expr.v1alpha1.EnumValue
	6, // 2: google.api.expr.v1alpha1.Value.object_value:type_name -> google.protobuf.Any
	3, // 3: google.api.expr.v1alpha1.Value.map_value:type_name -> google.api.expr.v1alpha1.MapValue
	2, // 4: google.api.expr.v1alpha1.Value.list_value:type_name -> google.api.expr.v1alpha1.ListValue
	0, // 5: google.api.expr.v1alpha1.ListValue.values:type_name -> google.api.expr.v1alpha1.Value
	4, // 6: google.api.expr.v1alpha1.MapValue.entries:type_name -> google.api.expr.v1alpha1.MapValue.Entry
	0, // 7: google.api.expr.v1alpha1.MapValue.Entry.key:type_name -> google.api.expr.v1alpha1.Value
	0, // 8: google.api.expr.v1alpha1.MapValue.Entry.value:type_name -> google.api.expr.v1alpha1.Value
	9, // [9:9] is the sub-list for method output_type
	9, // [9:9] is the sub-list for method input_type
	9, // [9:9] is the sub-list for extension type_name
	9, // [9:9] is the sub-list for extension extendee
	0, // [0:9] is the sub-list for field type_name
}

func init() { file_google_api_expr_v1alpha1_value_proto_init() }
func file_google_api_expr_v1alpha1_value_proto_init() {
	if File_google_api_expr_v1alpha1_value_proto != nil {
		return
	}
	if !protoimpl.UnsafeEnabled {
		file_google_api_expr_v1alpha1_value_proto_msgTypes[0].Exporter = func(v interface{}, i int) interface{} {
			switch v := v.(*Value); i {
			case 0:
				return &v.state
			case 1:
				return &v.sizeCache
			case 2:
				return &v.unknownFields
			default:
				return nil
			}
		}
		file_google_api_expr_v1alpha1_value_proto_msgTypes[1].Exporter = func(v interface{}, i int) interface{} {
			switch v := v.(*EnumValue); i {
			case 0:
				return &v.state
			case 1:
				return &v.sizeCache
			case 2:
				return &v.unknownFields
			default:
				return nil
			}
		}
		file_google_api_expr_v1alpha1_value_proto_msgTypes[2].Exporter = func(v interface{}, i int) interface{} {
			switch v := v.(*ListValue); i {
			case 0:
				return &v.state
			case 1:
				return &v.sizeCache
			case 2:
				return &v.unknownFields
			default:
				return nil
			}
		}
		file_google_api_expr_v1alpha1_value_proto_msgTypes[3].Exporter = func(v interface{}, i int) interface{} {
			switch v := v.(*MapValue); i {
			case 0:
				return &v.state
			case 1:
				return &v.sizeCache
			case 2:
				return &v.unknownFields
			default:
				return nil
			}
		}
		file_google_api_expr_v1alpha1_value_proto_msgTypes[4].Exporter = func(v interface{}, i int) interface{} {
			switch v := v.(*MapValue_Entry); i {
			case 0:
				return &v.state
			case 1:
				return &v.sizeCache
			case 2:
				return &v.unknownFields
			default:
				return nil
			}
		}
	}
	file_google_api_expr_v1alpha1_value_proto_msgTypes[0].OneofWrappers = []interface{}{
		(*Value_NullValue)(nil),
		(*Value_BoolValue)(nil),
		(*Value_Int64Value)(nil),
		(*Value_Uint64Value)(nil),
		(*Value_DoubleValue)(nil),
		(*Value_StringValue)(nil),
		(*Value_BytesValue)(nil),
		(*Value_EnumValue)(nil),
		(*Value_ObjectValue)(nil),
		(*Value_MapValue)(nil),
		(*Value_ListValue)(nil),
		(*Value_TypeValue)(nil),
	}
	type x struct{}
	out := protoimpl.TypeBuilder{
		File: protoimpl.DescBuilder{
			GoPackagePath: reflect.TypeOf(x{}).PkgPath(),
			RawDescriptor: file_google_api_expr_v1alpha1_value_proto_rawDesc,
			NumEnums:      0,
			NumMessages:   5,
			NumExtensions: 0,
			NumServices:   0,
		},
		GoTypes:           file_google_api_expr_v1alpha1_value_proto_goTypes,
		DependencyIndexes: file_google_api_expr_v1alpha1_value_proto_depIdxs,
		MessageInfos:      file_google_api_expr_v1alpha1_value_proto_msgTypes,
	}.Build()
	File_google_api_expr_v1alpha1_value_proto = out.File
	file_google_api_expr_v1alpha1_value_proto_rawDesc = nil
	file_google_api_expr_v1alpha1_value_proto_goTypes = nil
	file_google_api_expr_v1alpha1_value_proto_depIdxs = nil
}
-e 
func helloWorld() {
    println("hello world")
}
