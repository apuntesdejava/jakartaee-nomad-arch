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

      # Obtenemos la configuración dinámicamente desde Consul KV
      template {
        data            = "[[ key \"configs/payara-resources\" ]]"
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

      # El comando es una sola línea, lo generamos aquí para garantizar la ruta /local
      template {
        data        = "add-resources /local/payara-resources.xml"
        destination = "local/post-boot.txt"
      }

      config {
        image = var.registry != "" ? "${var.registry}/sales-hc-example:0.0.1" : "payara/sales-hc-example:0.0.1"
        ports = ["http"]
        args  = [
          "--postbootcommandfile", "/local/post-boot.txt",
          "--deploymentDir", "/opt/payara/deployments"
        ]
      }

      env {
        # En host mode apunta a los puertos estáticos directos
        # En bridge mode apunta a los upstreams de Envoy
        COM_APUNTESDEJAVA_SALES_SERVICES_PRODUCTSERVICE_MP_REST_URL = var.network_mode == "host" ? "http://${attr.unique.network.ip-address}:8082/products/api" : "http://localhost:19080/products/api"
        COM_APUNTESDEJAVA_SALES_SERVICES_CLIENTSERVICE_MP_REST_URL  = var.network_mode == "host" ? "http://${attr.unique.network.ip-address}:8081/clients/api"   : "http://localhost:19090/clients/api"

        # Puerto de Payara según el modo
        PAYARA_ARGS = var.network_mode == "host" ? "--port 8083" : "--port 8080"
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