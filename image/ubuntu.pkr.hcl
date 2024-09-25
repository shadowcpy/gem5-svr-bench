packer {
  required_plugins {
    qemu = {
      source  = "github.com/hashicorp/qemu"
      version = "~> 1"
    }
  }
}


variable "ubuntu_version" {
  type        = string
  # default     = "focal"
  # default     = "jammy"
  default     = "noble"
  description = "Ubuntu codename version (i.e. 20.04 is focal and 22.04 is jammy and 24.04 is noble)."
}

variable "arch" {
  type        = string
  default     = "arm64"
  description = "Architecture to build the image for."
}


variable "ssh_username" {
  type    = string
  default = "gem5"
}

variable "ssh_password" {
  type    = string
  default = "1234"
}



source "qemu" "ubuntu" {
  cpus             = "16"
  memory           = "8192"
  accelerator      = "kvm"

  disk_compression = true
  disk_image       = true
  disk_size        = "10G"
  headless         = true

  iso_checksum     = "file:https://cloud-images.ubuntu.com/${var.ubuntu_version}/current/SHA256SUMS"
  iso_url          = "https://cloud-images.ubuntu.com/${var.ubuntu_version}/current/${var.ubuntu_version}-server-cloudimg-${var.arch}.img"
  output_directory = "output-${var.ubuntu_version}"
  vm_name          = "ubuntu-${var.ubuntu_version}.img"

  # qemu_binary      = "/usr/bin/qemu-system-x86_64"
  # qemuargs         = [["-cpu", "host"], ["-display", "none"]]

  qemu_binary      = "/usr/bin/qemu-system-aarch64"
  qemuargs = [
          ["-boot", "order=dc"],
          ["-bios", "./flash0.img"],
          ["-cpu", "host"],
          ["-enable-kvm"],
          ["-machine", "virt"],
          ["-machine", "gic-version=max"],
          ["-serial", "mon:stdio"],
  #  ["-drive", "file=flash0.img,format=raw,if=pflash" ],
  #  ["-drive", "file=flash1.img,format=raw,if=pflash" ],
  ]
  
  shutdown_command = "echo '${var.ssh_password}'|sudo -S shutdown -P now"
  
  cd_files         = ["./cloud-init/*"]
  cd_label         = "cidata"
  ssh_password     = "${var.ssh_password}"
  ssh_username     = "${var.ssh_username}"
  ssh_wait_timeout = "60m"
  ssh_handshake_attempts = "1000"
}

build {
  sources = ["source.qemu.ubuntu"]



  provisioner "file" {
    destination = "/home/gem5/"
    source      = "files/exit.sh"
  }

  provisioner "file" {
    destination = "/home/gem5/"
    source      = "files/gem5_init.sh"
  }

  provisioner "file" {
    destination = "/home/gem5/"
    source      = "files/after_boot.sh"
  }

  provisioner "file" {
    destination = "/home/gem5/"
    source      = "files/serial-getty@.service"
  }

  # provisioner "shell" {
  #   execute_command = "echo '${var.ssh_password}' | {{ .Vars }} sudo -E -S bash '{{ .Path }}'"
  #   scripts         = ["scripts/post-installation.sh"]
  #   expect_disconnect = true
  # }


  provisioner "shell" {
    // run scripts with sudo, as the default cloud image user is unprivileged
    execute_command = "echo '${var.ssh_password}' | sudo -S sh -c '{{ .Vars }} {{ .Path }}'"
    // NOTE: cleanup.sh should always be run last, as this performs post-install cleanup tasks
    scripts = [
      "scripts/install.sh",
      #"scripts/cleanup.sh",
      "scripts/post-installation.sh",
    ]
    expect_disconnect = true
  }
}