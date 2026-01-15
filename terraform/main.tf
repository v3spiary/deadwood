#####################
# S3 bucket for shared data
#####################

resource "selectel_objectstorage_bucket_v1" "shared_s3" {
  name = "my-shared-bucket"
  acl  = "private"
}

#####################
# Network
#####################

resource "openstack_networking_network_v2" "private_net" {
  name           = "private-network"
  admin_state_up = true
}

resource "openstack_networking_subnet_v2" "private_subnet" {
  name       = "private-subnet"
  network_id = openstack_networking_network_v2.private_net.id
  cidr       = "10.0.0.0/24"
  ip_version = 4
}

# Внешняя сеть: ID нужно взять из панели/CLI
# Можно сделать data-сурс, но здесь жёстко, чтобы не плодить файлы.
resource "openstack_networking_router_v2" "router" {
  name                = "router"
  admin_state_up      = true
  external_network_id = "EXTERNAL-NETWORK-ID" # поменяй
}

resource "openstack_networking_router_interface_v2" "router_interface" {
  router_id = openstack_networking_router_v2.router.id
  subnet_id = openstack_networking_subnet_v2.private_subnet.id
}

#####################
# SSH keypair
#####################

resource "openstack_compute_keypair_v2" "default_key" {
  name       = "default-key"
  public_key = file("~/.ssh/id_rsa.pub")
}

#####################
# Image and flavor
#####################

data "openstack_images_image_v2" "ubuntu_22_04" {
  name        = "Ubuntu-22.04"
  most_recent = true
}

data "openstack_compute_flavor_v2" "default_flavor" {
  name = "Standard-4-8" # смени на нужный flavor
}

#####################
# Boot volume and server
#####################

resource "openstack_blockstorage_volume_v3" "cpu_boot_volume" {
  name        = "cpu-server-boot"
  size        = 40
  image_id    = data.openstack_images_image_v2.ubuntu_22_04.id
  volume_type = "network-ssd"
}

resource "openstack_compute_instance_v2" "cpu_server" {
  name      = "cpu-server"
  flavor_id = data.openstack_compute_flavor_v2.default_flavor.id
  key_pair  = openstack_compute_keypair_v2.default_key.name

  networks {
    uuid = openstack_networking_network_v2.private_net.id
  }

  block_device {
    uuid                  = openstack_blockstorage_volume_v3.cpu_boot_volume.id
    source_type           = "volume"
    destination_type      = "volume"
    boot_index            = 0
    delete_on_termination = false
  }

  security_groups = ["default"]

  user_data = file("${path.module}/cloud-init-common.yaml")
}
