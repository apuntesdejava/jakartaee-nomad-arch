job "api-gateway" {
  datacenters = ["dc1"]
  type        = "service"

  group "gateway" {
    count = 1

    network {
      mode = "bridge"
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