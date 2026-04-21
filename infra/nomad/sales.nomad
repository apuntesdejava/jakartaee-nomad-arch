variable "project_root" {
  type    = string
  default = ""
}

job "sales-backend" {
  datacenters = ["dc1"]
  type        = "service"

  group "web" {
    count = var.instance_count

    network {
      mode = var.network_mode
      port "http" {
        static = var.network_mode == "host" ? 8083 : 0
        to     = 8080
      }
    }

    service {
      name = "sales-backend"
      port = "http"
      tags = ["urlprefix-/sales"]

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
        image = var.registry != "" ? "${var.registry}/sales-hc-example:latest" : "apuntesdejava/sales-hc-example:latest"
        ports = ["http"]
      }

      env {
        # Direcciones de servicios
        COM_APUNTESDEJAVA_SALES_SERVICES_PRODUCTSERVICE_MP_REST_URL = var.network_mode == "host" ? "http://${attr.unique.network.ip-address}:8082/products/api" : "http://localhost:19080/products/api"
        COM_APUNTESDEJAVA_SALES_SERVICES_CLIENTSERVICE_MP_REST_URL  = var.network_mode == "host" ? "http://${attr.unique.network.ip-address}:8081/clients/api"   : "http://localhost:19090/clients/api"

        # Configuración de Payara
        PAYARA_ARGS = var.network_mode == "host" ? "--port ${NOMAD_PORT_http} --nocluster" : "--port 8080 --nocluster"

        # Credenciales de base de datos
        DB_USER = "appuser"
        DB_PASSWORD = "apppass123!"
        JDBC_URL = "jdbc:mysql://127.0.0.1:3306/appdb"
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

variable "network_mode" {
  type    = string
  default = "host"
}

variable "instance_count" {
  type    = number
  default = 1
}