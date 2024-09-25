# gem5-benchmarks
A framework to run various server workloads on gem5




## Prepare the benchmark disk image

To create a fresh base image with docker and all gem5 tools installed use the `build_image.sh` script in the image folder.

```bash
./image/build_image.sh
```
By default this will build a base image using [packer](https://www.packer.io/) with Ubuntu 24.04. The OS version and the architecture can be configured in the packer configuration script (`ubuntu.pkr.hcl`).
The build process should take less than 20 min after which the new base image will be placed in the `output-noble` directory.


## Install the benchmarks on the disks

The base image has only docker installed and all necessary tools. However, the docker images for the benchmarks are not pulled which needs to be done outside of gem5.

```bash
./image/install.sh
```



## Boot benchmark and take snapshot

Before we can start simulating the actual benchmark (1) linux has to be booted, (2) the docker image has to be started and (3) the benchmarks JIT engine -- very common for server applications -- has to be warmed up.
The KVM accelerated core is used to perform all three steps after which a checkpoint is taken.
> Note KVM can only be used if the host ISA is the same as the simulated system.

### On Arm ISA

```bash
# Start the setup phase with gem5 and take a checkpoint
./<path/to/gem5>/build/ARM/gem5.opt gem5-configs/arm-simple.py --kernel wkdir/kernel --disk wkdir/disk.img --mode=setup
```
This will take 5-10 minutes. The progress can be inspected via the `m5term` terminal or the redirected `board.terminal` log in the output directory.


## Simulation

Once the setup step has been performed and the checkpoint is taken simulations can be performed by invoking the same script with the `--mode=evaluation` parameter.

### On Arm
```bash
# Simulate
./<path/to/gem5>/build/ARM/gem5.opt gem5-configs/arm-simple.py --kernel wkdir/kernel --disk wkdir/disk.img --mode=evaluation
```