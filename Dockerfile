# build Swift wrapper
FROM swift AS swift-build

ENV PARCA_VERSION=v0.24.0

# Install curl and download Swift Static SDK
RUN apt-get update \
    && apt-get install -y curl

# To add llvm-addr2line
#RUN apt-get install -y llvm-19

#RUN curl -L -o swift-6.1.2-RELEASE_static-linux-0.0.1.artifactbundle.tar.gz \
#    https://download.swift.org/swift-6.1.2-release/static-sdk/swift-6.1.2-RELEASE/swift-6.1.2-RELEASE_static-linux-0.0.1.artifactbundle.tar.gz \
#    && tar -xzf swift-6.1.2-RELEASE_static-linux-0.0.1.artifactbundle.tar.gz \
#    && swift sdk install swift-6.1.2-RELEASE_static-linux-0.0.1.artifactbundle.tar.gz \
#    && rm swift-6.1.2-RELEASE_static-linux-0.0.1.artifactbundle.tar.gz
#RUN swift sdk list

WORKDIR /app

# Copy swift project
COPY . .

RUN swift build --configuration release

# Download Parca
RUN ARCH=$(uname -m) \
    && if [ "$ARCH" = "aarch64" ]; then ARCH="arm64"; fi \
    && curl -sL https://github.com/parca-dev/parca/releases/download/${PARCA_VERSION}/parca_${PARCA_VERSION#v}_`uname -s`_$ARCH.tar.gz | tar xvfz - \
    && mv parca /parca \
    && chmod +x /parca \
    && curl -sL https://raw.githubusercontent.com/parca-dev/parca/main/parca.yaml > /parca.yaml

# build gimli addr2line
FROM rust:1.81 AS rust-build
RUN cargo install addr2line --features="bin"

# Final stage
FROM swift:slim

# Grant permissions for Parca to persisted storage
RUN mkdir -p /data && chown 65534:65534 /data && chmod 775 /data

# Copy binaries build
COPY --from=swift-build /app/.build/release/addr2line-swift /usr/local/bin/addr2line-swift
COPY --from=swift-build /parca /parca
COPY --from=swift-build /parca.yaml /parca.yaml
COPY --from=rust-build /usr/local/cargo/bin/addr2line /usr/local/bin/addr2line-gimli

USER nobody
ENTRYPOINT ["/parca"]