job "api-gateway" {
  datacenters = ["dc1"]
  type        = "service"

  group "gateway" {
    count = 1

    network {
      mode = var.network_mode
      port "public" {
        static = 8080
        to     = 8080
      }
    }

    service {
      name = "api-gateway"
      port = "public"

      connect {
        gateway {
          proxy {}
        }
      }
    }
  }
}

variable "network_mode" {
  type    = string
  default = "host"
}