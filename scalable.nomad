job "sales-scalable" {
  datacenters = ["dc1"]

  #GRUPO 0: Balanceador
  group "loadbalancer" {
    count = 1
    network {
      port "lb" { static = 9999 }
      port "ui" { static = 9998 }
    }
    task "fabio" {
      driver = "docker"
      config {
        image = "fabiolb/fabio:1.6.11"
        ports = ["lb", "ui"]
        args = ["-proxy.addr=:9999", "-ui.addr=:9998"]
      }
      env {
        FABIO_REGISTRY_CONSUL_ADDR     = "${attr.unique.network.ip-address}:8500"
        FABIO_REGISTRY_CONSUL_REGISTER = "false"
      }
      resources {
        cpu    = 200
        memory = 128
      }
      service {
        name = "fabio-ui"
        port = "ui"
        tags = ["fabio-ui"]

        check {
          type     = "http"
          path     = "/health"
          interval = "10s"
          timeout  = "2s"
        }
      }
    }
  }

  # GRUPO 1: Base de Datos
  group "database" {
    count = 1
    network {
      mode = "host"
      port "db" {
        static = 3306
        to     = 3306
      }
    }

    task "mariadb" {
      driver = "docker"

      template {
        data = file("db/init.sql")
        destination = "local/init.sql"
        change_mode = "noop"
      }

      config {
        image = "mariadb:12.2.2"
        ports = ["db"]
        args = ["--bind-address=0.0.0.0"]
        volumes = [
          "local/init.sql:/docker-entrypoint-initdb.d/init.sql",
        ]
      }

      env {
        MARIADB_ROOT_PASSWORD = "sales"
        MARIADB_DATABASE      = "sales"
        MARIADB_USER          = "sales"
        MARIADB_PASSWORD      = "sales"
      }
      service {
        name         = "mariadb"
        port         = "db"
        address_mode = "host"
        check {
          type     = "tcp"
          interval = "10s"
          timeout  = "2s"
        }
      }
      resources {
        cpu    = 500
        memory = 512
      }
    }
  }

  # GRUPO 2: API Quarkus Products
  group "products-grp" {
    count = 1

    network {

      port "http" {
        to = 8080
      }
    }

    service {
      name = "products-api"
      port = "http"
      tags = ["urlprefix-/products/api"]

      check {
        type     = "http"
        path     = "/products/api/q/health"
        interval = "10s"
        timeout  = "2s"
      }
    }

    task "api" {
      driver = "docker"
      env {
        QUARKUS_DATASOURCE_JDBC_URL = "jdbc:mariadb://${attr.unique.network.ip-address}:3306/sales?useSSL=false"
        QUARKUS_DATASOURCE_USERNAME = "sales"
        QUARKUS_DATASOURCE_PASSWORD = "sales"
        QUARKUS_HTTP_HOST           = "0.0.0.0"
        QUARKUS_HTTP_PORT           = "${NOMAD_PORT_http}"
      }
      config {
        image = "quarkus/products-hc-example-jvm:0.0.1"
        ports = ["http"]
      }

      resources {
        cpu    = 200
        memory = 256
      }
    }
  }
  # GRUPO 3: API Quarkus Clients
  group "clients-grp" {
    count = 1

    network {

      port "http" {
        to = 8080
      }
    }

    service {
      name = "clients-api"
      port = "http"
      tags = ["urlprefix-/clients/api"]

      check {
        type     = "http"
        path     = "/clients/api/q/health"
        interval = "10s"
        timeout  = "2s"
      }
    }

    task "api" {
      driver = "docker"
      env {
        QUARKUS_DATASOURCE_JDBC_URL = "jdbc:mariadb://${attr.unique.network.ip-address}:3306/sales?useSSL=false"
        QUARKUS_DATASOURCE_USERNAME = "sales"
        QUARKUS_DATASOURCE_PASSWORD = "sales"
        QUARKUS_HTTP_HOST           = "0.0.0.0"
        QUARKUS_HTTP_PORT           = "${NOMAD_PORT_http}"
      }
      config {
        image = "quarkus/clients-hc-example-jvm:0.0.1"
        ports = ["http"]
      }

      resources {
        cpu    = 200
        memory = 256
      }
    }
  }

  # GRUPO 4: Payara Micro Sales
  group "sales-grp" {
    count = 1

    network {
      port "http" {
        to = 8080
      }
    }

    service {
      name = "sales-api"
      port = "http"
      tags = ["urlprefix-/sales/api"]

      check {
        type     = "http"
        path     = "/health"
        interval = "10s"
        timeout  = "2s"
      }
    }

    task "payara" {
      driver = "docker"

      config {
        image = "payara/sales-hc-example:0.0.1"
        ports = ["http"]
        volumes = [
          "local/post-boot-commands.asadmin:/opt/payara/post-boot-commands.asadmin"
        ]
        args = [
          "--postbootcommandfile", "/opt/payara/post-boot-commands.asadmin",
          "--deploy", "/opt/payara/deployments/sales-app.war"
        ]
      }

      template {
        destination = "local/post-boot-commands.asadmin"
        change_mode = "restart"
        data        = <<EOH
# Crear Pool de conexiones a Base de Datos
create-jdbc-connection-pool --datasourceclassname org.mariadb.jdbc.MariaDbDataSource --restype javax.sql.DataSource --property user=sales:password=sales:url="jdbc:mariadb://{{ range service "mariadb" }}{{ .Address }}:{{ .Port }}{{ end }}/sales" salesPool
create-jdbc-resource --connectionpoolid salesPool jdbc/sales

# Configurar Clientes REST via Consul Service Discovery
set-config-property --source=domain --propertyName=com.apuntesdejava.sales.services.ProductService/mp-rest/url --propertyValue=http://{{ range service "products-api" }}{{ .Address }}:{{ .Port }}{{ end }}/products/api
set-config-property --source=domain --propertyName=com.apuntesdejava.sales.services.ClientService/mp-rest/url --propertyValue=http://{{ range service "clients-api" }}{{ .Address }}:{{ .Port }}{{ end }}/clients/api
EOH
      }

      resources {
        cpu    = 500
        memory = 512
      }
    }
  }

}