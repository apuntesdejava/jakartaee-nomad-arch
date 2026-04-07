job "api-gateway" {
  datacenters = ["dc1"]
  type        = "system"

  group "fabio" {
    network {
      mode = "host"
      port "lb" {
        static = 8000
      }
      port "ui" {
        static = 9998
      }
    }

    task "fabio" {
      driver = "docker"
      
      config {
        image = "fabiolb/fabio:1.7.0"
        ports = ["lb", "ui"]
      }

      env {
        FABIO_REGISTRY_CONSUL_ADDR = "${attr.unique.network.ip-address}:8500"
        FABIO_PROXY_ADDR = ":8000"
      }

      resources {
        cpu    = 200
        memory = 128
      }
    }
  }
}