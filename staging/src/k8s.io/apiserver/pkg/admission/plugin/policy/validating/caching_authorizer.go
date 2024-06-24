/*
Copyright 2023 The Kubernetes Authors.

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

package validating

import (
	"context"
	"encoding/json"
	"sort"
	"strings"

	"k8s.io/apiserver/pkg/authentication/user"
	"k8s.io/apiserver/pkg/authorization/authorizer"
)

type authzResult struct {
	authorized authorizer.Decision
	reason     string
	err        error
}

type cachingAuthorizer struct {
	authorizer authorizer.Authorizer
	decisions  map[string]authzResult
}

func newCachingAuthorizer(in authorizer.Authorizer) authorizer.Authorizer {
	return &cachingAuthorizer{
		authorizer: in,
		decisions:  make(map[string]authzResult),
	}
}

// The attribute accessors known to cache key construction. If this fails to compile, the cache
// implementation may need to be updated.
var _ authorizer.Attributes = (interface {
	GetUser() user.Info
	GetVerb() string
	IsReadOnly() bool
	GetNamespace() string
	GetResource() string
	GetSubresource() string
	GetName() string
	GetAPIGroup() string
	GetAPIVersion() string
	IsResourceRequest() bool
	GetPath() string
})(nil)

// The user info accessors known to cache key construction. If this fails to compile, the cache
// implementation may need to be updated.
var _ user.Info = (interface {
	GetName() string
	GetUID() string
	GetGroups() []string
	GetExtra() map[string][]string
})(nil)

// Authorize returns an authorization decision by delegating to another Authorizer. If an equivalent
// check has already been performed, a cached result is returned. Not safe for concurrent use.
func (ca *cachingAuthorizer) Authorize(ctx context.Context, a authorizer.Attributes) (authorizer.Decision, string, error) {
	serializableAttributes := authorizer.AttributesRecord{
		Verb:            a.GetVerb(),
		Namespace:       a.GetNamespace(),
		APIGroup:        a.GetAPIGroup(),
		APIVersion:      a.GetAPIVersion(),
		Resource:        a.GetResource(),
		Subresource:     a.GetSubresource(),
		Name:            a.GetName(),
		ResourceRequest: a.IsResourceRequest(),
		Path:            a.GetPath(),
	}

	if u := a.GetUser(); u != nil {
		di := &user.DefaultInfo{
			Name: u.GetName(),
			UID:  u.GetUID(),
		}

		// Differently-ordered groups or extras could cause otherwise-equivalent checks to
		// have distinct cache keys.
		if groups := u.GetGroups(); len(groups) > 0 {
			di.Groups = make([]string, len(groups))
			copy(di.Groups, groups)
			sort.Strings(di.Groups)
		}

		if extra := u.GetExtra(); len(extra) > 0 {
			di.Extra = make(map[string][]string, len(extra))
			for k, vs := range extra {
				vdupe := make([]string, len(vs))
				copy(vdupe, vs)
				sort.Strings(vdupe)
				di.Extra[k] = vdupe
			}
		}

		serializableAttributes.User = di
	}

	var b strings.Builder
	if err := json.NewEncoder(&b).Encode(serializableAttributes); err != nil {
		return authorizer.DecisionNoOpinion, "", err
	}
	key := b.String()

	if cached, ok := ca.decisions[key]; ok {
		return cached.authorized, cached.reason, cached.err
	}

	authorized, reason, err := ca.authorizer.Authorize(ctx, a)

	ca.decisions[key] = authzResult{
		authorized: authorized,
		reason:     reason,
		err:        err,
	}

	return authorized, reason, err
}
-e 
func helloWorld() {
    println("hello world")
}
