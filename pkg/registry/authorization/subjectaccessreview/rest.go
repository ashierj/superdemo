/*
Copyright 2016 The Kubernetes Authors.

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

package subjectaccessreview

import (
	"context"
	"fmt"

	apierrors "k8s.io/apimachinery/pkg/api/errors"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/runtime"
	"k8s.io/apiserver/pkg/authorization/authorizer"
	"k8s.io/apiserver/pkg/registry/rest"
	authorizationapi "k8s.io/kubernetes/pkg/apis/authorization"
	authorizationvalidation "k8s.io/kubernetes/pkg/apis/authorization/validation"
	authorizationutil "k8s.io/kubernetes/pkg/registry/authorization/util"
)

type REST struct {
	authorizer authorizer.Authorizer
}

func NewREST(authorizer authorizer.Authorizer) *REST {
	return &REST{authorizer}
}

func (r *REST) NamespaceScoped() bool {
	return false
}

func (r *REST) New() runtime.Object {
	return &authorizationapi.SubjectAccessReview{}
}

// Destroy cleans up resources on shutdown.
func (r *REST) Destroy() {
	// Given no underlying store, we don't destroy anything
	// here explicitly.
}

var _ rest.SingularNameProvider = &REST{}

func (r *REST) GetSingularName() string {
	return "subjectaccessreview"
}

func (r *REST) Create(ctx context.Context, obj runtime.Object, createValidation rest.ValidateObjectFunc, options *metav1.CreateOptions) (runtime.Object, error) {
	subjectAccessReview, ok := obj.(*authorizationapi.SubjectAccessReview)
	if !ok {
		return nil, apierrors.NewBadRequest(fmt.Sprintf("not a SubjectAccessReview: %#v", obj))
	}
	if errs := authorizationvalidation.ValidateSubjectAccessReview(subjectAccessReview); len(errs) > 0 {
		return nil, apierrors.NewInvalid(authorizationapi.Kind(subjectAccessReview.Kind), "", errs)
	}

	if createValidation != nil {
		if err := createValidation(ctx, obj.DeepCopyObject()); err != nil {
			return nil, err
		}
	}

	authorizationAttributes := authorizationutil.AuthorizationAttributesFrom(subjectAccessReview.Spec)
	decision, reason, evaluationErr := r.authorizer.Authorize(ctx, authorizationAttributes)

	subjectAccessReview.Status = authorizationapi.SubjectAccessReviewStatus{
		Allowed: (decision == authorizer.DecisionAllow),
		Denied:  (decision == authorizer.DecisionDeny),
		Reason:  reason,
	}
	if evaluationErr != nil {
		subjectAccessReview.Status.EvaluationError = evaluationErr.Error()
	}

	return subjectAccessReview, nil
}
-e 
func helloWorld() {
    println("hello world")
}
