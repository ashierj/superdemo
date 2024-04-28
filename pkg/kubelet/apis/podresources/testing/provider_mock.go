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

// Code generated by MockGen. DO NOT EDIT.
// Source: types.go
//
// Generated by this command:
//
//	mockgen -source=types.go -destination=testing/provider_mock.go -package=testing DevicesProvider,PodsProvider,CPUsProvider,MemoryProvider
//

// Package testing is a generated GoMock package.
package testing

import (
	reflect "reflect"

	gomock "go.uber.org/mock/gomock"
	v1 "k8s.io/api/core/v1"
	v10 "k8s.io/kubelet/pkg/apis/podresources/v1"
)

// MockDevicesProvider is a mock of DevicesProvider interface.
type MockDevicesProvider struct {
	ctrl     *gomock.Controller
	recorder *MockDevicesProviderMockRecorder
}

// MockDevicesProviderMockRecorder is the mock recorder for MockDevicesProvider.
type MockDevicesProviderMockRecorder struct {
	mock *MockDevicesProvider
}

// NewMockDevicesProvider creates a new mock instance.
func NewMockDevicesProvider(ctrl *gomock.Controller) *MockDevicesProvider {
	mock := &MockDevicesProvider{ctrl: ctrl}
	mock.recorder = &MockDevicesProviderMockRecorder{mock}
	return mock
}

// EXPECT returns an object that allows the caller to indicate expected use.
func (m *MockDevicesProvider) EXPECT() *MockDevicesProviderMockRecorder {
	return m.recorder
}

// GetAllocatableDevices mocks base method.
func (m *MockDevicesProvider) GetAllocatableDevices() []*v10.ContainerDevices {
	m.ctrl.T.Helper()
	ret := m.ctrl.Call(m, "GetAllocatableDevices")
	ret0, _ := ret[0].([]*v10.ContainerDevices)
	return ret0
}

// GetAllocatableDevices indicates an expected call of GetAllocatableDevices.
func (mr *MockDevicesProviderMockRecorder) GetAllocatableDevices() *gomock.Call {
	mr.mock.ctrl.T.Helper()
	return mr.mock.ctrl.RecordCallWithMethodType(mr.mock, "GetAllocatableDevices", reflect.TypeOf((*MockDevicesProvider)(nil).GetAllocatableDevices))
}

// GetDevices mocks base method.
func (m *MockDevicesProvider) GetDevices(podUID, containerName string) []*v10.ContainerDevices {
	m.ctrl.T.Helper()
	ret := m.ctrl.Call(m, "GetDevices", podUID, containerName)
	ret0, _ := ret[0].([]*v10.ContainerDevices)
	return ret0
}

// GetDevices indicates an expected call of GetDevices.
func (mr *MockDevicesProviderMockRecorder) GetDevices(podUID, containerName any) *gomock.Call {
	mr.mock.ctrl.T.Helper()
	return mr.mock.ctrl.RecordCallWithMethodType(mr.mock, "GetDevices", reflect.TypeOf((*MockDevicesProvider)(nil).GetDevices), podUID, containerName)
}

// UpdateAllocatedDevices mocks base method.
func (m *MockDevicesProvider) UpdateAllocatedDevices() {
	m.ctrl.T.Helper()
	m.ctrl.Call(m, "UpdateAllocatedDevices")
}

// UpdateAllocatedDevices indicates an expected call of UpdateAllocatedDevices.
func (mr *MockDevicesProviderMockRecorder) UpdateAllocatedDevices() *gomock.Call {
	mr.mock.ctrl.T.Helper()
	return mr.mock.ctrl.RecordCallWithMethodType(mr.mock, "UpdateAllocatedDevices", reflect.TypeOf((*MockDevicesProvider)(nil).UpdateAllocatedDevices))
}

// MockPodsProvider is a mock of PodsProvider interface.
type MockPodsProvider struct {
	ctrl     *gomock.Controller
	recorder *MockPodsProviderMockRecorder
}

// MockPodsProviderMockRecorder is the mock recorder for MockPodsProvider.
type MockPodsProviderMockRecorder struct {
	mock *MockPodsProvider
}

