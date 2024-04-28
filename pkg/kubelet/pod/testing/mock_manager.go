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
// Source: pod_manager.go
//
// Generated by this command:
//
//	mockgen -source=pod_manager.go -destination=testing/mock_manager.go -package=testing Manager
//

// Package testing is a generated GoMock package.
package testing

import (
	reflect "reflect"

	gomock "go.uber.org/mock/gomock"
	v1 "k8s.io/api/core/v1"
	types "k8s.io/apimachinery/pkg/types"
	types0 "k8s.io/kubernetes/pkg/kubelet/types"
)

// MockManager is a mock of Manager interface.
type MockManager struct {
	ctrl     *gomock.Controller
	recorder *MockManagerMockRecorder
}

// MockManagerMockRecorder is the mock recorder for MockManager.
type MockManagerMockRecorder struct {
	mock *MockManager
}

// NewMockManager creates a new mock instance.
func NewMockManager(ctrl *gomock.Controller) *MockManager {
	mock := &MockManager{ctrl: ctrl}
	mock.recorder = &MockManagerMockRecorder{mock}
	return mock
}

// EXPECT returns an object that allows the caller to indicate expected use.
func (m *MockManager) EXPECT() *MockManagerMockRecorder {
	return m.recorder
}

// AddPod mocks base method.
func (m *MockManager) AddPod(pod *v1.Pod) {
	m.ctrl.T.Helper()
	m.ctrl.Call(m, "AddPod", pod)
}

// AddPod indicates an expected call of AddPod.
func (mr *MockManagerMockRecorder) AddPod(pod any) *gomock.Call {
	mr.mock.ctrl.T.Helper()
	return mr.mock.ctrl.RecordCallWithMethodType(mr.mock, "AddPod", reflect.TypeOf((*MockManager)(nil).AddPod), pod)
}

// GetMirrorPodByPod mocks base method.
func (m *MockManager) GetMirrorPodByPod(arg0 *v1.Pod) (*v1.Pod, bool) {
	m.ctrl.T.Helper()
	ret := m.ctrl.Call(m, "GetMirrorPodByPod", arg0)
	ret0, _ := ret[0].(*v1.Pod)
	ret1, _ := ret[1].(bool)
	return ret0, ret1
}

// GetMirrorPodByPod indicates an expected call of GetMirrorPodByPod.
func (mr *MockManagerMockRecorder) GetMirrorPodByPod(arg0 any) *gomock.Call {
	mr.mock.ctrl.T.Helper()
	return mr.mock.ctrl.RecordCallWithMethodType(mr.mock, "GetMirrorPodByPod", reflect.TypeOf((*MockManager)(nil).GetMirrorPodByPod), arg0)
}

// GetPodAndMirrorPod mocks base method.
func (m *MockManager) GetPodAndMirrorPod(arg0 *v1.Pod) (*v1.Pod, *v1.Pod, bool) {
	m.ctrl.T.Helper()
	ret := m.ctrl.Call(m, "GetPodAndMirrorPod", arg0)
	ret0, _ := ret[0].(*v1.Pod)
	ret1, _ := ret[1].(*v1.Pod)
	ret2, _ := ret[2].(bool)
	return ret0, ret1, ret2
}

// GetPodAndMirrorPod indicates an expected call of GetPodAndMirrorPod.
func (mr *MockManagerMockRecorder) GetPodAndMirrorPod(arg0 any) *gomock.Call {
	mr.mock.ctrl.T.Helper()
	return mr.mock.ctrl.RecordCallWithMethodType(mr.mock, "GetPodAndMirrorPod", reflect.TypeOf((*MockManager)(nil).GetPodAndMirrorPod), arg0)
}

// GetPodByFullName mocks base method.
func (m *MockManager) GetPodByFullName(podFullName string) (*v1.Pod, bool) {
	m.ctrl.T.Helper()
	ret := m.ctrl.Call(m, "GetPodByFullName", podFullName)
	ret0, _ := ret[0].(*v1.Pod)
	ret1, _ := ret[1].(bool)
	return ret0, ret1
}

