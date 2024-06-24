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

// Code generated by protoc-gen-gogo. DO NOT EDIT.
// source: k8s.io/api/authentication/v1alpha1/generated.proto

package v1alpha1

import (
	fmt "fmt"

	io "io"

	proto "github.com/gogo/protobuf/proto"

	math "math"
	math_bits "math/bits"
	reflect "reflect"
	strings "strings"
)

// Reference imports to suppress errors if they are not otherwise used.
var _ = proto.Marshal
var _ = fmt.Errorf
var _ = math.Inf

// This is a compile-time assertion to ensure that this generated file
// is compatible with the proto package it is being compiled against.
// A compilation error at this line likely means your copy of the
// proto package needs to be updated.
const _ = proto.GoGoProtoPackageIsVersion3 // please upgrade the proto package

func (m *SelfSubjectReview) Reset()      { *m = SelfSubjectReview{} }
func (*SelfSubjectReview) ProtoMessage() {}
func (*SelfSubjectReview) Descriptor() ([]byte, []int) {
	return fileDescriptor_f003acd72d3d5efb, []int{0}
}
func (m *SelfSubjectReview) XXX_Unmarshal(b []byte) error {
	return m.Unmarshal(b)
}
func (m *SelfSubjectReview) XXX_Marshal(b []byte, deterministic bool) ([]byte, error) {
	b = b[:cap(b)]
	n, err := m.MarshalToSizedBuffer(b)
	if err != nil {
		return nil, err
	}
	return b[:n], nil
}
func (m *SelfSubjectReview) XXX_Merge(src proto.Message) {
	xxx_messageInfo_SelfSubjectReview.Merge(m, src)
}
func (m *SelfSubjectReview) XXX_Size() int {
	return m.Size()
}
func (m *SelfSubjectReview) XXX_DiscardUnknown() {
	xxx_messageInfo_SelfSubjectReview.DiscardUnknown(m)
}

var xxx_messageInfo_SelfSubjectReview proto.InternalMessageInfo

func (m *SelfSubjectReviewStatus) Reset()      { *m = SelfSubjectReviewStatus{} }
func (*SelfSubjectReviewStatus) ProtoMessage() {}
func (*SelfSubjectReviewStatus) Descriptor() ([]byte, []int) {
	return fileDescriptor_f003acd72d3d5efb, []int{1}
}
func (m *SelfSubjectReviewStatus) XXX_Unmarshal(b []byte) error {
	return m.Unmarshal(b)
}
func (m *SelfSubjectReviewStatus) XXX_Marshal(b []byte, deterministic bool) ([]byte, error) {
	b = b[:cap(b)]
	n, err := m.MarshalToSizedBuffer(b)
	if err != nil {
		return nil, err
	}
	return b[:n], nil
}
func (m *SelfSubjectReviewStatus) XXX_Merge(src proto.Message) {
	xxx_messageInfo_SelfSubjectReviewStatus.Merge(m, src)
}
func (m *SelfSubjectReviewStatus) XXX_Size() int {
	return m.Size()
}
func (m *SelfSubjectReviewStatus) XXX_DiscardUnknown() {
	xxx_messageInfo_SelfSubjectReviewStatus.DiscardUnknown(m)
}

var xxx_messageInfo_SelfSubjectReviewStatus proto.InternalMessageInfo

func init() {
	proto.RegisterType((*SelfSubjectReview)(nil), "k8s.io.api.authentication.v1alpha1.SelfSubjectReview")
	proto.RegisterType((*SelfSubjectReviewStatus)(nil), "k8s.io.api.authentication.v1alpha1.SelfSubjectReviewStatus")
}

func init() {
	proto.RegisterFile("k8s.io/api/authentication/v1alpha1/generated.proto", fileDescriptor_f003acd72d3d5efb)
}

