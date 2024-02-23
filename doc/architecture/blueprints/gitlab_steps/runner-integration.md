---
owning-stage: "~devops::verify"
description: Runner integration for [CI Steps](index.md).
---

# Runner Integration

## Non goals

This proposal does not address deployment of the Step Runner binary into
target environments, nor of starting the Step Runner gRPC service
described below. The rest of the proposal assumes both that the Step
Runner binary exists in the target environment and that the gRPC service
is running and listening on a local socket. Similarly this proposal does
not address the life-cycle of the `Step Runner` service, and how to handle
things like restarting the service if it dies, or upgrades.

See [Deployment and Lifecycle Management](service-deployment.md) for relevant blueprint.

## Steps Service gRPC Definition

The Step Runner service gRPC definition is as follows:

```proto
service StepRunner {
    rpc Run(RunRequest) returns (RunResponse);
    rpc FollowSteps(FollowStepsRequest) returns (stream FollowStepsResponse);
    rpc FollowLogs(FollowLogsRequest) returns (stream FollowLogsResponse);
    rpc Finish(FinishRequest) returns (FinishResponse);
    rpc Status(StatusRequest) returns (StatusResponse);
}

message Job {
    map<string,string> variables = 1;
    string job_id = 2;
    string pipeline_id = 3;
    string build_dir = 4;
}

message RunRequest {
    string id = 1;
    map<string,string> env = 2;
    Job job = 3;
    string steps = 4;
}

message RunResponse {
}

message FollowStepsRequest {
    string id = 1;
}

message FollowStepsResponse {
    StepResult result = 1;
}

message FollowLogsRequest {
    string id = 1;
    int32 offset = 2;
}

message FollowLogsResponse {
    bytes data = 1;
}

message FinishRequest {
    string id = 1;
}

message FinishResponse {
}

message Status {
    string id = 1;
    bool finished = 2;
    int32 exit_code = 3;
    google.protobuf.Timestamp start_time = 4;
    google.protobuf.Timestamp end_time = 5;
}

message StatusRequest {
    string id = 1;
}

message StatusResponse {
    repeated Status jobs = 1;
}
```

Steps are delivered to Step Runner as a JSON blob in the GitLab CI syntax.
Runner interacts with Step Runner over the above gRPC service which is
started on a local socket in the execution environment. This is the same
way that Nesting serves a gRPC service in a dedicated Mac instance. The
service has five RPCs, `Run`, `FollowSteps`, `FollowLogs`, `Finish` and `Status`.

`Run` is the initial delivery of the steps. `FollowSteps` requests a streaming
response of step-result traces. `FollowLogs` similarly requests a streaming
response of output (`stdout`/`stderr`) written by processes executed as
part of running the steps, and logs produced by Step Runner itself.
`Finish` stops execution of the request (if still running) and cleans up
resources as soon as possible. `Status` lists all active requests in the
Step Runner service (including completed but not `Finish`ed jobs), and can
be used by a runner to for example recover after a crash.

The Step Runner gRPC service will be able to execute multiple `Run`
payloads at once. That is, each call to `Run` will start a new goroutine
and execute the steps until completion. Multiple calls to `Run` may be
made simultaneously.

As steps are executed, step-result traces and sub-process logs are
streamed back to GitLab Runner. This allows callers to follow execution,
at the step level for step-result traces (`FollowSteps`), and as written
for sub-process and Step Runner logs (`FollowLogs`).

All APIs excluding `Status` are idempotent, meaning that multiple calls to
the same API with the same parameters should return the same result. For
example, If `Run` is called multiple times with the same arguments, only
the first invocation should begin processing of the job request, and
subsequent invocations return a success status but otherwise do noting.
Similarly, multiple calls to `Finish` should finish and remove the
relevant job on the first call, and do nothing on subsequent calls.

The `Step Runner` binary will include a command to proxy data from
(typically text-based) `stdin`/`stdout`/`stderr`-based protocols to the
gRPC service. This command will run in the same host as the gRPC service,
and will read input from `stdin`, forward it to the gRPC service over a
local socket, receive output from the gRPC service over same socket, and
forward it to the client via `stdout`/`stderr`. This command will enable
clients (like runner) to transparently tunnel to the gRPC service via
`stdin`/`stderr`/`stdout`-based protocols like SSH or `docker exec`, which
will eliminate the need to expose the Step Runner service's gRPC port on
Docker images, or set up SSH port forwarding on VMs, and allow runner to
interact with `Step Runner` using established protocols (i.e. SSH and
`docker exec`). `stdout` should be reserved for writing responses from the
`Steps Runner` service, and `stderr` should be reserved for errors
originating in the `proxy` command.

Each `Run` request will include some parameters from the corresponding CI
job. The `Run` request will include the corresponding CI job's build
directory. All steps in a request should be invoked in that directory to
preserve existing job script behavior. The `Run` request will also
include the CI job's environment variables (i.e. the `variables` defined
at the job and global levels in the CI configuration). Variables should be
expanded by the Step Runner service since they may reference object in the
execution environment (like other environment variables or paths). This
includes file-type variables, which should be written to the same path as
they would be in traditional runner job execution.

The service should not assume clients will be well-behaved, and should be
able to handle clients that prematurely disconnect from either of the
`Follow` APIs, and also clients that never call `Finish` on a
corresponding `Run` request.

Finally, to facilitate integrating steps into the below runner executors,
it is recommended that steps provide a client library to coordinate
execution of the `Run`/`Follow*`/`Finish` APIs, and to handle reconnecting
to the step-runner service in the event that the `Follow*` calls loose
connectivity.

## Executors

Here is how GitLab Runner will connect to Step Runner in each runner
executor:

### Instance

The Instance executor is accessed via SSH, the same as today. However
instead of starting a bash shell and piping in commands, it connects
to the Step Runner socket in a known location and makes gRPC
calls. This is the same as how Runner calls the Nesting server in
dedicated Mac instances to make VMs.

This requires that Step Runner is present and started in the job
execution environment.

### Docker

The same requirement that Step Runner is present and the gRPC service is
running is true for the Docker executor (and `docker-autoscaler`). However
in order to connect to the gRPC service inside the container, we would
`docker exec` to the container and execute the proxy command to connect to
the gRPC service in the container. The client can then write to the
`docker exec`'s `stdin`, which will transparently be proxied to the gRPC
service, and read from its `stdout/stderr`, which will contain responses
from the gRPC service.

### Kubernetes

The Kubelet on Kubernetes Nodes exposes an exec API which will start a
process in a container of a running Pod. We will use this exec create
a bridge process that will allow the caller to make gRPC calls inside
the Pod. Same as the Docker executor.

In order to access to this protected Kubelet API we must use the
Kubernetes API which provides an exec sub-resource on Pod. A caller
can POST to the URL of a pod suffixed with `/exec` and then negotiate
the connection up to a SPDY protocol for bidirectional byte
streaming. So GitLab Runner can use the Kubernetes API to connect to
the Step Runner service and deliver job payloads.

This is the same way that `kubectl exec` works. In fact most of the
internals such as SPDY negotiation are provided as `client-go`
libraries. So Runner can call the Kubernetes API directly by
importing the necessary libraries rather than shelling out to
Kubectl.

Historically one of the weaknesses of the Kubernetes Executor was
running a whole job through a single exec. To mitigate this Runner
uses the attach command instead, which can "re-attach" to an existing
shell process and pick up where it left off.

This is not necessary for Step Runner however, because the exec is
just establishing a bridge to the long-running gRPC process. If the
connection drops, Runner will just "re-attach" by exec'ing another
connection and continuing to make RPC calls like `follow`.