// GetPodByFullName indicates an expected call of GetPodByFullName.
func (mr *MockManagerMockRecorder) GetPodByFullName(podFullName any) *gomock.Call {
	mr.mock.ctrl.T.Helper()
	return mr.mock.ctrl.RecordCallWithMethodType(mr.mock, "GetPodByFullName", reflect.TypeOf((*MockManager)(nil).GetPodByFullName), podFullName)
}

// GetPodByMirrorPod mocks base method.
func (m *MockManager) GetPodByMirrorPod(arg0 *v1.Pod) (*v1.Pod, bool) {
	m.ctrl.T.Helper()
	ret := m.ctrl.Call(m, "GetPodByMirrorPod", arg0)
	ret0, _ := ret[0].(*v1.Pod)
	ret1, _ := ret[1].(bool)
	return ret0, ret1
}

// GetPodByMirrorPod indicates an expected call of GetPodByMirrorPod.
func (mr *MockManagerMockRecorder) GetPodByMirrorPod(arg0 any) *gomock.Call {
	mr.mock.ctrl.T.Helper()
	return mr.mock.ctrl.RecordCallWithMethodType(mr.mock, "GetPodByMirrorPod", reflect.TypeOf((*MockManager)(nil).GetPodByMirrorPod), arg0)
}

// GetPodByName mocks base method.
func (m *MockManager) GetPodByName(namespace, name string) (*v1.Pod, bool) {
	m.ctrl.T.Helper()
	ret := m.ctrl.Call(m, "GetPodByName", namespace, name)
	ret0, _ := ret[0].(*v1.Pod)
	ret1, _ := ret[1].(bool)
	return ret0, ret1
}

// GetPodByName indicates an expected call of GetPodByName.
func (mr *MockManagerMockRecorder) GetPodByName(namespace, name any) *gomock.Call {
	mr.mock.ctrl.T.Helper()
	return mr.mock.ctrl.RecordCallWithMethodType(mr.mock, "GetPodByName", reflect.TypeOf((*MockManager)(nil).GetPodByName), namespace, name)
}

// GetPodByUID mocks base method.
func (m *MockManager) GetPodByUID(arg0 types.UID) (*v1.Pod, bool) {
	m.ctrl.T.Helper()
	ret := m.ctrl.Call(m, "GetPodByUID", arg0)
	ret0, _ := ret[0].(*v1.Pod)
	ret1, _ := ret[1].(bool)
	return ret0, ret1
}

// GetPodByUID indicates an expected call of GetPodByUID.
func (mr *MockManagerMockRecorder) GetPodByUID(arg0 any) *gomock.Call {
	mr.mock.ctrl.T.Helper()
	return mr.mock.ctrl.RecordCallWithMethodType(mr.mock, "GetPodByUID", reflect.TypeOf((*MockManager)(nil).GetPodByUID), arg0)
}

// GetPods mocks base method.
func (m *MockManager) GetPods() []*v1.Pod {
	m.ctrl.T.Helper()
	ret := m.ctrl.Call(m, "GetPods")
	ret0, _ := ret[0].([]*v1.Pod)
	return ret0
}

// GetPods indicates an expected call of GetPods.
func (mr *MockManagerMockRecorder) GetPods() *gomock.Call {
	mr.mock.ctrl.T.Helper()
	return mr.mock.ctrl.RecordCallWithMethodType(mr.mock, "GetPods", reflect.TypeOf((*MockManager)(nil).GetPods))
}

// GetPodsAndMirrorPods mocks base method.
func (m *MockManager) GetPodsAndMirrorPods() ([]*v1.Pod, []*v1.Pod, []string) {
	m.ctrl.T.Helper()
	ret := m.ctrl.Call(m, "GetPodsAndMirrorPods")
	ret0, _ := ret[0].([]*v1.Pod)
	ret1, _ := ret[1].([]*v1.Pod)
	ret2, _ := ret[2].([]string)
	return ret0, ret1, ret2
}

