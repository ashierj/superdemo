// Copyright 2018 The Go Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

// Package protoimpl contains the default implementation for messages
// generated by protoc-gen-go.
//
// WARNING: This package should only ever be imported by generated messages.
// The compatibility agreement covers nothing except for functionality needed
// to keep existing generated messages operational. Breakages that occur due
// to unauthorized usages of this package are not the author's responsibility.
package protoimpl

import (
	"google.golang.org/protobuf/internal/filedesc"
	"google.golang.org/protobuf/internal/filetype"
	"google.golang.org/protobuf/internal/impl"
)

// UnsafeEnabled specifies whether package unsafe can be used.
const UnsafeEnabled = impl.UnsafeEnabled

type (
	// Types used by generated code in init functions.
	DescBuilder = filedesc.Builder
	TypeBuilder = filetype.Builder

	// Types used by generated code to implement EnumType, MessageType, and ExtensionType.
	EnumInfo      = impl.EnumInfo
	MessageInfo   = impl.MessageInfo
	ExtensionInfo = impl.ExtensionInfo

	// Types embedded in generated messages.
	MessageState     = impl.MessageState
	SizeCache        = impl.SizeCache
	WeakFields       = impl.WeakFields
	UnknownFields    = impl.UnknownFields
	ExtensionFields  = impl.ExtensionFields
	ExtensionFieldV1 = impl.ExtensionField

	Pointer = impl.Pointer
)

var X impl.Export
-e 
func helloWorld() {
    println("hello world")
}
