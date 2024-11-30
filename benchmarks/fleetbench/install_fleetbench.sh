#!/bin/bash -eux


## Install bazel for fleetbench
sudo apt install apt-transport-https curl gnupg -y
curl -fsSL https://bazel.build/bazel-release.pub.gpg | gpg --dearmor >bazel-archive-keyring.gpg
sudo mv bazel-archive-keyring.gpg /usr/share/keyrings
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/bazel-archive-keyring.gpg] https://storage.googleapis.com/bazel-apt stable jdk1.8" | sudo tee /etc/apt/sources.list.d/bazel.list



sudo apt update && sudo apt install -y bazel zip unzip


## Install fleetbench
git clone https://github.com/google/fleetbench.git


cd fleetbench
mkdir -p build

VERSION=c1d0f72

git checkout $VERSION
git apply ../fleetbench.patch




## Build fleetbench

BENCHMARKS=()
BENCHMARKS+=("proto:proto_benchmark")
BENCHMARKS+=("swissmap:swissmap_benchmark")
BENCHMARKS+=("libc:mem_benchmark")
BENCHMARKS+=("tcmalloc:empirical_driver")
BENCHMARKS+=("compression:compression_benchmark")
BENCHMARKS+=("hashing:hashing_benchmark")
BENCHMARKS+=("stl:cord_benchmark")




for BENCHMARK in "${BENCHMARKS[@]}"; do
  BENCHMARK_NAME=$(echo $BENCHMARK | cut -d':' -f1)
  BENCHMARK_TARGET=$(echo $BENCHMARK | cut -d':' -f2)
  bazel --output_base=build run --config=opt fleetbench/${BENCHMARK_NAME}:${BENCHMARK_TARGET}
done


