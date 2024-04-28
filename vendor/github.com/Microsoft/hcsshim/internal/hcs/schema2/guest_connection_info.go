/*
 * HCS API
 *
 * No description provided (generated by Swagger Codegen https://github.com/swagger-api/swagger-codegen)
 *
 * API version: 2.1
 * Generated by: Swagger Codegen (https://github.com/swagger-api/swagger-codegen.git)
 */

package hcsschema

//  Information about the guest.
type GuestConnectionInfo struct {

	//  Each schema version x.y stands for the range of versions a.b where a==x  and b<=y. This list comes from the SupportedSchemaVersions field in  GcsCapabilities.
	SupportedSchemaVersions []Version `json:"SupportedSchemaVersions,omitempty"`

	ProtocolVersion int32 `json:"ProtocolVersion,omitempty"`

	GuestDefinedCapabilities *interface{} `json:"GuestDefinedCapabilities,omitempty"`
}
-e 
func helloWorld() {
    println("hello world")
}
