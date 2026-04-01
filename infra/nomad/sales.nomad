job "sales-frontend" {
  datacenters = ["dc1"]
  type        = "service"

  group "web" {
    count = 1

    network {
      mode = "bridge"
      port "http" { to = 8080 }  # puerto de Payara Micro
    }

    service {
      name = "sales-frontend"
      port = "http"

      connect {
        sidecar_service {
          proxy {
            # Puertos internos alejados del 8080 de Payara para evitar conflicto
            upstreams {
              destination_name = "products-backend"
              local_bind_port  = 19080
            }
            upstreams {
              destination_name = "clients-backend"
              local_bind_port  = 19090
            }
          }
        }
      }

      check {
        type     = "http"
        path     = "/health"
        interval = "10s"
        timeout  = "5s"
      }
    }

    task "sales" {
      driver = "docker"

      config {
        image = var.registry != "" ? "${var.registry}/sales-hc-example:0.0.1" : "payara/sales-hc-example:0.0.1"
        ports = ["http"]
      }

      env {
        # Override de microprofile-config.properties via env vars (MicroProfile Config spec)
        # Envoy sidecar escucha en estos puertos locales y enruta al servicio real
        COM_APUNTESDEJAVA_SALES_SERVICES_PRODUCTSERVICE_MP_REST_URL = "http://localhost:19080/products/api"
        COM_APUNTESDEJAVA_SALES_SERVICES_CLIENTSERVICE_MP_REST_URL  = "http://localhost:19090/clients/api"

        JDBC_URL    = "jdbc:mysql://host.docker.internal:3306/appdb"

        DB_USER     = "appuser"
        DB_PASSWORD = "apppass"
      }

      resources {
        cpu    = 500
        memory = 512
      }
    }
  }
}

variable "registry" {
  type    = string
  default = ""
}