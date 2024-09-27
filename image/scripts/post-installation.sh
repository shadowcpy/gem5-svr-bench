#!/bin/bash

# Copyright (c) 2024 The Regents of the University of California.
# SPDX-License-Identifier: BSD 3-Clause

echo 'Post Installation Started'

echo 'installing packages'
apt-get update
apt-get install -y scons
apt-get install -y git
apt-get install -y vim
apt-get install -y build-essential

echo "Installing serial service for autologin after systemd"
mv /home/gem5/serial-getty@.service /lib/systemd/system/

echo "Installing the gem5 init script in /sbin"
mv /home/gem5/gem5_init.sh /sbin
mv /sbin/init /sbin/init.old
ln -s /sbin/gem5_init.sh /sbin/init

# Add after_boot.sh to bashrc in the gem5 user account
# This will run the script after the user automatically logs in
echo -e "\nif [ -z \"\$AFTER_BOOT_EXECUTED\" ]; then\n   export AFTER_BOOT_EXECUTED=1\n    /home/gem5/after_boot.sh\nfi\n" >> /home/gem5/.bashrc

# Remove the motd
rm /etc/update-motd.d/*

# Build and install the gem5-bridge (m5) binary, library, and headers
echo "Building and installing gem5-bridge (m5) and libm5"

# Just get the files we need
git clone https://github.com/gem5/gem5.git --depth=1 --filter=blob:none --no-checkout --sparse --single-branch --branch=stable
pushd gem5
# Checkout just the files we need
git sparse-checkout add util/m5
git sparse-checkout add include
git checkout
# Install the headers globally so that other benchmarks can use them
sudo cp -r include/gem5 /usr/local/include/\

ARCH=$(dpkg --print-architecture)
if [ ${ARCH} == amd64 ]; then
    ARCH=x86
fi

# Build the library and binary
pushd util/m5
scons build/${ARCH}/out/m5
sudo cp build/${ARCH}/out/m5 /usr/local/bin/
sudo cp build/${ARCH}/out/libm5.a /usr/local/lib/
popd
popd


# Set the setuid bit on the m5 binary
chmod 4755 /usr/local/bin/m5
chmod u+s /usr/local/bin/m5

#create a symbolic link to the gem5 binary for backward compatibility
ln -s /usr/local/bin/m5 /usr/local/bin/gem5-bridge

# delete the git repo for gem5
rm -rf gem5
echo "Done building and installing gem5-bridge (m5) and libm5"

# You can extend this script to install your own packages here.

# # Disable network by default
# echo "Disabling network by default"
# echo "See README.md for instructions on how to enable network"
# if [ -f /etc/netplan/50-cloud-init.yaml ]; then
#     mv /etc/netplan/50-cloud-init.yaml /etc/netplan/50-cloud-init.yaml.bak
# elif [ -f /etc/netplan/00-installer-config.yaml ]; then
#     mv /etc/netplan/00-installer-config.yaml /etc/netplan/00-installer-config.yaml.bak
#     netplan apply
# fi

echo "Post Installation Done"