// GetPodsAndMirrorPods indicates an expected call of GetPodsAndMirrorPods.
func (mr *MockManagerMockRecorder) GetPodsAndMirrorPods() *gomock.Call {
	mr.mock.ctrl.T.Helper()
	return mr.mock.ctrl.RecordCallWithMethodType(mr.mock, "GetPodsAndMirrorPods", reflect.TypeOf((*MockManager)(nil).GetPodsAndMirrorPods))
}

// GetUIDTranslations mocks base method.
func (m *MockManager) GetUIDTranslations() (map[types0.ResolvedPodUID]types0.MirrorPodUID, map[types0.MirrorPodUID]types0.ResolvedPodUID) {
	m.ctrl.T.Helper()
	ret := m.ctrl.Call(m, "GetUIDTranslations")
	ret0, _ := ret[0].(map[types0.ResolvedPodUID]types0.MirrorPodUID)
	ret1, _ := ret[1].(map[types0.MirrorPodUID]types0.ResolvedPodUID)
	return ret0, ret1
}

// GetUIDTranslations indicates an expected call of GetUIDTranslations.
func (mr *MockManagerMockRecorder) GetUIDTranslations() *gomock.Call {
	mr.mock.ctrl.T.Helper()
	return mr.mock.ctrl.RecordCallWithMethodType(mr.mock, "GetUIDTranslations", reflect.TypeOf((*MockManager)(nil).GetUIDTranslations))
}

// RemovePod mocks base method.
func (m *MockManager) RemovePod(pod *v1.Pod) {
	m.ctrl.T.Helper()
	m.ctrl.Call(m, "RemovePod", pod)
}

// RemovePod indicates an expected call of RemovePod.
func (mr *MockManagerMockRecorder) RemovePod(pod any) *gomock.Call {
	mr.mock.ctrl.T.Helper()
	return mr.mock.ctrl.RecordCallWithMethodType(mr.mock, "RemovePod", reflect.TypeOf((*MockManager)(nil).RemovePod), pod)
}

// SetPods mocks base method.
func (m *MockManager) SetPods(pods []*v1.Pod) {
	m.ctrl.T.Helper()
	m.ctrl.Call(m, "SetPods", pods)
}

// SetPods indicates an expected call of SetPods.
func (mr *MockManagerMockRecorder) SetPods(pods any) *gomock.Call {
	mr.mock.ctrl.T.Helper()
	return mr.mock.ctrl.RecordCallWithMethodType(mr.mock, "SetPods", reflect.TypeOf((*MockManager)(nil).SetPods), pods)
}

// TranslatePodUID mocks base method.
func (m *MockManager) TranslatePodUID(uid types.UID) types0.ResolvedPodUID {
	m.ctrl.T.Helper()
	ret := m.ctrl.Call(m, "TranslatePodUID", uid)
	ret0, _ := ret[0].(types0.ResolvedPodUID)
	return ret0
}

// TranslatePodUID indicates an expected call of TranslatePodUID.
func (mr *MockManagerMockRecorder) TranslatePodUID(uid any) *gomock.Call {
	mr.mock.ctrl.T.Helper()
	return mr.mock.ctrl.RecordCallWithMethodType(mr.mock, "TranslatePodUID", reflect.TypeOf((*MockManager)(nil).TranslatePodUID), uid)
}

// UpdatePod mocks base method.
func (m *MockManager) UpdatePod(pod *v1.Pod) {
	m.ctrl.T.Helper()
	m.ctrl.Call(m, "UpdatePod", pod)
}

// UpdatePod indicates an expected call of UpdatePod.
func (mr *MockManagerMockRecorder) UpdatePod(pod any) *gomock.Call {
	mr.mock.ctrl.T.Helper()
	return mr.mock.ctrl.RecordCallWithMethodType(mr.mock, "UpdatePod", reflect.TypeOf((*MockManager)(nil).UpdatePod), pod)
}