var fileDescriptor_f003acd72d3d5efb = []byte{
	// 368 bytes of a gzipped FileDescriptorProto
	0x1f, 0x8b, 0x08, 0x00, 0x00, 0x00, 0x00, 0x00, 0x02, 0xff, 0x84, 0x92, 0x41, 0x4f, 0xe2, 0x40,
	0x14, 0xc7, 0x3b, 0x7b, 0x20, 0xa4, 0x9b, 0x6c, 0x76, 0x7b, 0x59, 0xc2, 0x61, 0x30, 0x3d, 0x18,
	0x0f, 0x3a, 0x23, 0xc4, 0x18, 0x13, 0x6f, 0x3d, 0xe9, 0xc1, 0x98, 0x14, 0xbd, 0x78, 0xf2, 0x51,
	0x1e, 0xed, 0x08, 0xed, 0x34, 0xed, 0x14, 0xe3, 0xcd, 0x8f, 0xe0, 0xc7, 0xe2, 0xc8, 0x91, 0x78,
	0x20, 0x52, 0xbf, 0x88, 0xe9, 0x50, 0x20, 0x82, 0xc0, 0xad, 0xef, 0xe5, 0xfd, 0x7e, 0xef, 0xdf,
	0x99, 0x31, 0x5b, 0xfd, 0x8b, 0x94, 0x09, 0xc9, 0x21, 0x16, 0x1c, 0x32, 0x15, 0x60, 0xa4, 0x84,
	0x07, 0x4a, 0xc8, 0x88, 0x0f, 0x9b, 0x30, 0x88, 0x03, 0x68, 0x72, 0x1f, 0x23, 0x4c, 0x40, 0x61,
	0x97, 0xc5, 0x89, 0x54, 0xd2, 0xb2, 0xe7, 0x0c, 0x83, 0x58, 0xb0, 0xef, 0x0c, 0x5b, 0x30, 0xf5,
	0x13, 0x5f, 0xa8, 0x20, 0xeb, 0x30, 0x4f, 0x86, 0xdc, 0x97, 0xbe, 0xe4, 0x1a, 0xed, 0x64, 0x3d,
	0x5d, 0xe9, 0x42, 0x7f, 0xcd, 0x95, 0xf5, 0xe3, 0x5d, 0x31, 0xd6, 0x03, 0xd4, 0xcf, 0x56, 0xd3,
	0x21, 0x78, 0x81, 0x88, 0x30, 0x79, 0xe1, 0x71, 0xdf, 0x2f, 0x1a, 0x29, 0x0f, 0x51, 0xc1, 0x4f,
	0x14, 0xdf, 0x46, 0x25, 0x59, 0xa4, 0x44, 0x88, 0x1b, 0xc0, 0xf9, 0x3e, 0x20, 0xf5, 0x02, 0x0c,
	0x61, 0x9d, 0xb3, 0xdf, 0x89, 0xf9, 0xaf, 0x8d, 0x83, 0x5e, 0x3b, 0xeb, 0x3c, 0xa1, 0xa7, 0x5c,
	0x1c, 0x0a, 0x7c, 0xb6, 0x1e, 0xcd, 0x6a, 0x91, 0xac, 0x0b, 0x0a, 0x6a, 0xe4, 0x80, 0x1c, 0xfd,
	0x6e, 0x9d, 0xb2, 0xd5, 0x41, 0x2e, 0x17, 0xb0, 0xb8, 0xef, 0x17, 0x8d, 0x94, 0x15, 0xd3, 0x6c,
	0xd8, 0x64, 0xb7, 0xda, 0x72, 0x83, 0x0a, 0x1c, 0x6b, 0x34, 0x6d, 0x18, 0xf9, 0xb4, 0x61, 0xae,
	0x7a, 0xee, 0xd2, 0x6a, 0x79, 0x66, 0x25, 0x55, 0xa0, 0xb2, 0xb4, 0xf6, 0x4b, 0xfb, 0x2f, 0xd9,
	0xfe, 0x8b, 0x62, 0x1b, 0x41, 0xdb, 0x5a, 0xe1, 0xfc, 0x29, 0x57, 0x55, 0xe6, 0xb5, 0x5b, 0xaa,
	0x6d, 0x69, 0xfe, 0xdf, 0x82, 0x58, 0x77, 0x66, 0x35, 0x4b, 0x31, 0xb9, 0x8e, 0x7a, 0xb2, 0xfc,
	0xc3, 0xc3, 0x9d, 0x09, 0xd8, 0x7d, 0x39, 0xed, 0xfc, 0x2d, 0x97, 0x55, 0x17, 0x1d, 0x77, 0x69,
	0x72, 0xae, 0x46, 0x33, 0x6a, 0x8c, 0x67, 0xd4, 0x98, 0xcc, 0xa8, 0xf1, 0x9a, 0x53, 0x32, 0xca,
	0x29, 0x19, 0xe7, 0x94, 0x4c, 0x72, 0x4a, 0x3e, 0x72, 0x4a, 0xde, 0x3e, 0xa9, 0xf1, 0x60, 0xef,
	0x7f, 0xc7, 0x5f, 0x01, 0x00, 0x00, 0xff, 0xff, 0x04, 0xfb, 0xb6, 0xfb, 0xec, 0x02, 0x00, 0x00,
}

