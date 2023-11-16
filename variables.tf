variable "existing_vpc_name" {
  description = "The name of an existing VPC where the cluster will be deployed."
  type        = string
}

variable "zone" {
  description = "The zone where the cluster will be deployed."
  type        = string
}

variable "prefix" {
  description = "The prefix to use for all consul compute instances. If not set, defaults to consul."
  type        = string
  default     = "consul"
}

variable "resource_group_id" {
  description = "The ID of the resource group where the cluster will be deployed."
  type        = string
}

variable "consul_sg_rules" {
  description = "A list of security group rules to be added to the Consul security group"
  type = list(
    object({
      name      = string
      direction = string
      remote    = string
      tcp = optional(
        object({
          port_max = optional(number)
          port_min = optional(number)
        })
      )
      udp = optional(
        object({
          port_max = optional(number)
          port_min = optional(number)
        })
      )
      icmp = optional(
        object({
          type = optional(number)
          code = optional(number)
        })
      )
    })
  )

  validation {
    error_message = "Security group rules can only have one of `icmp`, `udp`, or `tcp`."
    condition = (var.frontend_rules == null || length(var.frontend_rules) == 0) ? true : length(distinct(
      # Get flat list of results
      flatten([
        # Check through rules
        for rule in var.frontend_rules :
        # Return true if there is more than one of `icmp`, `udp`, or `tcp`
        true if length(
          [
            for type in ["tcp", "udp", "icmp"] :
            true if rule[type] != null
          ]
        ) > 1
      ])
    )) == 0 # Checks for length. If all fields all correct, array will be empty
  }

  validation {
    error_message = "Security group rule direction can only be `inbound` or `outbound`."
    condition = (var.frontend_rules == null || length(var.frontend_rules) == 0) ? true : length(distinct(
      flatten([
        # Check through rules
        for rule in var.frontend_rules :
        # Return false if direction is not valid
        false if !contains(["inbound", "outbound"], rule.direction)
      ])
    )) == 0
  }

  validation {
    error_message = "Security group rule names must match the regex pattern ^([a-z]|[a-z][-a-z0-9]*[a-z0-9])$."
    condition = (var.frontend_rules == null || length(var.frontend_rules) == 0) ? true : length(distinct(
      flatten([
        # Check through rules
        for rule in var.frontend_rules :
        # Return false if direction is not valid
        false if !can(regex("^([a-z]|[a-z][-a-z0-9]*[a-z0-9])$", rule.name))
      ])
    )) == 0
  }

  default = [
    {
      name       = "consul-dns-tcp-inbound"
      direction  = "inbound"
      remote     = "0.0.0.0/0"
      ip_version = "ipv4"
      tcp = {
        port_min = 8600
        port_max = 8600
      }
    },
    {
      name       = "consul-dns-udp-inbound"
      direction  = "inbound"
      remote     = "0.0.0.0/0"
      ip_version = "ipv4"
      udp = {
        port_min = 8600
        port_max = 8600
      }
    },
    {
      name       = "consul-api-tcp-inbound"
      direction  = "inbound"
      remote     = "0.0.0.0/0"
      ip_version = "ipv4"
      tcp = {
        port_min = 8500
        port_max = 8500
      }
    },
    {
      name       = "consul-lan-wan-rpc-serf-tcp-inbound"
      direction  = "inbound"
      remote     = "0.0.0.0/0"
      ip_version = "ipv4"
      tcp = {
        port_min = 8300
        port_max = 8302
      }
    },
    {
      name       = "consul-lan-wan-serf-udp-inbound"
      direction  = "inbound"
      remote     = "0.0.0.0/0"
      ip_version = "ipv4"
      udp = {
        port_min = 8301
        port_max = 8302
      }
    },
    {
      name       = "http-outbound"
      direction  = "outbound"
      remote     = "0.0.0.0/0"
      ip_version = "ipv4"
      tcp = {
        port_min = 80
        port_max = 80
      }
    },

    {
      name       = "https-outbound"
      direction  = "outbound"
      remote     = "0.0.0.0/0"
      ip_version = "ipv4"
      tcp = {
        port_min = 443
        port_max = 443
      }
    },
    {
      name       = "iaas-services-outbound"
      direction  = "outbound"
      remote     = "161.26.0.0/16"
      ip_version = "ipv4"
    },
    {
      name       = "cloud-services-outbound"
      direction  = "outbound"
      remote     = "166.8.0.0/14"
      ip_version = "ipv4"
    }
  ]
}


variable "consul_server_count" {
  description = "The number of consul server nodes to deploy."
  type        = number
  default     = 3
  validation {
    condition     = contains([1, 3, 5], var.consul_server_count)
    error_message = "Error: Incorrect value for consul_server_count. Supported options are 1, 3, or 5."
  }
}


