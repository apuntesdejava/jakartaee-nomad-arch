job "sales-backend" {
  datacenters = ["dc1"]
  type        = "service"

  group "web" {
    count = 1

    network {
      mode = "host"
      port "http" {
        static = 8083
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

      vault {
        policies = ["nomad-cluster"]
      }

      template {
        data            = "[[key \"configs/payara-resources\"]]"
        destination     = "local/payara-resources.xml"
        left_delimiter  = "[["
        right_delimiter = "]]"
      }

      template {
        data = <<EOH
DB_USER="{{ with secret "kv/data/mysql" }}{{ .Data.data.user }}{{ end }}"
DB_PASSWORD="{{ with secret "kv/data/mysql" }}{{ .Data.data.password }}{{ end }}"
JDBC_URL="{{ with secret "kv/data/mysql" }}{{ .Data.data.url }}{{ end }}"
EOH
        destination = "local/secrets.env"
        env         = true
      }

      template {
        data        = "add-resources /local/payara-resources.xml"
        destination = "local/post-boot.txt"
      }

      config {
        image = "apuntesdejava/sales-hc-example:0.0.1"
        ports = ["http"]
        args  = [
          "--postbootcommandfile", "/local/post-boot.txt",
          "--deploymentDir", "/opt/payara/deployments"
        ]
      }

      env {
        COM_APUNTESDEJAVA_SALES_SERVICES_PRODUCTSERVICE_MP_REST_URL = "http://${attr.unique.network.ip-address}:8082/products/api"
        COM_APUNTESDEJAVA_SALES_SERVICES_CLIENTSERVICE_MP_REST_URL  = "http://${attr.unique.network.ip-address}:8081/clients/api"
        PAYARA_ARGS = "--port ${NOMAD_PORT_http} --nocluster"
      }

      resources {
        cpu    = 500
        memory = 512
      }
    }
  }
}
