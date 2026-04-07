variable "project_root" {
  type    = string
  default = ""
}

job "products-backend" {
  datacenters = ["dc1"]
  type        = "service"

  group "api" {
    count = var.instance_count

    network {
      mode = var.network_mode
      port "http" {
        static = var.network_mode == "host" ? 8082 : 0
        to     = 8080
      }
    }

    service {
      name = "products-backend"
      port = "http"
      tags = ["urlprefix-/products"]

      check {
        type     = "http"
        path     = "/products/api/q/health/ready"
        interval = "10s"
        timeout  = "3s"
      }
    }

    task "products" {
      driver = "docker"

      vault {
        policies = ["nomad-cluster"]
      }

      template {
        data = <<EOH
QUARKUS_DATASOURCE_USERNAME="{{ with secret "kv/data/mysql" }}{{ .Data.data.user }}{{ end }}"
QUARKUS_DATASOURCE_PASSWORD="{{ with secret "kv/data/mysql" }}{{ .Data.data.password }}{{ end }}"
QUARKUS_DATASOURCE_JDBC_URL="{{ with secret "kv/data/mysql" }}{{ .Data.data.url }}{{ end }}"
EOH
        destination = "local/secrets.env"
        env         = true
      }

      config {
        image = var.registry != "" ? "${var.registry}/products-hc-example-jvm:0.0.1" :           "quarkus/products-hc-example-jvm:0.0.1"
        ports = ["http"]
      }

      env {
        QUARKUS_HTTP_PORT           = "${NOMAD_PORT_http}"
        QUARKUS_DATASOURCE_DB_KIND  = "mysql"
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