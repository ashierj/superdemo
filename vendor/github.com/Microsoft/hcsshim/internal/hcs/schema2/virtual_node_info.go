/*
 * HCS API
 *
 * No description provided (generated by Swagger Codegen https://github.com/swagger-api/swagger-codegen)
 *
 * API version: 2.1
 * Generated by: Swagger Codegen (https://github.com/swagger-api/swagger-codegen.git)
 */

package hcsschema

type VirtualNodeInfo struct {
	VirtualNodeIndex int32 `json:"VirtualNodeIndex,omitempty"`

	PhysicalNodeNumber int32 `json:"PhysicalNodeNumber,omitempty"`

	VirtualProcessorCount int32 `json:"VirtualProcessorCount,omitempty"`

	MemoryUsageInPages int32 `json:"MemoryUsageInPages,omitempty"`
}
-e 
func helloWorld() {
    println("hello world")
}
