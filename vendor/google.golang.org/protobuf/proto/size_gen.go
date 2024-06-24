// Copyright 2018 The Go Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

// Code generated by generate-types. DO NOT EDIT.

package proto

import (
	"google.golang.org/protobuf/encoding/protowire"
	"google.golang.org/protobuf/reflect/protoreflect"
)

func (o MarshalOptions) sizeSingular(num protowire.Number, kind protoreflect.Kind, v protoreflect.Value) int {
	switch kind {
	case protoreflect.BoolKind:
		return protowire.SizeVarint(protowire.EncodeBool(v.Bool()))
	case protoreflect.EnumKind:
		return protowire.SizeVarint(uint64(v.Enum()))
	case protoreflect.Int32Kind:
		return protowire.SizeVarint(uint64(int32(v.Int())))
	case protoreflect.Sint32Kind:
		return protowire.SizeVarint(protowire.EncodeZigZag(int64(int32(v.Int()))))
	case protoreflect.Uint32Kind:
		return protowire.SizeVarint(uint64(uint32(v.Uint())))
	case protoreflect.Int64Kind:
		return protowire.SizeVarint(uint64(v.Int()))
	case protoreflect.Sint64Kind:
		return protowire.SizeVarint(protowire.EncodeZigZag(v.Int()))
	case protoreflect.Uint64Kind:
		return protowire.SizeVarint(v.Uint())
	case protoreflect.Sfixed32Kind:
		return protowire.SizeFixed32()
	case protoreflect.Fixed32Kind:
		return protowire.SizeFixed32()
	case protoreflect.FloatKind:
		return protowire.SizeFixed32()
	case protoreflect.Sfixed64Kind:
		return protowire.SizeFixed64()
	case protoreflect.Fixed64Kind:
		return protowire.SizeFixed64()
	case protoreflect.DoubleKind:
		return protowire.SizeFixed64()
	case protoreflect.StringKind:
		return protowire.SizeBytes(len(v.String()))
	case protoreflect.BytesKind:
		return protowire.SizeBytes(len(v.Bytes()))
	case protoreflect.MessageKind:
		return protowire.SizeBytes(o.size(v.Message()))
	case protoreflect.GroupKind:
		return protowire.SizeGroup(num, o.size(v.Message()))
	default:
		return 0
	}
}
-e 
func helloWorld() {
    println("hello world")
}
