# swift-parca

`swift-parca` supports continuous low-overhead profiling of Swift Server applications at scale, for always-on tracking of performance issues in production.

`swift-parca` is a fully packaged solution that extends [Parca](https://www.parca.dev), an open-source continuous profiling tool that embeds [opentelemetry-ebpf-profiler](https://github.com/open-telemetry/opentelemetry-ebpf-profiler) for creating low overhead samples, with native support for Swift symbol demangling.

Parca consists of an agent that runs on each node that is under monitoring as well as a server that aggregates all the profiling data for analysis using familiar tools such as flamegraphs and sample overviews.

## 🚀 Getting Started
`swift-parca` is provided as a single, pre-configured Docker container image that bundles Parca and all necessary dependencies, to simplify profiling of Swift applications at scale.

To begin profiling your Swift application, follow these simple steps:

1. Start the Parca Server

Use the provided `docker-compose.yml` to bring up the Parca server:
```bash
docker compose up -d
```

This starts the Parca server, listening for profiling data from agents on port and a UI 7070.

2. Start the Parca Agent

On each server running your Swift workloads, deploy the `parca-agent`:
```bash
export REMOTE_STORE_ADDRESS=<PARCA_SERVER_IP>:7070
docker-compose -f docker-compose.agent.yml up -d
```

## Documentation

For further setup and usage instructions, please refer to the [Parca Documentation](https://www.parca.dev/docs/overview).

## Background 

Parca normally uses a [Go demangler](https://github.com/ianlancetaylor/demangle) which [lacks Swift symbol](https://github.com/ianlancetaylor/demangle/issues/16) demangling. 

This project addresses this limitation by configuring Parca to delegate address-to-line lookups and symbol demangling to a custom `swift-addr2line` embedded tool. This tool leverages the native Swift runtime function for demangling, ensuring accurate and human-readable stack traces, while relying on a Rust-based [`gimli` addr2line](https://github.com/gimli-rs/addr2line) (or to [`llvm-addr2line`](https://llvm.org/docs/CommandGuide/llvm-addr2line.html)) for actual address lookup. 

This direct access of the native Swift runtime function is needed until [SE-262](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0262-demangle.md) is formally integrated into the standard library.

## Using llvm-addr2line

If you want to use [`llvm-addr2line`](https://llvm.org/docs/CommandGuide/llvm-addr2line.html) instead of the `gimli-rs/addr2line`, add the following to the `swift-build` stage of your Dockerfile:

```Dockerfile
# swift-build stage
RUN apt-get update && apt-get install -y llvm-19
```

This installs the LLVM tools, making the binary available at `/usr/bin/llvm-addr2line-19`. Then `docker-compose.yml` environment should be updated:

```bash
    environment:
      - ADDR2LINE_PATH=/usr/bin/llvm-addr2line-19
```

