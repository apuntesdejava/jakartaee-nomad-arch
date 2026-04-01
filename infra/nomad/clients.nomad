job "clients-backend" {
  datacenters = ["dc1"]
  type        = "service"

  group "api" {
    count = 1

    network {
      mode = "host"
      port "http" { to = 8081 }
    }

    service {
      name = "clients-backend"
      port = "http"


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
        image = var.registry != "" ? "${var.registry}/clients-hc-example-jvm:0.0.1" : "quarkus/clients-hc-example-jvm:0.0.1"
        ports = ["http"]
      }

      env {
        QUARKUS_HTTP_PORT           = "8081"
        QUARKUS_DATASOURCE_DB_KIND  = "mysql"
        QUARKUS_DATASOURCE_JDBC_URL = "jdbc:mysql://host.docker.internal:3306/appdb"
        QUARKUS_DATASOURCE_USERNAME = "appuser"
        QUARKUS_DATASOURCE_PASSWORD = "apppass"
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