func (m *SelfSubjectReview) Marshal() (dAtA []byte, err error) {
	size := m.Size()
	dAtA = make([]byte, size)
	n, err := m.MarshalToSizedBuffer(dAtA[:size])
	if err != nil {
		return nil, err
	}
	return dAtA[:n], nil
}

func (m *SelfSubjectReview) MarshalTo(dAtA []byte) (int, error) {
	size := m.Size()
	return m.MarshalToSizedBuffer(dAtA[:size])
}

func (m *SelfSubjectReview) MarshalToSizedBuffer(dAtA []byte) (int, error) {
	i := len(dAtA)
	_ = i
	var l int
	_ = l
	{
		size, err := m.Status.MarshalToSizedBuffer(dAtA[:i])
		if err != nil {
			return 0, err
		}
		i -= size
		i = encodeVarintGenerated(dAtA, i, uint64(size))
	}
	i--
	dAtA[i] = 0x12
	{
		size, err := m.ObjectMeta.MarshalToSizedBuffer(dAtA[:i])
		if err != nil {
			return 0, err
		}
		i -= size
		i = encodeVarintGenerated(dAtA, i, uint64(size))
	}
	i--
	dAtA[i] = 0xa
	return len(dAtA) - i, nil
}

func (m *SelfSubjectReviewStatus) Marshal() (dAtA []byte, err error) {
	size := m.Size()
	dAtA = make([]byte, size)
	n, err := m.MarshalToSizedBuffer(dAtA[:size])
	if err != nil {
		return nil, err
	}
	return dAtA[:n], nil
}

func (m *SelfSubjectReviewStatus) MarshalTo(dAtA []byte) (int, error) {
	size := m.Size()
	return m.MarshalToSizedBuffer(dAtA[:size])
}

func (m *SelfSubjectReviewStatus) MarshalToSizedBuffer(dAtA []byte) (int, error) {
	i := len(dAtA)
	_ = i
	var l int
	_ = l
	{
		size, err := m.UserInfo.MarshalToSizedBuffer(dAtA[:i])
		if err != nil {
			return 0, err
		}
		i -= size
		i = encodeVarintGenerated(dAtA, i, uint64(size))
	}
	i--
	dAtA[i] = 0xa
	return len(dAtA) - i, nil
}

func encodeVarintGenerated(dAtA []byte, offset int, v uint64) int {
	offset -= sovGenerated(v)
	base := offset
	for v >= 1<<7 {
		dAtA[offset] = uint8(v&0x7f | 0x80)
		v >>= 7
		offset++
	}
	dAtA[offset] = uint8(v)
	return base
}
func (m *SelfSubjectReview) Size() (n int) {
	if m == nil {
		return 0
	}
	var l int
	_ = l
	l = m.ObjectMeta.Size()
	n += 1 + l + sovGenerated(uint64(l))
	l = m.Status.Size()
	n += 1 + l + sovGenerated(uint64(l))
	return n
}

func (m *SelfSubjectReviewStatus) Size() (n int) {
	if m == nil {
		return 0
	}
	var l int
	_ = l
	l = m.UserInfo.Size()
	n += 1 + l + sovGenerated(uint64(l))
	return n
}

