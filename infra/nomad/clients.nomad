variable "project_root" {
  type    = string
  default = ""
}

job "clients-backend" {
  datacenters = ["dc1"]
  type        = "service"

  group "api" {
    count = var.instance_count

    network {
      mode = var.network_mode
      port "http" {
        static = var.network_mode == "host" ? 8081 : 0
        to     = 8080
      }
    }

    service {
      name = "clients-backend"
      port = "http"
      tags = ["urlprefix-/clients"]

      check {
        type     = "http"
        path     = "/clients/api/q/health/ready"
        interval = "10s"
        timeout  = "3s"
      }
    }

    task "clients" {
      driver = "docker"

      config {
        image = var.registry != "" ? "${var.registry}/clients-hc-example-jvm:latest" : "apuntesdejava/clients-hc-example-jvm:latest"
        ports = ["http"]
      }

      env {
        QUARKUS_HTTP_PORT           = "${NOMAD_PORT_http}"
        QUARKUS_DATASOURCE_DB_KIND  = "mysql"
        QUARKUS_DATASOURCE_USERNAME = "appuser"
        QUARKUS_DATASOURCE_PASSWORD = "apppass123!"
        QUARKUS_DATASOURCE_JDBC_URL = "jdbc:mysql://127.0.0.1:3306/appdb"
        JAVA_OPTS_APPEND            = "-Dquarkus.http.host=0.0.0.0"
      }

      resources {
        cpu    = 500
        memory = 384
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