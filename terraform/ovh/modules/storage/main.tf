locals {
  tags = setunion(var.tags != null ? var.tags : [], [
    "by Terraform",
    replace(var.addresses, "/", "_"),
    "storage",
  ])
  user_data = templatefile("${path.module}/templates/user_data.tftpl", {
    ssh_keys  = var.ssh_keys
    addresses = var.addresses
    gw        = var.gw
    dns       = var.dns != null ? var.dns : "8.8.8.8"
    search    = var.search != null ? var.search : ""
    shares    = var.shares != null ? var.shares : []
  })
}

data "cidr_network" "addresses" {
  prefix = var.addresses
}

data "openstack_images_image_v2" "image" {
  region      = var.region
  name        = var.image_name
  most_recent = true
}

resource "openstack_networking_port_v2" "port" {
  region                = var.region
  network_id            = var.network_id
  admin_state_up        = true
  no_security_groups    = true
  port_security_enabled = false
  fixed_ip {
    ip_address = data.cidr_network.addresses.ip
    subnet_id  = var.subnet_id
  }
}

resource "openstack_blockstorage_volume_v2" "storage_volume" {
  region = var.region
  name   = "storage_volume"
  size   = var.storage_size
}

resource "openstack_compute_instance_v2" "storage" {
  region = var.region
  name   = var.server_name

  image_id    = data.openstack_images_image_v2.image.id
  flavor_name = var.flavor_name
  block_device {
    uuid                  = data.openstack_images_image_v2.image.id
    source_type           = "image"
    destination_type      = "local"
    boot_index            = 0
    delete_on_termination = true
  }
  block_device {
    uuid                  = openstack_blockstorage_volume_v2.storage_volume.id
    source_type           = "volume"
    boot_index            = 1
    destination_type      = "volume"
    delete_on_termination = false
  }
  tags         = local.tags
  config_drive = true

  network {
    port = openstack_networking_port_v2.port.id
  }

  user_data = local.user_data
}
