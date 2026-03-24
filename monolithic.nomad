job "sales-monolith" {
  datacenters = ["dc1"]

  # GRUPO 1: Base de Datos (Igual que siempre)
  group "database" {
    count = 1
    network {
      mode = "host"
      port "db" {
        static = 3306
        to = 3306
      }
    }

    task "mariadb" {
      driver = "docker"

      template {
        data        = file("db/init.sql")
        destination = "local/init.sql"
        change_mode = "noop"
      }

      config {
        image = "mariadb:12.2.2"
        ports = ["db"]
        args  = ["--bind-address=0.0.0.0"]
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
        name = "mariadb"
        port = "db"
        address_mode = "host"
        check {
          type     = "tcp"
          interval = "10s"
          timeout  = "2s"
        }
      }
      resources {
        cpu = 500
        memory = 512
      }
    }
  }

  # GRUPO 2: API Quarkus (Modo Solitario)
  group "products-grp" {
    count = 1  # <--- Solo UNO. El punto único de fallo.

    network {
      # Puerto ESTÁTICO 8080.
      # Aquí no hay balanceador, conectamos directo a la aplicación.
      port "http" { static = 8080 }
    }

    task "api" {
      driver = "docker"
      config {
        image = "quarkus/products-hc-example-jvm:0.0.1"
        ports = ["http"]
      }

      env {
        # Conexión a la DB
        QUARKUS_DATASOURCE_JDBC_URL = "jdbc:mariadb://${attr.unique.network.ip-address}:3306/sales?useSSL=false"
        QUARKUS_DATASOURCE_USERNAME = "sales"
        QUARKUS_DATASOURCE_PASSWORD = "sales"
        QUARKUS_HTTP_HOST           = "0.0.0.0"
      }

      # Registramos el servicio solo para salud, pero no hay Fabio escuchando etiquetas
      service {
        name = "api-products"
        port = "http"
        address_mode = "host"

        check {
          type     = "http"
          path     = "/products/api/q/health"
          interval = "10s"
          timeout  = "2s"
        }
      }

      resources {
        cpu = 200
        memory = 256
      }
    }
  }


  group "clients-grp" {
    count = 1  # <--- Solo UNO. El punto único de fallo.

    network {
      # Puerto ESTÁTICO 8080.
      # Aquí no hay balanceador, conectamos directo a la aplicación.
      port "http" { static = 8090 }
    }

    task "api" {
      driver = "docker"
      config {
        image = "quarkus/clients-hc-example-jvm:0.0.1"
        ports = ["http"]
      }

      env {
        # Conexión a la DB
        QUARKUS_DATASOURCE_JDBC_URL = "jdbc:mariadb://${attr.unique.network.ip-address}:3306/sales?useSSL=false"
        QUARKUS_DATASOURCE_USERNAME = "sales"
        QUARKUS_DATASOURCE_PASSWORD = "sales"
        QUARKUS_HTTP_HOST           = "0.0.0.0"
      }

      # Registramos el servicio solo para salud, pero no hay Fabio escuchando etiquetas
      service {
        name = "api-clients"
        port = "http"
        address_mode = "host"

        check {
          type     = "http"
          path     = "/clients/api/q/health"
          interval = "10s"
          timeout  = "2s"
        }
      }

      resources {
        cpu = 200
        memory = 256
      }
    }
  }
}