module "consul_security_group" {
  source                = "terraform-ibm-modules/vpc/ibm//modules/security-group"
  version               = "1.1.1"
  create_security_group = true
  name                  = "${var.prefix}-consul-sg"
  vpc_id                = data.ibm_is_vpc.vpc.id
  resource_group_id     = var.resource_group_id
  security_group_rules  = local.consul_rules
}

resource "ibm_is_instance" "servers" {
  count          = var.consul_server_count
  name           = "${var.prefix}-consul-server-${count.index + 1}"
  vpc            = data.ibm_is_vpc.vpc.id
  image          = data.ibm_is_image.base.id
  profile        = var.instance_profile
  resource_group = module.resource_group.resource_group_id

  # metadata_service {
  #   enabled            = true
  #   protocol           = "https"
  #   response_hop_limit = 5
  # }

  dynamic "metadata_service" {
    for_each = var.metadata_service.enabled ? [1] : []

    content {
      enabled            = var.metadata_service.enabled
      protocol           = var.metadata_service.protocol
      response_hop_limit = var.metadata_service.response_hop_limit
    }
  }

  boot_volume {
    auto_delete_volume = false
    size               = 250
    name               = "${local.prefix}-bastion-boot"
    tags               = concat(local.tags, ["zone:${local.vpc_zones[0].zone}"])
  }

  primary_network_interface {
    subnet            = ibm_is_subnet.frontend.0.id
    allow_ip_spoofing = var.allow_ip_spoofing
    security_groups   = [module.frontend_security_group.security_group_id[0]]
  }

  user_data = var.init_script != "" ? var.init_script : file("${path.module}/init-script.sh")

  zone = local.vpc_zones[0].zone
  keys = local.ssh_key_id
  tags = concat(local.tags, ["zone:${local.vpc_zones[0].zone}"])
}
