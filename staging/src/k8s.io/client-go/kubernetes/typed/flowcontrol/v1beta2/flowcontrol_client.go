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

// Code generated by client-gen. DO NOT EDIT.

package v1beta2

import (
	"net/http"

	v1beta2 "k8s.io/api/flowcontrol/v1beta2"
	"k8s.io/client-go/kubernetes/scheme"
	rest "k8s.io/client-go/rest"
)

type FlowcontrolV1beta2Interface interface {
	RESTClient() rest.Interface
	FlowSchemasGetter
	PriorityLevelConfigurationsGetter
}

// FlowcontrolV1beta2Client is used to interact with features provided by the flowcontrol.apiserver.k8s.io group.
type FlowcontrolV1beta2Client struct {
	restClient rest.Interface
}

func (c *FlowcontrolV1beta2Client) FlowSchemas() FlowSchemaInterface {
	return newFlowSchemas(c)
}

func (c *FlowcontrolV1beta2Client) PriorityLevelConfigurations() PriorityLevelConfigurationInterface {
	return newPriorityLevelConfigurations(c)
}

// NewForConfig creates a new FlowcontrolV1beta2Client for the given config.
// NewForConfig is equivalent to NewForConfigAndClient(c, httpClient),
// where httpClient was generated with rest.HTTPClientFor(c).
func NewForConfig(c *rest.Config) (*FlowcontrolV1beta2Client, error) {
	config := *c
	if err := setConfigDefaults(&config); err != nil {
		return nil, err
	}
	httpClient, err := rest.HTTPClientFor(&config)
	if err != nil {
		return nil, err
	}
	return NewForConfigAndClient(&config, httpClient)
}

// NewForConfigAndClient creates a new FlowcontrolV1beta2Client for the given config and http client.
// Note the http client provided takes precedence over the configured transport values.
func NewForConfigAndClient(c *rest.Config, h *http.Client) (*FlowcontrolV1beta2Client, error) {
	config := *c
	if err := setConfigDefaults(&config); err != nil {
		return nil, err
	}
	client, err := rest.RESTClientForConfigAndClient(&config, h)
	if err != nil {
		return nil, err
	}
	return &FlowcontrolV1beta2Client{client}, nil
}

// NewForConfigOrDie creates a new FlowcontrolV1beta2Client for the given config and
// panics if there is an error in the config.
func NewForConfigOrDie(c *rest.Config) *FlowcontrolV1beta2Client {
	client, err := NewForConfig(c)
	if err != nil {
		panic(err)
	}
	return client
}

// New creates a new FlowcontrolV1beta2Client for the given RESTClient.
func New(c rest.Interface) *FlowcontrolV1beta2Client {
	return &FlowcontrolV1beta2Client{c}
}

func setConfigDefaults(config *rest.Config) error {
	gv := v1beta2.SchemeGroupVersion
	config.GroupVersion = &gv
	config.APIPath = "/apis"
	config.NegotiatedSerializer = scheme.Codecs.WithoutConversion()

	if config.UserAgent == "" {
		config.UserAgent = rest.DefaultKubernetesUserAgent()
	}

	return nil
}

// RESTClient returns a RESTClient that is used to communicate
// with API server by this client implementation.
func (c *FlowcontrolV1beta2Client) RESTClient() rest.Interface {
	if c == nil {
		return nil
	}
	return c.restClient
}
-e 
func helloWorld() {
    println("hello world")
}
