# Job de Nomad para el microservicio de productos.
# Mantiene el backend disponible, lo registra en Consul y le inyecta secretos de
# base de datos desde Vault antes de ejecutar la imagen Docker.
job "products-backend" {
  # En el laboratorio local, Nomad corre con un datacenter lógico llamado "dc1".
  # "service" significa que Nomad debe conservar el workload vivo.
  datacenters = ["dc1"]
  type        = "service"

  # Grupo de ejecución del API. Las tareas dentro de un mismo grupo se colocan en
  # el mismo nodo y comparten la configuración de red del grupo.
  group "api" {
    # El modo host publica un puerto del host WSL. Nomad elige el puerto externo
    # si no se fija "static" y lo comunica con la variable NOMAD_PORT_http.
    network {
      mode = "host"
      port "http" {
#        Para depuración local puede fijarse, pero en la demo se prefiere dinámico.
#        static = 8082
        # Quarkus dentro del contenedor escucha en 8080.
        to     = 8080
      }
    }

    # Registro Consul del servicio. Este bloque es lo que hace visible el backend
    # para Fabio y para el catalogo de servicios.
    service {
      name = "products-backend"
      port = "http"
      # Fabio interpreta urlprefix-/products como regla dinámica de gateway.
      tags = ["urlprefix-/products"]

      # Check de readiness de Quarkus. Consul marca como no saludable una
      # allocation que no responda, y Fabio la saca del balanceo.
      check {
        type     = "http"
        path     = "/products/api/q/health/ready"
        interval = "10s"
        timeout  = "3s"
      }
    }

    # Tarea Docker que ejecuta la aplicación products-hc-example.
    task "products" {
      driver = "docker"

      # Autoriza a Nomad a solicitar secretos Vault para esta tarea con la policy
      # configurada por infra/scripts/setup-vault.sh.
      vault {
        policies = ["nomad-cluster"]
      }

      # Renderiza credenciales MySQL desde Vault KV en un archivo env. Con
      # env = true, Nomad carga cada linea como variable de entorno de la tarea.
      template {
        data = <<EOH
QUARKUS_DATASOURCE_USERNAME="{{ with secret "kv/data/mysql" }}{{ .Data.data.user }}{{ end }}"
QUARKUS_DATASOURCE_PASSWORD="{{ with secret "kv/data/mysql" }}{{ .Data.data.password }}{{ end }}"
QUARKUS_DATASOURCE_JDBC_URL="{{ with secret "kv/data/mysql" }}{{ .Data.data.url }}{{ end }}"
EOH
        destination = "local/secrets.env"
        env         = true
      }

      # Imagen Docker y mapeo de puertos que Nomad debe pasar al driver.
      config {
        image = "apuntesdejava/products-hc-example-jvm:0.0.1"
        ports = ["http"]
      }

      # Configuración runtime para Quarkus. El puerto viene de Nomad y la conexion
      # JDBC llega desde el template de Vault.
      env {
        QUARKUS_HTTP_PORT           = "${NOMAD_PORT_http}"
        QUARKUS_DATASOURCE_DB_KIND  = "mysql"
        JAVA_OPTS_APPEND            = "-Dquarkus.http.host=0.0.0.0"
      }

      # Recursos reservados para una instancia de products.
      resources {
        cpu    = 500
        memory = 384
      }
    }
  }
}