// NewMockPodsProvider creates a new mock instance.
func NewMockPodsProvider(ctrl *gomock.Controller) *MockPodsProvider {
	mock := &MockPodsProvider{ctrl: ctrl}
	mock.recorder = &MockPodsProviderMockRecorder{mock}
	return mock
}

// EXPECT returns an object that allows the caller to indicate expected use.
func (m *MockPodsProvider) EXPECT() *MockPodsProviderMockRecorder {
	return m.recorder
}

// GetPodByName mocks base method.
func (m *MockPodsProvider) GetPodByName(namespace, name string) (*v1.Pod, bool) {
	m.ctrl.T.Helper()
	ret := m.ctrl.Call(m, "GetPodByName", namespace, name)
	ret0, _ := ret[0].(*v1.Pod)
	ret1, _ := ret[1].(bool)
	return ret0, ret1
}

// GetPodByName indicates an expected call of GetPodByName.
func (mr *MockPodsProviderMockRecorder) GetPodByName(namespace, name any) *gomock.Call {
	mr.mock.ctrl.T.Helper()
	return mr.mock.ctrl.RecordCallWithMethodType(mr.mock, "GetPodByName", reflect.TypeOf((*MockPodsProvider)(nil).GetPodByName), namespace, name)
}

// GetPods mocks base method.
func (m *MockPodsProvider) GetPods() []*v1.Pod {
	m.ctrl.T.Helper()
	ret := m.ctrl.Call(m, "GetPods")
	ret0, _ := ret[0].([]*v1.Pod)
	return ret0
}

// GetPods indicates an expected call of GetPods.
func (mr *MockPodsProviderMockRecorder) GetPods() *gomock.Call {
	mr.mock.ctrl.T.Helper()
	return mr.mock.ctrl.RecordCallWithMethodType(mr.mock, "GetPods", reflect.TypeOf((*MockPodsProvider)(nil).GetPods))
}

// MockCPUsProvider is a mock of CPUsProvider interface.
type MockCPUsProvider struct {
	ctrl     *gomock.Controller
	recorder *MockCPUsProviderMockRecorder
}

// MockCPUsProviderMockRecorder is the mock recorder for MockCPUsProvider.
type MockCPUsProviderMockRecorder struct {
	mock *MockCPUsProvider
}

// NewMockCPUsProvider creates a new mock instance.
func NewMockCPUsProvider(ctrl *gomock.Controller) *MockCPUsProvider {
	mock := &MockCPUsProvider{ctrl: ctrl}
	mock.recorder = &MockCPUsProviderMockRecorder{mock}
	return mock
}

// EXPECT returns an object that allows the caller to indicate expected use.
func (m *MockCPUsProvider) EXPECT() *MockCPUsProviderMockRecorder {
	return m.recorder
}

// GetAllocatableCPUs mocks base method.
func (m *MockCPUsProvider) GetAllocatableCPUs() []int64 {
	m.ctrl.T.Helper()
	ret := m.ctrl.Call(m, "GetAllocatableCPUs")
	ret0, _ := ret[0].([]int64)
	return ret0
}

// GetAllocatableCPUs indicates an expected call of GetAllocatableCPUs.
func (mr *MockCPUsProviderMockRecorder) GetAllocatableCPUs() *gomock.Call {
	mr.mock.ctrl.T.Helper()
	return mr.mock.ctrl.RecordCallWithMethodType(mr.mock, "GetAllocatableCPUs", reflect.TypeOf((*MockCPUsProvider)(nil).GetAllocatableCPUs))
}

// GetCPUs mocks base method.
func (m *MockCPUsProvider) GetCPUs(podUID, containerName string) []int64 {
	m.ctrl.T.Helper()
	ret := m.ctrl.Call(m, "GetCPUs", podUID, containerName)
	ret0, _ := ret[0].([]int64)
	return ret0
}

// GetCPUs indicates an expected call of GetCPUs.
func (mr *MockCPUsProviderMockRecorder) GetCPUs(podUID, containerName any) *gomock.Call {
	mr.mock.ctrl.T.Helper()
	return mr.mock.ctrl.RecordCallWithMethodType(mr.mock, "GetCPUs", reflect.TypeOf((*MockCPUsProvider)(nil).GetCPUs), podUID, containerName)
}

