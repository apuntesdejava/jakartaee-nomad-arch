job "products-backend" {
  datacenters = ["dc1"]
  type        = "service"

  group "api" {
    network {
      mode = "host"
      port "http" {
        static = 8082
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
        image = "apuntesdejava/products-hc-example-jvm:0.0.1"
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
