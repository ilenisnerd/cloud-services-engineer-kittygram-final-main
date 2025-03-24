# Настройка провайдера
terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
  
   backend "s3" {
    endpoints = {
      s3 = "https://storage.yandexcloud.net"
    }
    bucket = "kittygram-tf-state"
    region = "ru-central1"
    key    = "tf-state.tfstate"

    skip_region_validation      = true
    skip_credentials_validation = true
    skip_requesting_account_id  = true
    skip_s3_checksum            = true
  }
}

provider "yandex" {
  token     = var.yc_token
  cloud_id  = var.cloud_id
  folder_id = var.folder_id
  zone      = "ru-central1-a"
}

variable "yc_token" {
  description = "Yandex Cloud OAuth token"
  type        = string
  sensitive   = true
}

variable "cloud_id" {
  description = "Yandex Cloud ID"
  type        = string
}

variable "folder_id" {
  description = "Yandex Cloud Folder ID"
  type        = string
}

# Создание сети
resource "yandex_vpc_network" "network" {
  name = "network1"
}

# Создание подсети
resource "yandex_vpc_subnet" "subnet" {
  name           = "subnet1"
  network_id     = yandex_vpc_network.network.id
  v4_cidr_blocks = ["192.168.10.0/24"]
}

resource "yandex_vpc_security_group" "kittygram_sg" {
  name        = "kittygram-security-group"
  description = "Security group for Kittygram VM"
  network_id  = yandex_vpc_network.network.id

  # Входящий трафик: SSH (порт 22)
  ingress {
    protocol       = "TCP"
    description    = "Allow SSH"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 22
  }

  # Входящий трафик: HTTP для gateway (порт 8000)
  ingress {
    protocol       = "TCP"
    description    = "Allow HTTP for gateway"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 8000
  }

  # Исходящий трафик: разрешить весь
  egress {
    protocol       = "ANY"
    description    = "Allow all outbound traffic"
    v4_cidr_blocks = ["0.0.0.0/0"]
    from_port      = 0
    to_port        = 65535
  }
}

# Создание ВМ
resource "yandex_compute_instance" "vm" {
  name = "terraform-vm"

  resources {
    cores  = 2
    memory = 2
  }

  boot_disk {
    initialize_params {
      image_id = "fd8ou6hurlbfqmi57ofd" # Ubuntu 24.04 LTS
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.subnet.id
    nat       = true
    security_group_ids = [yandex_vpc_security_group.kittygram_sg.id]
  }

  metadata = {
    ssh-keys = "ubuntu:${file("my_ssh_key.pub")}"
    user-data = <<EOT
#cloud-config
package_update: true
package_upgrade: true

packages:
  - docker.io
  - docker-compose-plugin

runcmd:
  - systemctl enable docker
  - systemctl start docker
  - usermod -aG docker ubuntu
EOT
  }
} 

resource "yandex_storage_bucket" "terraform_state" {
  bucket     = "kittygram-tf-state"
  acl        = "private"
  folder_id  = var.folder_id

  versioning {
    enabled = true
  }
}