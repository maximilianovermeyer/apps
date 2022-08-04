
variable "app_name" {
  type    = string
  default = "wireguard"
}

variable "app_version" {
  type    = string
  default = "latest"
}

variable "hcloud_image" {
  type    = string
  default = "ubuntu-22.04"
}

variable "apt_packages" {
  type    = string
  default = "wireguard"
}

variable "wireguard_ui_version" {
  type    = string
  default = "0.4.1"
}

variable "caddy_version" {
  type    = string
  default = "2.5.1"
}

variable "git-sha" {
  type    = string
  default = "${env("GITHUB_SHA")}"
}

variable "hcloud_api_token" {
  type      = string
  default   = "${env("HCLOUD_API_TOKEN")}"
  sensitive = true
}

variable "snapshot_name" {
  type = string
  default = "packer-{{timestamp}}"
}

source "hcloud" "autogenerated_1" {
  image       = "${var.hcloud_image}"
  location    = "nbg1"
  server_name = "hcloud-app-builder-${var.app_name}-{{timestamp}}"
  server_type = "cx11"
  snapshot_labels = {
    git-sha   = "${var.git-sha}"
    version   = "${var.app_version}"
    slug      = "oneclick-${var.app_name}-${var.app_version}-${var.hcloud_image}"
  }
  snapshot_name = "${var.snapshot_name}"
  ssh_username  = "root"

  # Workaround until https://github.com/hashicorp/packer/issues/11733 is released
  user_data = "#!/bin/sh\necho PubkeyAcceptedKeyTypes=+ssh-rsa >> /etc/ssh/sshd_config; service ssh reload"

  token         = "${var.hcloud_api_token}"
}

build {
  sources = ["source.hcloud.autogenerated_1"]

  provisioner "shell" {
    inline = ["cloud-init status --wait"]
  }

  provisioner "file" {
    destination = "/etc/"
    source      = "apps/hetzner/wireguard/files/etc/"
  }

  provisioner "file" {
    destination = "/opt/"
    source      = "apps/hetzner/wireguard/files/opt/"
  }

  provisioner "file" {
    destination = "/var/"
    source      = "apps/hetzner/wireguard/files/var/"
  }

  provisioner "shell" {
    environment_vars = ["DEBIAN_FRONTEND=noninteractive", "LC_ALL=C", "LANG=en_US.UTF-8", "LC_CTYPE=en_US.UTF-8"]
    scripts          = ["apps/shared/scripts/apt-upgrade.sh"]
  }

  provisioner "shell" {
    environment_vars = ["DEBIAN_FRONTEND=noninteractive", "LC_ALL=C", "LANG=en_US.UTF-8", "LC_CTYPE=en_US.UTF-8"]
    inline           = ["apt -qqy -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install ${var.apt_packages}"]
  }

  provisioner "shell" {
    environment_vars = ["application_name=${var.app_name}", "application_version=${var.app_version}", "wireguard_ui_version=${var.wireguard_ui_version}", "caddy_version=${var.caddy_version}", "DEBIAN_FRONTEND=noninteractive", "LC_ALL=C", "LANG=en_US.UTF-8", "LC_CTYPE=en_US.UTF-8"]
    scripts          = ["apps/shared/scripts/apt-upgrade.sh", "apps/hetzner/wireguard/scripts/install.sh", "apps/shared/scripts/cleanup.sh"]
  }
}