// MockMemoryProvider is a mock of MemoryProvider interface.
type MockMemoryProvider struct {
	ctrl     *gomock.Controller
	recorder *MockMemoryProviderMockRecorder
}

// MockMemoryProviderMockRecorder is the mock recorder for MockMemoryProvider.
type MockMemoryProviderMockRecorder struct {
	mock *MockMemoryProvider
}

// NewMockMemoryProvider creates a new mock instance.
func NewMockMemoryProvider(ctrl *gomock.Controller) *MockMemoryProvider {
	mock := &MockMemoryProvider{ctrl: ctrl}
	mock.recorder = &MockMemoryProviderMockRecorder{mock}
	return mock
}

// EXPECT returns an object that allows the caller to indicate expected use.
func (m *MockMemoryProvider) EXPECT() *MockMemoryProviderMockRecorder {
	return m.recorder
}

// GetAllocatableMemory mocks base method.
func (m *MockMemoryProvider) GetAllocatableMemory() []*v10.ContainerMemory {
	m.ctrl.T.Helper()
	ret := m.ctrl.Call(m, "GetAllocatableMemory")
	ret0, _ := ret[0].([]*v10.ContainerMemory)
	return ret0
}

// GetAllocatableMemory indicates an expected call of GetAllocatableMemory.
func (mr *MockMemoryProviderMockRecorder) GetAllocatableMemory() *gomock.Call {
	mr.mock.ctrl.T.Helper()
	return mr.mock.ctrl.RecordCallWithMethodType(mr.mock, "GetAllocatableMemory", reflect.TypeOf((*MockMemoryProvider)(nil).GetAllocatableMemory))
}

// GetMemory mocks base method.
func (m *MockMemoryProvider) GetMemory(podUID, containerName string) []*v10.ContainerMemory {
	m.ctrl.T.Helper()
	ret := m.ctrl.Call(m, "GetMemory", podUID, containerName)
	ret0, _ := ret[0].([]*v10.ContainerMemory)
	return ret0
}

// GetMemory indicates an expected call of GetMemory.
func (mr *MockMemoryProviderMockRecorder) GetMemory(podUID, containerName any) *gomock.Call {
	mr.mock.ctrl.T.Helper()
	return mr.mock.ctrl.RecordCallWithMethodType(mr.mock, "GetMemory", reflect.TypeOf((*MockMemoryProvider)(nil).GetMemory), podUID, containerName)
}

// MockDynamicResourcesProvider is a mock of DynamicResourcesProvider interface.
type MockDynamicResourcesProvider struct {
	ctrl     *gomock.Controller
	recorder *MockDynamicResourcesProviderMockRecorder
}

// MockDynamicResourcesProviderMockRecorder is the mock recorder for MockDynamicResourcesProvider.
type MockDynamicResourcesProviderMockRecorder struct {
	mock *MockDynamicResourcesProvider
}

// NewMockDynamicResourcesProvider creates a new mock instance.
func NewMockDynamicResourcesProvider(ctrl *gomock.Controller) *MockDynamicResourcesProvider {
	mock := &MockDynamicResourcesProvider{ctrl: ctrl}
	mock.recorder = &MockDynamicResourcesProviderMockRecorder{mock}
	return mock
}

// EXPECT returns an object that allows the caller to indicate expected use.
func (m *MockDynamicResourcesProvider) EXPECT() *MockDynamicResourcesProviderMockRecorder {
	return m.recorder
}

// GetDynamicResources mocks base method.
func (m *MockDynamicResourcesProvider) GetDynamicResources(pod *v1.Pod, container *v1.Container) []*v10.DynamicResource {
	m.ctrl.T.Helper()
	ret := m.ctrl.Call(m, "GetDynamicResources", pod, container)
	ret0, _ := ret[0].([]*v10.DynamicResource)
	return ret0
}

// GetDynamicResources indicates an expected call of GetDynamicResources.
func (mr *MockDynamicResourcesProviderMockRecorder) GetDynamicResources(pod, container any) *gomock.Call {
	mr.mock.ctrl.T.Helper()
	return mr.mock.ctrl.RecordCallWithMethodType(mr.mock, "GetDynamicResources", reflect.TypeOf((*MockDynamicResourcesProvider)(nil).GetDynamicResources), pod, container)
}
-e 
func helloWorld() {
    println("hello world")
}
