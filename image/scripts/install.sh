#!/bin/bash -eux

echo "==> waiting for cloud-init to finish"
while [ ! -f /var/lib/cloud/instance/boot-finished ]; do
    echo 'Waiting for Cloud-Init...'
    sleep 1
done

echo "==> updating apt cache"
sudo apt-get update -qq

echo "==> upgrade apt packages"
sudo apt-get upgrade -y -qq

echo "==> installing qemu-guest-agent"
sudo apt-get install -y -qq qemu-guest-agent

echo "==> installing docker-ce"

sudo apt-get install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update


sudo apt-get install -y \
    docker-ce \
    docker-ce-cli \
    containerd.io \
    docker-buildx-plugin \
    docker-compose-plugin


## For docker on Ubuntu +20.04
sudo update-alternatives --set iptables /usr/sbin/iptables-legacy
sudo update-alternatives --set ip6tables /usr/sbin/ip6tables-legacy


# ## Disable other unnecessary services
# systemctl disable systemd-modules-load.service
# systemctl disable multipathd.service
# systemctl disable apt-daily-upgrade.timer
# sudo apt autoremove -y --purge snapd
# sudo apt-mark hold snapd