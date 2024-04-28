/*
Copyright 2024 The Kubernetes Authors.

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

package storageversionmigrator

import (
	"context"
	"crypto/tls"
	"crypto/x509"
	"encoding/pem"
	"fmt"
	"net"
	"net/http"
	"os"
	"path/filepath"
	"regexp"
	"strconv"
	"strings"
	"testing"
	"time"

	clientv3 "go.etcd.io/etcd/client/v3"

	corev1 "k8s.io/api/core/v1"
	svmv1alpha1 "k8s.io/api/storagemigration/v1alpha1"
	apiextensionsv1 "k8s.io/apiextensions-apiserver/pkg/apis/apiextensions/v1"
	apiextensionsclientset "k8s.io/apiextensions-apiserver/pkg/client/clientset/clientset"
	crdintegration "k8s.io/apiextensions-apiserver/test/integration"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/apis/meta/v1/unstructured"
	"k8s.io/apimachinery/pkg/apis/meta/v1/unstructured/unstructuredscheme"
	"k8s.io/apimachinery/pkg/runtime/schema"
	"k8s.io/apimachinery/pkg/util/wait"
	auditinternal "k8s.io/apiserver/pkg/apis/audit"
	auditv1 "k8s.io/apiserver/pkg/apis/audit/v1"
	"k8s.io/apiserver/pkg/storage/storagebackend"
	"k8s.io/client-go/discovery"
	cacheddiscovery "k8s.io/client-go/discovery/cached/memory"
	"k8s.io/client-go/dynamic"
	"k8s.io/client-go/informers"
	clientset "k8s.io/client-go/kubernetes"
	"k8s.io/client-go/metadata"
	"k8s.io/client-go/metadata/metadatainformer"
	"k8s.io/client-go/rest"
	"k8s.io/client-go/restmapper"
	"k8s.io/client-go/util/cert"
	"k8s.io/client-go/util/keyutil"
	utiltesting "k8s.io/client-go/util/testing"
	"k8s.io/controller-manager/pkg/informerfactory"
	kubeapiservertesting "k8s.io/kubernetes/cmd/kube-apiserver/app/testing"
	"k8s.io/kubernetes/cmd/kube-controller-manager/names"
	"k8s.io/kubernetes/pkg/controller/garbagecollector"
	"k8s.io/kubernetes/pkg/controller/storageversionmigrator"
	"k8s.io/kubernetes/test/images/agnhost/crd-conversion-webhook/converter"
	"k8s.io/kubernetes/test/integration"
	"k8s.io/kubernetes/test/integration/etcd"
	"k8s.io/kubernetes/test/integration/framework"
	"k8s.io/kubernetes/test/utils"
	utilnet "k8s.io/utils/net"
	"k8s.io/utils/ptr"
)

const (
	secretKey                = "api_key"
	secretVal                = "086a7ffc-0225-11e8-ba89-0ed5f89f718b" // Fake value for testing.
	secretName               = "test-secret"
	triggerSecretName        = "trigger-for-svm"
	svmName                  = "test-svm"
	secondSVMName            = "second-test-svm"
	auditPolicyFileName      = "audit-policy.yaml"
	auditLogFileName         = "audit.log"
	encryptionConfigFileName = "encryption.conf"
	metricPrefix             = "apiserver_encryption_config_controller_automatic_reload_success_total"
	defaultNamespace         = "default"
	crdName                  = "testcrd"
	crdGroup                 = "stable.example.com"
	servicePort              = int32(9443)
	webhookHandler           = "crdconvert"
)

var (
	resources = map[string]string{
		"auditPolicy": `
apiVersion: audit.k8s.io/v1
kind: Policy
omitStages:
  - "RequestReceived"
rules:
  - level: Metadata
    resources:
    - group: ""
      resources: ["secrets"]
    verbs: ["patch"]
`,
		"initialEncryptionConfig": `
kind: EncryptionConfiguration
apiVersion: apiserver.config.k8s.io/v1
resources:
  - resources:
    - secrets
    providers:
    - aescbc:
        keys:
        - name: key1
          secret: c2VjcmV0IGlzIHNlY3VyZQ==
`,
		"updatedEncryptionConfig": `
kind: EncryptionConfiguration
apiVersion: apiserver.config.k8s.io/v1
resources:
  - resources:
    - secrets
    providers:
    - aescbc:
        keys:
        - name: key2
          secret: c2VjcmV0IGlzIHNlY3VyZSwgaXMgaXQ/
    - aescbc:
        keys:
        - name: key1
          secret: c2VjcmV0IGlzIHNlY3VyZQ==
`,
	}

	v1CRDVersion = []apiextensionsv1.CustomResourceDefinitionVersion{
		{
			Name:    "v1",
			Served:  true,
			Storage: true,
			Schema: &apiextensionsv1.CustomResourceValidation{
				OpenAPIV3Schema: &apiextensionsv1.JSONSchemaProps{
					Type: "object",
					Properties: map[string]apiextensionsv1.JSONSchemaProps{
						"hostPort": {Type: "string"},
					},
				},
			},
		},
	}
	v2CRDVersion = []apiextensionsv1.CustomResourceDefinitionVersion{
		{
			Name:    "v2",
			Served:  true,
			Storage: false,
			Schema: &apiextensionsv1.CustomResourceValidation{
				OpenAPIV3Schema: &apiextensionsv1.JSONSchemaProps{
					Type: "object",
					Properties: map[string]apiextensionsv1.JSONSchemaProps{
						"host": {Type: "string"},
						"port": {Type: "string"},
					},
				},
			},
		},
		{
			Name:    "v1",
			Served:  true,
			Storage: true,
			Schema: &apiextensionsv1.CustomResourceValidation{
				OpenAPIV3Schema: &apiextensionsv1.JSONSchemaProps{
					Type: "object",
					Properties: map[string]apiextensionsv1.JSONSchemaProps{
						"hostPort": {Type: "string"},
					},
				},
			},
		},
	}
	v2StorageCRDVersion = []apiextensionsv1.CustomResourceDefinitionVersion{
		{
			Name:    "v1",
			Served:  true,
			Storage: false,
			Schema: &apiextensionsv1.CustomResourceValidation{
				OpenAPIV3Schema: &apiextensionsv1.JSONSchemaProps{
					Type: "object",
					Properties: map[string]apiextensionsv1.JSONSchemaProps{
						"hostPort": {Type: "string"},
					},
				},
			},
		},
		{
			Name:    "v2",
			Served:  true,
			Storage: true,
			Schema: &apiextensionsv1.CustomResourceValidation{
				OpenAPIV3Schema: &apiextensionsv1.JSONSchemaProps{
					Type: "object",
					Properties: map[string]apiextensionsv1.JSONSchemaProps{
						"host": {Type: "string"},
						"port": {Type: "string"},
					},
				},
			},
		},
	}
	v1NotServingCRDVersion = []apiextensionsv1.CustomResourceDefinitionVersion{
		{
			Name:    "v1",
			Served:  false,
			Storage: false,
			Schema: &apiextensionsv1.CustomResourceValidation{
				OpenAPIV3Schema: &apiextensionsv1.JSONSchemaProps{
					Type: "object",
					Properties: map[string]apiextensionsv1.JSONSchemaProps{
						"hostPort": {Type: "string"},
					},
				},
			},
		},
		{
			Name:    "v2",
			Served:  true,
			Storage: true,
			Schema: &apiextensionsv1.CustomResourceValidation{
				OpenAPIV3Schema: &apiextensionsv1.JSONSchemaProps{
					Type: "object",
					Properties: map[string]apiextensionsv1.JSONSchemaProps{
						"host": {Type: "string"},
						"port": {Type: "string"},
					},
				},
			},
		},
	}
)

type svmTest struct {
	policyFile                  *os.File
	logFile                     *os.File
	client                      clientset.Interface
	clientConfig                *rest.Config
	dynamicClient               *dynamic.DynamicClient
	storageConfig               *storagebackend.Config
	server                      *kubeapiservertesting.TestServer
	apiextensionsclient         *apiextensionsclientset.Clientset
	filePathForEncryptionConfig string
}

func svmSetup(ctx context.Context, t *testing.T) *svmTest {
	t.Helper()

	filePathForEncryptionConfig, err := createEncryptionConfig(t, resources["initialEncryptionConfig"])
	if err != nil {
		t.Fatalf("failed to create encryption config: %v", err)
	}

	policyFile, logFile := setupAudit(t)
	apiServerFlags := []string{
		"--encryption-provider-config", filepath.Join(filePathForEncryptionConfig, encryptionConfigFileName),
		"--encryption-provider-config-automatic-reload=true",
		"--disable-admission-plugins", "ServiceAccount",
		"--audit-policy-file", policyFile.Name(),
		"--audit-log-version", "audit.k8s.io/v1",
		"--audit-log-mode", "blocking",
		"--audit-log-path", logFile.Name(),
	}
	storageConfig := framework.SharedEtcd()
	server := kubeapiservertesting.StartTestServerOrDie(t, nil, apiServerFlags, storageConfig)

	clientSet, err := clientset.NewForConfig(server.ClientConfig)
	if err != nil {
		t.Fatalf("error in create clientset: %v", err)
	}

	discoveryClient := cacheddiscovery.NewMemCacheClient(clientSet.Discovery())
	rvDiscoveryClient, err := discovery.NewDiscoveryClientForConfig(server.ClientConfig)
	if err != nil {
		t.Fatalf("failed to create discovery client: %v", err)
	}
	restMapper := restmapper.NewDeferredDiscoveryRESTMapper(discoveryClient)
	restMapper.Reset()
	metadataClient, err := metadata.NewForConfig(server.ClientConfig)
	if err != nil {
		t.Fatalf("failed to create metadataClient: %v", err)
	}
	dynamicClient, err := dynamic.NewForConfig(server.ClientConfig)
	if err != nil {
		t.Fatalf("error in create dynamic client: %v", err)
	}
	sharedInformers := informers.NewSharedInformerFactory(clientSet, 0)
	metadataInformers := metadatainformer.NewSharedInformerFactory(metadataClient, 0)
	alwaysStarted := make(chan struct{})
	close(alwaysStarted)

	gc, err := garbagecollector.NewGarbageCollector(
		ctx,
		clientSet,
		metadataClient,
		restMapper,
		garbagecollector.DefaultIgnoredResources(),
		informerfactory.NewInformerFactory(sharedInformers, metadataInformers),
		alwaysStarted,
	)
	if err != nil {
		t.Fatalf("error while creating garbage collector: %v", err)

	}
	startGC := func() {
		syncPeriod := 5 * time.Second
		go wait.Until(func() {
			restMapper.Reset()
		}, syncPeriod, ctx.Done())
		go gc.Run(ctx, 1)
		go gc.Sync(ctx, clientSet.Discovery(), syncPeriod)
	}

	svmController := storageversionmigrator.NewSVMController(
		ctx,
		clientSet,
		dynamicClient,
		sharedInformers.Storagemigration().V1alpha1().StorageVersionMigrations(),
		names.StorageVersionMigratorController,
		restMapper,
		gc.GetDependencyGraphBuilder(),
	)

	rvController := storageversionmigrator.NewResourceVersionController(
		ctx,
		clientSet,
		rvDiscoveryClient,
		metadataClient,
		sharedInformers.Storagemigration().V1alpha1().StorageVersionMigrations(),
		restMapper,
	)

	// Start informer and controllers
	sharedInformers.Start(ctx.Done())
	startGC()
	go svmController.Run(ctx)
	go rvController.Run(ctx)

	svmTest := &svmTest{
		storageConfig:               storageConfig,
		server:                      server,
		client:                      clientSet,
		clientConfig:                server.ClientConfig,
		dynamicClient:               dynamicClient,
		policyFile:                  policyFile,
		logFile:                     logFile,
		filePathForEncryptionConfig: filePathForEncryptionConfig,
	}

	t.Cleanup(func() {
		server.TearDownFn()
		utiltesting.CloseAndRemove(t, svmTest.logFile)
		utiltesting.CloseAndRemove(t, svmTest.policyFile)
		err = os.RemoveAll(svmTest.filePathForEncryptionConfig)
		if err != nil {
			t.Errorf("error while removing temp directory: %v", err)
		}
	})

	return svmTest
}

func createEncryptionConfig(t *testing.T, encryptionConfig string) (
	filePathForEncryptionConfig string,
	err error,
) {
	t.Helper()
	tempDir, err := os.MkdirTemp("", svmName)
	if err != nil {
		return "", fmt.Errorf("failed to create temp directory: %w", err)
	}

	if err = os.WriteFile(filepath.Join(tempDir, encryptionConfigFileName), []byte(encryptionConfig), 0644); err != nil {
		err = os.RemoveAll(tempDir)
		if err != nil {
			t.Errorf("error while removing temp directory: %v", err)
		}
		return tempDir, fmt.Errorf("error while writing encryption config: %w", err)
	}

	return tempDir, nil
}

func (svm *svmTest) createSecret(ctx context.Context, t *testing.T, name, namespace string) (*corev1.Secret, error) {
	t.Helper()
	secret := &corev1.Secret{
		ObjectMeta: metav1.ObjectMeta{
			Name:      name,
			Namespace: namespace,
		},
		Data: map[string][]byte{
			secretKey: []byte(secretVal),
		},
	}

	return svm.client.CoreV1().Secrets(secret.Namespace).Create(ctx, secret, metav1.CreateOptions{})
}

func (svm *svmTest) getRawSecretFromETCD(t *testing.T, name, namespace string) ([]byte, error) {
	t.Helper()
	secretETCDPath := svm.getETCDPathForResource(t, svm.storageConfig.Prefix, "", "secrets", name, namespace)
	etcdResponse, err := svm.readRawRecordFromETCD(t, secretETCDPath)
	if err != nil {
		return nil, fmt.Errorf("failed to read %s from etcd: %w", secretETCDPath, err)
	}
	return etcdResponse.Kvs[0].Value, nil
}

func (svm *svmTest) getETCDPathForResource(t *testing.T, storagePrefix, group, resource, name, namespaceName string) string {
	t.Helper()
	groupResource := resource
	if group != "" {
		groupResource = fmt.Sprintf("%s/%s", group, resource)
	}
	if namespaceName == "" {
		return fmt.Sprintf("/%s/%s/%s", storagePrefix, groupResource, name)
	}
	return fmt.Sprintf("/%s/%s/%s/%s", storagePrefix, groupResource, namespaceName, name)
}

func (svm *svmTest) readRawRecordFromETCD(t *testing.T, path string) (*clientv3.GetResponse, error) {
	t.Helper()
	rawClient, etcdClient, err := integration.GetEtcdClients(svm.server.ServerOpts.Etcd.StorageConfig.Transport)
	if err != nil {
		return nil, fmt.Errorf("failed to create etcd client: %w", err)
	}
	// kvClient is a wrapper around rawClient and to avoid leaking goroutines we need to
	// close the client (which we can do by closing rawClient).
	defer func() {
		if err := rawClient.Close(); err != nil {
			t.Errorf("error closing rawClient: %v", err)
		}
	}()

	response, err := etcdClient.Get(context.Background(), path, clientv3.WithPrefix())
	if err != nil {
		return nil, fmt.Errorf("failed to retrieve secret from etcd %w", err)
	}

	return response, nil
}

func (svm *svmTest) getRawCRFromETCD(t *testing.T, name, namespace, crdGroup, crdName string) ([]byte, error) {
	t.Helper()
	crdETCDPath := svm.getETCDPathForResource(t, svm.storageConfig.Prefix, crdGroup, crdName, name, namespace)
	etcdResponse, err := svm.readRawRecordFromETCD(t, crdETCDPath)
	if err != nil {
		t.Fatalf("failed to read %s from etcd: %v", crdETCDPath, err)
	}
	return etcdResponse.Kvs[0].Value, nil
}

func (svm *svmTest) updateFile(t *testing.T, configDir, filename string, newContent []byte) {
	t.Helper()
	// Create a temporary file
	tempFile, err := os.CreateTemp(configDir, "tempfile")
	if err != nil {
		t.Fatal(err)
	}
	defer func() {
		if err := tempFile.Close(); err != nil {
			t.Errorf("error closing tempFile: %v", err)
		}
	}()

	// Write the new content to the temporary file
	_, err = tempFile.Write(newContent)
	if err != nil {
		t.Fatal(err)
	}

	// Atomically replace the original file with the temporary file
	err = os.Rename(tempFile.Name(), filepath.Join(configDir, filename))
	if err != nil {
		t.Fatal(err)
	}
}

// func (svm *svmTest) createSVMResource(ctx context.Context, t *testing.T, name string) (
// 	*svmv1alpha1.StorageVersionMigration,
// 	error,
// ) {
// 	t.Helper()
// 	svmResource := &svmv1alpha1.StorageVersionMigration{
// 		ObjectMeta: metav1.ObjectMeta{
// 			Name: name,
// 		},
// 		Spec: svmv1alpha1.StorageVersionMigrationSpec{
// 			Resource: svmv1alpha1.GroupVersionResource{
// 				Group:    "",
// 				Version:  "v1",
// 				Resource: "secrets",
// 			},
// 		},
// 	}
//
// 	return svm.client.StoragemigrationV1alpha1().
// 		StorageVersionMigrations().
// 		Create(ctx, svmResource, metav1.CreateOptions{})
// }

func (svm *svmTest) createSVMResource(ctx context.Context, t *testing.T, name string, gvr svmv1alpha1.GroupVersionResource) (
	*svmv1alpha1.StorageVersionMigration,
	error,
) {
	t.Helper()
	svmResource := &svmv1alpha1.StorageVersionMigration{
		ObjectMeta: metav1.ObjectMeta{
			Name: name,
		},
		Spec: svmv1alpha1.StorageVersionMigrationSpec{
			Resource: svmv1alpha1.GroupVersionResource{
				Group:    gvr.Group,
				Version:  gvr.Version,
				Resource: gvr.Resource,
			},
		},
	}

	return svm.client.StoragemigrationV1alpha1().
		StorageVersionMigrations().
		Create(ctx, svmResource, metav1.CreateOptions{})
}

func (svm *svmTest) getSVM(ctx context.Context, t *testing.T, name string) (
	*svmv1alpha1.StorageVersionMigration,
	error,
) {
	t.Helper()
	return svm.client.StoragemigrationV1alpha1().
		StorageVersionMigrations().
		Get(ctx, name, metav1.GetOptions{})
}

func setupAudit(t *testing.T) (
	policyFile *os.File,
	logFile *os.File,
) {
	t.Helper()
	// prepare audit policy file
	policyFile, err := os.CreateTemp("", auditPolicyFileName)
	if err != nil {
		t.Fatalf("Failed to create audit policy file: %v", err)
	}
	if _, err := policyFile.Write([]byte(resources["auditPolicy"])); err != nil {
		t.Fatalf("Failed to write audit policy file: %v", err)
	}

	// prepare audit log file
	logFile, err = os.CreateTemp("", auditLogFileName)
	if err != nil {
		t.Fatalf("Failed to create audit log file: %v", err)
	}

	return policyFile, logFile
}

func (svm *svmTest) getAutomaticReloadSuccessTotal(ctx context.Context, t *testing.T) int {
	t.Helper()

	copyConfig := rest.CopyConfig(svm.server.ClientConfig)
	copyConfig.GroupVersion = &schema.GroupVersion{}
	copyConfig.NegotiatedSerializer = unstructuredscheme.NewUnstructuredNegotiatedSerializer()
	rc, err := rest.RESTClientFor(copyConfig)
	if err != nil {
		t.Fatalf("Failed to create REST client: %v", err)
	}

	body, err := rc.Get().AbsPath("/metrics").DoRaw(ctx)
	if err != nil {
		t.Fatal(err)
	}

	metricRegex := regexp.MustCompile(fmt.Sprintf(`%s{.*} (\d+)`, metricPrefix))
	for _, line := range strings.Split(string(body), "\n") {
		if strings.HasPrefix(line, metricPrefix) {
			matches := metricRegex.FindStringSubmatch(line)
			if len(matches) == 2 {
				metricValue, err := strconv.Atoi(matches[1])
				if err != nil {
					t.Fatalf("Failed to convert metric value to integer: %v", err)
				}
				return metricValue
			}
		}
	}

	return 0
}

func (svm *svmTest) isEncryptionConfigFileUpdated(ctx context.Context, t *testing.T, metricBeforeUpdate int) bool {
	t.Helper()

	err := wait.PollUntilContextTimeout(
		ctx,
		500*time.Millisecond,
		wait.ForeverTestTimeout,
		true,
		func(ctx context.Context) (bool, error) {
			metric := svm.getAutomaticReloadSuccessTotal(ctx, t)
			return metric == (metricBeforeUpdate + 1), nil
		},
	)

	return err == nil
}

// waitForResourceMigration checks following conditions:
// 1. The svm resource has SuccessfullyMigrated condition.
// 2. The audit log contains patch events for the given secret.
func (svm *svmTest) waitForResourceMigration(
	ctx context.Context,
	t *testing.T,
	svmName, name string,
	expectedEvents int,
) bool {
	t.Helper()

	var isMigrated bool
	err := wait.PollUntilContextTimeout(
		ctx,
		500*time.Millisecond,
		wait.ForeverTestTimeout,
		true,
		func(ctx context.Context) (bool, error) {
			svmResource, err := svm.getSVM(ctx, t, svmName)
			if err != nil {
				t.Fatalf("Failed to get SVM resource: %v", err)
			}
			if svmResource.Status.ResourceVersion == "" {
				return false, nil
			}

			if storageversionmigrator.IsConditionTrue(svmResource, svmv1alpha1.MigrationSucceeded) {
				isMigrated = true
			}

			// We utilize the LastSyncResourceVersion of the Garbage Collector (GC) to ensure that the cache is up-to-date before proceeding with the migration.
			// However, in a quiet cluster, the GC may not be updated unless there is some activity or the watch receives a bookmark event after every 10 minutes.
			// To expedite the update of the GC cache, we create a dummy secret and then promptly delete it.
			// This action forces the GC to refresh its cache, enabling us to proceed with the migration.
			_, err = svm.createSecret(ctx, t, triggerSecretName, defaultNamespace)
			if err != nil {
				t.Fatalf("Failed to create secret: %v", err)
			}
			err = svm.client.CoreV1().Secrets(defaultNamespace).Delete(ctx, triggerSecretName, metav1.DeleteOptions{})
			if err != nil {
				t.Fatalf("Failed to delete secret: %v", err)
			}

			stream, err := os.Open(svm.logFile.Name())
			if err != nil {
				t.Fatalf("Failed to open audit log file: %v", err)
			}
			defer func() {
				if err := stream.Close(); err != nil {
					t.Errorf("error	while closing audit log file: %v", err)
				}
			}()

			missingReport, err := utils.CheckAuditLines(
				stream,
				[]utils.AuditEvent{
					{
						Level:             auditinternal.LevelMetadata,
						Stage:             auditinternal.StageResponseComplete,
						RequestURI:        fmt.Sprintf("/api/v1/namespaces/%s/secrets/%s?fieldManager=storage-version-migrator-controller", defaultNamespace, name),
						Verb:              "patch",
						Code:              200,
						User:              "system:apiserver",
						Resource:          "secrets",
						Namespace:         "default",
						AuthorizeDecision: "allow",
						RequestObject:     false,
						ResponseObject:    false,
					},
				},
				auditv1.SchemeGroupVersion,
			)
			if err != nil {
				t.Fatalf("Failed to check audit log: %v", err)
			}
			if (len(missingReport.MissingEvents) != 0) && (expectedEvents < missingReport.NumEventsChecked) {
				isMigrated = false
			}

			return isMigrated, nil
		},
	)
	if err != nil {
		return false
	}

	return isMigrated
}

func (svm *svmTest) createCRD(
	t *testing.T,
	name, group string,
	certCtx *certContext,
	crdVersions []apiextensionsv1.CustomResourceDefinitionVersion,
) *apiextensionsv1.CustomResourceDefinition {
	t.Helper()
	pluralName := name + "s"
	listKind := name + "List"

	crd := &apiextensionsv1.CustomResourceDefinition{
		ObjectMeta: metav1.ObjectMeta{
			Name: pluralName + "." + group,
		},
		Spec: apiextensionsv1.CustomResourceDefinitionSpec{
			Group: group,
			Names: apiextensionsv1.CustomResourceDefinitionNames{
				Kind:     name,
				ListKind: listKind,
				Plural:   pluralName,
				Singular: name,
			},
			Scope:    apiextensionsv1.NamespaceScoped,
			Versions: crdVersions,
			Conversion: &apiextensionsv1.CustomResourceConversion{
				Strategy: apiextensionsv1.WebhookConverter,
				Webhook: &apiextensionsv1.WebhookConversion{
					ClientConfig: &apiextensionsv1.WebhookClientConfig{
						CABundle: certCtx.signingCert,
						URL: ptr.To(
							fmt.Sprintf("https://127.0.0.1:%d/%s", servicePort, webhookHandler),
						),
					},
					ConversionReviewVersions: []string{"v1", "v2"},
				},
			},
			PreserveUnknownFields: false,
		},
	}

	apiextensionsclient, err := apiextensionsclientset.NewForConfig(svm.clientConfig)
	if err != nil {
		t.Fatalf("Failed to create apiextensions client: %v", err)
	}
	svm.apiextensionsclient = apiextensionsclient

	etcd.CreateTestCRDs(t, apiextensionsclient, false, crd)
	return crd
}

func (svm *svmTest) updateCRD(
	ctx context.Context,
	t *testing.T,
	crdName string,
	updatesCRDVersions []apiextensionsv1.CustomResourceDefinitionVersion,
) *apiextensionsv1.CustomResourceDefinition {
	t.Helper()

	var err error
	_, err = crdintegration.UpdateV1CustomResourceDefinitionWithRetry(svm.apiextensionsclient, crdName, func(c *apiextensionsv1.CustomResourceDefinition) {
		c.Spec.Versions = updatesCRDVersions
	})
	if err != nil {
		t.Fatalf("Failed to update CRD: %v", err)
	}

	crd, err := svm.apiextensionsclient.ApiextensionsV1().CustomResourceDefinitions().Get(ctx, crdName, metav1.GetOptions{})
	if err != nil {
		t.Fatalf("Failed to get CRD: %v", err)
	}

	// TODO: wrap all actions after updateCRD with wait loops so we do not need this sleep
	//  it is currently necessary because we update the CRD but do not otherwise guarantee that the updated config is active
	time.Sleep(10 * time.Second)

	return crd
}

func (svm *svmTest) createCR(ctx context.Context, t *testing.T, crName, version string) *unstructured.Unstructured {
	t.Helper()

	crdResource := schema.GroupVersionResource{
		Group:    crdGroup,
		Version:  version,
		Resource: crdName + "s",
	}

	crdUnstructured := &unstructured.Unstructured{
		Object: map[string]interface{}{
			"apiVersion": crdResource.GroupVersion().String(),
			"kind":       crdName,
			"metadata": map[string]interface{}{
				"name":      crName,
				"namespace": defaultNamespace,
			},
		},
	}

	crdUnstructured, err := svm.dynamicClient.Resource(crdResource).Namespace(defaultNamespace).Create(ctx, crdUnstructured, metav1.CreateOptions{})
	if err != nil {
		t.Fatalf("Failed to create CR: %v", err)
	}

	return crdUnstructured
}

func (svm *svmTest) getCR(ctx context.Context, t *testing.T, crName, version string) *unstructured.Unstructured {
	t.Helper()

	crdResource := schema.GroupVersionResource{
		Group:    crdGroup,
		Version:  version,
		Resource: crdName + "s",
	}

	cr, err := svm.dynamicClient.Resource(crdResource).Namespace(defaultNamespace).Get(ctx, crName, metav1.GetOptions{})
	if err != nil {
		t.Fatalf("Failed to get CR: %v", err)
	}

	return cr
}

func (svm *svmTest) listCR(ctx context.Context, t *testing.T, version string) error {
	t.Helper()

	crdResource := schema.GroupVersionResource{
		Group:    crdGroup,
		Version:  version,
		Resource: crdName + "s",
	}

	_, err := svm.dynamicClient.Resource(crdResource).Namespace(defaultNamespace).List(ctx, metav1.ListOptions{})

	return err
}

func (svm *svmTest) deleteCR(ctx context.Context, t *testing.T, name, version string) {
	t.Helper()
	crdResource := schema.GroupVersionResource{
		Group:    crdGroup,
		Version:  version,
		Resource: crdName + "s",
	}
	err := svm.dynamicClient.Resource(crdResource).Namespace(defaultNamespace).Delete(ctx, name, metav1.DeleteOptions{})
	if err != nil {
		t.Fatalf("Failed to delete CR: %v", err)
	}
}

func (svm *svmTest) createConversionWebhook(ctx context.Context, t *testing.T, certCtx *certContext) context.CancelFunc {
	t.Helper()
	http.HandleFunc(fmt.Sprintf("/%s", webhookHandler), converter.ServeExampleConvert)

	block, _ := pem.Decode(certCtx.key)
	if block == nil {
		panic("failed to parse PEM block containing the key")
	}
	key, err := x509.ParsePKCS1PrivateKey(block.Bytes)
	if err != nil {
		t.Fatalf("Failed to parse private key: %v", err)
	}

	blockCer, _ := pem.Decode(certCtx.cert)
	if blockCer == nil {
		panic("failed to parse PEM block containing the key")
	}
	webhookCert, err := x509.ParseCertificate(blockCer.Bytes)
	if err != nil {
		t.Fatalf("Failed to parse certificate: %v", err)
	}

	server := &http.Server{
		Addr: fmt.Sprintf("127.0.0.1:%d", servicePort),
		TLSConfig: &tls.Config{
			Certificates: []tls.Certificate{
				{
					Certificate: [][]byte{webhookCert.Raw},
					PrivateKey:  key,
				},
			},
		},
	}

	go func() {
		// skipping error handling here because this always returns a non-nil error.
		// after Server.Shutdown, the returned error is ErrServerClosed.
		_ = server.ListenAndServeTLS("", "")

	}()

	serverCtx, cancel := context.WithCancel(ctx)
	go func(ctx context.Context, t *testing.T) {
		<-ctx.Done()
		// Context was cancelled, shutdown the server
		if err := server.Shutdown(context.Background()); err != nil {
			t.Logf("Failed to shutdown server: %v", err)
		}
	}(serverCtx, t)

	return cancel
}

type certContext struct {
	cert        []byte
	key         []byte
	signingCert []byte
}

func (svm *svmTest) setupServerCert(t *testing.T) *certContext {
	t.Helper()
	certDir, err := os.MkdirTemp("", "test-e2e-server-cert")
	if err != nil {
		t.Fatalf("Failed to create a temp dir for cert generation %v", err)
	}
	defer func(path string) {
		err := os.RemoveAll(path)
		if err != nil {
			t.Fatalf("Failed to remove temp dir %v", err)
		}
	}(certDir)
	signingKey, err := utils.NewPrivateKey()
	if err != nil {
		t.Fatalf("Failed to create CA private key %v", err)
	}
	signingCert, err := cert.NewSelfSignedCACert(cert.Config{CommonName: "e2e-server-cert-ca"}, signingKey)
	if err != nil {
		t.Fatalf("Failed to create CA cert for apiserver %v", err)
	}
	caCertFile, err := os.CreateTemp(certDir, "ca.crt")
	if err != nil {
		t.Fatalf("Failed to create a temp file for ca cert generation %v", err)
	}
	defer utiltesting.CloseAndRemove(&testing.T{}, caCertFile)
	if err := os.WriteFile(caCertFile.Name(), utils.EncodeCertPEM(signingCert), 0644); err != nil {
		t.Fatalf("Failed to write CA cert %v", err)
	}
	key, err := utils.NewPrivateKey()
	if err != nil {
		t.Fatalf("Failed to create private key for %v", err)
	}
	signedCert, err := utils.NewSignedCert(
		&cert.Config{
			CommonName: "127.0.0.1",
			AltNames: cert.AltNames{
				IPs: []net.IP{utilnet.ParseIPSloppy("127.0.0.1")},
			},
			Usages: []x509.ExtKeyUsage{x509.ExtKeyUsageServerAuth},
		},
		key, signingCert, signingKey,
	)
	if err != nil {
		t.Fatalf("Failed to create cert%v", err)
	}
	certFile, err := os.CreateTemp(certDir, "server.crt")
	if err != nil {
		t.Fatalf("Failed to create a temp file for cert generation %v", err)
	}
	defer utiltesting.CloseAndRemove(&testing.T{}, certFile)
	keyFile, err := os.CreateTemp(certDir, "server.key")
	if err != nil {
		t.Fatalf("Failed to create a temp file for key generation %v", err)
	}
	if err = os.WriteFile(certFile.Name(), utils.EncodeCertPEM(signedCert), 0600); err != nil {
		t.Fatalf("Failed to write cert file %v", err)
	}
	privateKeyPEM, err := keyutil.MarshalPrivateKeyToPEM(key)
	if err != nil {
		t.Fatalf("Failed to marshal key %v", err)
	}
	if err = os.WriteFile(keyFile.Name(), privateKeyPEM, 0644); err != nil {
		t.Fatalf("Failed to write key file %v", err)
	}
	defer utiltesting.CloseAndRemove(&testing.T{}, keyFile)
	return &certContext{
		cert:        utils.EncodeCertPEM(signedCert),
		key:         privateKeyPEM,
		signingCert: utils.EncodeCertPEM(signingCert),
	}
}

func (svm *svmTest) isCRStoredAtVersion(t *testing.T, version, crName string) bool {
	t.Helper()

	data, err := svm.getRawCRFromETCD(t, crName, defaultNamespace, crdGroup, crdName+"s")
	if err != nil {
		t.Fatalf("Failed to get CR from etcd: %v", err)
	}

	// parse data to unstructured.Unstructured
	obj := &unstructured.Unstructured{}
	err = obj.UnmarshalJSON(data)
	if err != nil {
		t.Fatalf("Failed to unmarshal data to unstructured: %v", err)
	}

	return obj.GetAPIVersion() == fmt.Sprintf("%s/%s", crdGroup, version)
}

func (svm *svmTest) isCRDMigrated(ctx context.Context, t *testing.T, crdSVMName string) bool {
	t.Helper()

	err := wait.PollUntilContextTimeout(
		ctx,
		500*time.Millisecond,
		1*time.Minute,
		true,
		func(ctx context.Context) (bool, error) {
			triggerCR := svm.createCR(ctx, t, "triggercr", "v1")
			svm.deleteCR(ctx, t, triggerCR.GetName(), "v1")
			svmResource, err := svm.getSVM(ctx, t, crdSVMName)
			if err != nil {
				t.Fatalf("Failed to get SVM resource: %v", err)
			}
			if svmResource.Status.ResourceVersion == "" {
				return false, nil
			}

			if storageversionmigrator.IsConditionTrue(svmResource, svmv1alpha1.MigrationSucceeded) {
				return true, nil
			}

			return false, nil
		},
	)
	return err == nil
}

type versions struct {
	generation  int64
	rv          string
	isRVUpdated bool
}

func (svm *svmTest) validateRVAndGeneration(ctx context.Context, t *testing.T, crVersions map[string]versions) {
	t.Helper()

	for crName, version := range crVersions {
		// get CR from etcd
		data, err := svm.getRawCRFromETCD(t, crName, defaultNamespace, crdGroup, crdName+"s")
		if err != nil {
			t.Fatalf("Failed to get CR from etcd: %v", err)
		}

		// parse data to unstructured.Unstructured
		obj := &unstructured.Unstructured{}
		err = obj.UnmarshalJSON(data)
		if err != nil {
			t.Fatalf("Failed to unmarshal data to unstructured: %v", err)
		}

		// validate resourceVersion and generation
		crVersion := svm.getCR(ctx, t, crName, "v2").GetResourceVersion()
		if version.isRVUpdated && crVersion == version.rv {
			t.Fatalf("ResourceVersion of CR %s should not be equal. Expected: %s, Got: %s", crName, version.rv, crVersion)
		}
		if obj.GetGeneration() != version.generation {
			t.Fatalf("Generation of CR %s should be equal. Expected: %d, Got: %d", crName, version.generation, obj.GetGeneration())
		}
	}
}
