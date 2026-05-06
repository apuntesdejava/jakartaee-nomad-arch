job "clients-backend" {
  datacenters = ["dc1"]
  type        = "service"

  group "api" {
    network {
      mode = "host"
      port "http" {
#        static = 8081
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
        image = "apuntesdejava/clients-hc-example-jvm:0.0.1"
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
