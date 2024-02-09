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
things like restarting the service if it dies.

## Steps Service gRPC Definition

The Step Runner service gRPC definition is as follows:

```proto
service StepRunner {
    rpc Run(RunRequest) returns (RunResponse);
    rpc Follow(FollowRequest) returns (stream FollowResponse);
    rpc FollowIO(FollowIORequest) returns (stream FollowIOResponse);
    rpc Cancel(CancelRequest) returns (CancelResponse);
    rpc List(ListRequest) returns (ListResponse);
}

message RunRequest {
    string id = 1;
    string work_dir = 2;
    map<string,string> env = 3;
    option (buf.validate.message).cel = {
        id: "env",
        message: "env must be alphanumeric with underscores",
        expression: "this.env.all(key, key.matches('^[a-zA-Z_][a-zA-Z0-9_]*$'))",
    };

    enum StepType {
        unknown = 0;
        step = 1;
        script = 2;
    }
    StepType type = 4;
    repeated Step steps = 5;
    string ci_script = 6;
}

message RunResponse {
}

message FollowRequest {
    string id = 1;
}

message FollowResponse {
    StepResult result = 1;
}

message FollowIORequest {
    string id = 1;
    int32 read_stdout = 2; // number of bytes previously read from stdout. i.e. offset into buffered stdout.
    int32 read_stderr = 3; // number of bytes previously read from stderr. i.e. offset into buffered stderr.
}

message FollowIOResponse {
    enum StreamType {
            stdout = 0;
            stderr = 1;
        }
    bytes stream = 1;
    StreamType stream_type = 2;
}

message CancelRequest {
    string id = 1;
}

message CancelResponse {
}

message ListRequest {
    // nothing for now, but we could add filters here
}

message Job {
    string id = 1;
    // are these sufficient statuses?
    enum JobStatus {
        running = 0;
        suceeded = 1;
        failed = 2;
    }
    JobStatus status = 2;
    google.protobuf.Timestamp finished_time = 3;
    // maybe we can add runtime here?
}

message ListResponse {
    repeated Job jobs = 1;
}
```

Steps are delivered to Step Runner as a YAML blob in the GitLab CI syntax.
Runner interacts with Step Runner over the above gRPC service which is
started on a local socket in the execution environment. This is the same
way that Nesting serves a gRPC service in a dedicated Mac instance. The
service has five RPCs, `Run`, `Follow`, `FollowIO`, `Cancel` and `List`.

`Run` is the initial delivery of the steps. `Follow` requests a streaming
response of step-result traces. `FollowIO` similarly requests a streaming
response of output (`stdout`/`stderr`) written by processes executed as
part of running the steps. `Cancel` stops execution of the request (if
still running) and cleans up resources as soon as possible. `List` lists
all active requests in the Step Runner service (including completed but
not `Cancel`ed jobs), and can be used by a runner to for example recover
after a crash.

The Step Runner gRPC service will be able to execute multiple `Run`
payloads at once. That is, each call to `Run` will start a new goroutine
and execute the steps until completion. Multiple calls to `Run` may be
made simultaneously. This is also why components are cached by `location`,
`version` and `hash`. Because we cannot be changing which ref we are on
while multiple, concurrent executions are using the underlying files.

As steps are executed, step-result traces and sub-process IO are streamed
back to GitLab Runner. This allows callers to follow execution, at the
step level for step-result traces (`Follow`), and as written for
sub-process IO (`FollowIO`).

All APIs excluding `List` are idempotent, meaning that multiple calls to
the same API with the same parameters should return the same result. For
example, If `Run` is called multiple times with the same arguments, only
the first invocation should begin processing of the job request, and
subsequent invocations return a success status but otherwise do noting.
Similarly, multiple calls to `Cancel` should finish and remove the
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

Here is how GitLab Runner will connect to Step Runner in each runner
executor:

## Instance

The Instance executor is accessed via SSH, the same as today. However
instead of starting a bash shell and piping in commands, it connects
to the Step Runner socket in a known location and makes gRPC
calls. This is the same as how Runner calls the Nesting server in
dedicated Mac instances to make VMs.

This requires that Step Runner is present and started in the job
execution environment.

## Docker

The same requirement that Step Runner is present and started is true
for the Docker executor (and `docker-autoscaler`). However in order to
connect to the socket inside the container, we must `exec` a bridge
process in the container. This will be another command on the Step
Runner binary which proxies STDIN and STDOUT to the local socket in a
known location, allowing the caller of exec to make gRPC calls inside
the container.

## Kubernetes

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