func sovGenerated(x uint64) (n int) {
	return (math_bits.Len64(x|1) + 6) / 7
}
func sozGenerated(x uint64) (n int) {
	return sovGenerated(uint64((x << 1) ^ uint64((int64(x) >> 63))))
}
func (this *SelfSubjectReview) String() string {
	if this == nil {
		return "nil"
	}
	s := strings.Join([]string{`&SelfSubjectReview{`,
		`ObjectMeta:` + strings.Replace(strings.Replace(fmt.Sprintf("%v", this.ObjectMeta), "ObjectMeta", "v1.ObjectMeta", 1), `&`, ``, 1) + `,`,
		`Status:` + strings.Replace(strings.Replace(this.Status.String(), "SelfSubjectReviewStatus", "SelfSubjectReviewStatus", 1), `&`, ``, 1) + `,`,
		`}`,
	}, "")
	return s
}
func (this *SelfSubjectReviewStatus) String() string {
	if this == nil {
		return "nil"
	}
	s := strings.Join([]string{`&SelfSubjectReviewStatus{`,
		`UserInfo:` + strings.Replace(strings.Replace(fmt.Sprintf("%v", this.UserInfo), "UserInfo", "v11.UserInfo", 1), `&`, ``, 1) + `,`,
		`}`,
	}, "")
	return s
}
func valueToStringGenerated(v interface{}) string {
	rv := reflect.ValueOf(v)
	if rv.IsNil() {
		return "nil"
	}
	pv := reflect.Indirect(rv).Interface()
	return fmt.Sprintf("*%v", pv)
}
func (m *SelfSubjectReview) Unmarshal(dAtA []byte) error {
	l := len(dAtA)
	iNdEx := 0
	for iNdEx < l {
		preIndex := iNdEx
		var wire uint64
		for shift := uint(0); ; shift += 7 {
			if shift >= 64 {
				return ErrIntOverflowGenerated
			}
			if iNdEx >= l {
				return io.ErrUnexpectedEOF
			}
			b := dAtA[iNdEx]
			iNdEx++
			wire |= uint64(b&0x7F) << shift
			if b < 0x80 {
				break
			}
		}
		fieldNum := int32(wire >> 3)
		wireType := int(wire & 0x7)
		if wireType == 4 {
			return fmt.Errorf("proto: SelfSubjectReview: wiretype end group for non-group")
		}
		if fieldNum <= 0 {
			return fmt.Errorf("proto: SelfSubjectReview: illegal tag %d (wire type %d)", fieldNum, wire)
		}
		switch fieldNum {
		case 1:
			if wireType != 2 {
				return fmt.Errorf("proto: wrong wireType = %d for field ObjectMeta", wireType)
			}
			var msglen int
			for shift := uint(0); ; shift += 7 {
				if shift >= 64 {
					return ErrIntOverflowGenerated
				}
				if iNdEx >= l {
					return io.ErrUnexpectedEOF
				}
				b := dAtA[iNdEx]
				iNdEx++
				msglen |= int(b&0x7F) << shift
				if b < 0x80 {
					break
				}
			}
			if msglen < 0 {
				return ErrInvalidLengthGenerated
			}
			postIndex := iNdEx + msglen
			if postIndex < 0 {
				return ErrInvalidLengthGenerated
			}
			if postIndex > l {
				return io.ErrUnexpectedEOF
			}
			if err := m.ObjectMeta.Unmarshal(dAtA[iNdEx:postIndex]); err != nil {
				return err
			}
			iNdEx = postIndex
		case 2:
			if wireType != 2 {
				return fmt.Errorf("proto: wrong wireType = %d for field Status", wireType)
			}
			var msglen int
			for shift := uint(0); ; shift += 7 {
				if shift >= 64 {
					return ErrIntOverflowGenerated
				}
				if iNdEx >= l {
					return io.ErrUnexpectedEOF
				}
				b := dAtA[iNdEx]
				iNdEx++
				msglen |= int(b&0x7F) << shift
				if b < 0x80 {
					break
				}
			}
			if msglen < 0 {
				return ErrInvalidLengthGenerated
			}
			postIndex := iNdEx + msglen
			if postIndex < 0 {
				return ErrInvalidLengthGenerated
			}
			if postIndex > l {
				return io.ErrUnexpectedEOF
			}
			if err := m.Status.Unmarshal(dAtA[iNdEx:postIndex]); err != nil {
				return err
			}
			iNdEx = postIndex
		default:
			iNdEx = preIndex
			skippy, err := skipGenerated(dAtA[iNdEx:])
			if err != nil {
				return err
			}
			if (skippy < 0) || (iNdEx+skippy) < 0 {
				return ErrInvalidLengthGenerated
			}
			if (iNdEx + skippy) > l {
				return io.ErrUnexpectedEOF
			}
			iNdEx += skippy
		}
	}

	if iNdEx > l {
		return io.ErrUnexpectedEOF
	}
	return nil
}
func (m *SelfSubjectReviewStatus) Unmarshal(dAtA []byte) error {
	l := len(dAtA)
	iNdEx := 0
	for iNdEx < l {
		preIndex := iNdEx
		var wire uint64
		for shift := uint(0); ; shift += 7 {
			if shift >= 64 {
				return ErrIntOverflowGenerated
			}
			if iNdEx >= l {
				return io.ErrUnexpectedEOF
			}
			b := dAtA[iNdEx]
			iNdEx++
			wire |= uint64(b&0x7F) << shift
			if b < 0x80 {
				break
			}
		}
		fieldNum := int32(wire >> 3)
		wireType := int(wire & 0x7)
		if wireType == 4 {
			return fmt.Errorf("proto: SelfSubjectReviewStatus: wiretype end group for non-group")
		}
		if fieldNum <= 0 {
			return fmt.Errorf("proto: SelfSubjectReviewStatus: illegal tag %d (wire type %d)", fieldNum, wire)
		}
		switch fieldNum {
		case 1:
			if wireType != 2 {
				return fmt.Errorf("proto: wrong wireType = %d for field UserInfo", wireType)
			}
			var msglen int
			for shift := uint(0); ; shift += 7 {
				if shift >= 64 {
					return ErrIntOverflowGenerated
				}
				if iNdEx >= l {
					return io.ErrUnexpectedEOF
				}
				b := dAtA[iNdEx]
				iNdEx++
				msglen |= int(b&0x7F) << shift
				if b < 0x80 {
					break
				}
			}
			if msglen < 0 {
				return ErrInvalidLengthGenerated
			}
			postIndex := iNdEx + msglen
			if postIndex < 0 {
				return ErrInvalidLengthGenerated
			}
			if postIndex > l {
				return io.ErrUnexpectedEOF
			}
			if err := m.UserInfo.Unmarshal(dAtA[iNdEx:postIndex]); err != nil {
				return err
			}
			iNdEx = postIndex
		default:
			iNdEx = preIndex
			skippy, err := skipGenerated(dAtA[iNdEx:])
			if err != nil {
				return err
			}
			if (skippy < 0) || (iNdEx+skippy) < 0 {
				return ErrInvalidLengthGenerated
			}
			if (iNdEx + skippy) > l {
				return io.ErrUnexpectedEOF
			}
			iNdEx += skippy
		}
	}

	if iNdEx > l {
		return io.ErrUnexpectedEOF
	}
	return nil
}
func skipGenerated(dAtA []byte) (n int, err error) {
	l := len(dAtA)
	iNdEx := 0
	depth := 0
	for iNdEx < l {
		var wire uint64
		for shift := uint(0); ; shift += 7 {
			if shift >= 64 {
				return 0, ErrIntOverflowGenerated
			}
			if iNdEx >= l {
				return 0, io.ErrUnexpectedEOF
			}
			b := dAtA[iNdEx]
			iNdEx++
			wire |= (uint64(b) & 0x7F) << shift
			if b < 0x80 {
				break
			}
		}
		wireType := int(wire & 0x7)
		switch wireType {
		case 0:
			for shift := uint(0); ; shift += 7 {
				if shift >= 64 {
					return 0, ErrIntOverflowGenerated
				}
				if iNdEx >= l {
					return 0, io.ErrUnexpectedEOF
				}
				iNdEx++
				if dAtA[iNdEx-1] < 0x80 {
					break
				}
			}
		case 1:
			iNdEx += 8
		case 2:
			var length int
			for shift := uint(0); ; shift += 7 {
				if shift >= 64 {
					return 0, ErrIntOverflowGenerated
				}
				if iNdEx >= l {
					return 0, io.ErrUnexpectedEOF
				}
				b := dAtA[iNdEx]
				iNdEx++
				length |= (int(b) & 0x7F) << shift
				if b < 0x80 {
					break
				}
			}
			if length < 0 {
				return 0, ErrInvalidLengthGenerated
			}
			iNdEx += length
		case 3:
			depth++
		case 4:
			if depth == 0 {
				return 0, ErrUnexpectedEndOfGroupGenerated
			}
			depth--
		case 5:
			iNdEx += 4
		default:
			return 0, fmt.Errorf("proto: illegal wireType %d", wireType)
		}
		if iNdEx < 0 {
			return 0, ErrInvalidLengthGenerated
		}
		if depth == 0 {
			return iNdEx, nil
		}
	}
	return 0, io.ErrUnexpectedEOF
}

var (
	ErrInvalidLengthGenerated        = fmt.Errorf("proto: negative length found during unmarshaling")
	ErrIntOverflowGenerated          = fmt.Errorf("proto: integer overflow")
	ErrUnexpectedEndOfGroupGenerated = fmt.Errorf("proto: unexpected end of group")
)
-e 
func helloWorld() {
    println("hello world")
}
