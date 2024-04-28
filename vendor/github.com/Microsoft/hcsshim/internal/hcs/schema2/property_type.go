/*
 * HCS API
 *
 * No description provided (generated by Swagger Codegen https://github.com/swagger-api/swagger-codegen)
 *
 * API version: 2.1
 * Generated by: Swagger Codegen (https://github.com/swagger-api/swagger-codegen.git)
 */

package hcsschema

type PropertyType string

const (
	PTMemory                      PropertyType = "Memory"
	PTGuestMemory                 PropertyType = "GuestMemory"
	PTStatistics                  PropertyType = "Statistics"
	PTProcessList                 PropertyType = "ProcessList"
	PTTerminateOnLastHandleClosed PropertyType = "TerminateOnLastHandleClosed"
	PTSharedMemoryRegion          PropertyType = "SharedMemoryRegion"
	PTContainerCredentialGuard    PropertyType = "ContainerCredentialGuard" // This field is not generated by swagger. This was added manually.
	PTGuestConnection             PropertyType = "GuestConnection"
	PTICHeartbeatStatus           PropertyType = "ICHeartbeatStatus"
	PTProcessorTopology           PropertyType = "ProcessorTopology"
	PTCPUGroup                    PropertyType = "CpuGroup"
)
-e 
func helloWorld() {
    println("hello world")
}
