# Job de Nomad para el microservicio de clientes.
# Un job describe que workload se ejecuta, donde puede correr y como Nomad debe
# registrarlo, monitorearlo y conectarlo con otros componentes de la plataforma.
job "clients-backend" {
  # En modo local, start-local.sh arranca Nomad en el datacenter lógico "dc1".
  # El tipo "service" indica que este workload debe mantenerse corriendo y puede
  # registrarse para service discovery.
  datacenters = ["dc1"]
  type        = "service"

  # Un grupo agrupa tareas que se ejecutan juntas en el mismo nodo. Aquí solo hay
  # una tarea Docker, pero el grupo también define red, puertos y registro Consul.
  group "api" {
    # Red del grupo. Con mode = "host", el contenedor usa un puerto del host WSL.
    # Nomad asigna dinámicamente el puerto externo y lo expone como NOMAD_PORT_http.
    network {
      mode = "host"
      port "http" {
#        Si necesitas un puerto fijo para depurar, puedes activar static.
#        static = 8081
        # Dentro del contenedor Quarkus escucha en 8080; Nomad enruta el puerto
        # dinámico del host hacia ese puerto interno.
        to     = 8080
      }
    }

    # Registro del servicio en Consul. Fabio lee este registro para descubrir a
    # que allocation debe enviar las llamadas que entren por /clients.
    service {
      name = "clients-backend"
      port = "http"
      # urlprefix es la convención de Fabio: todo lo que empiece con /clients se
      # enruta a las instancias saludables de este servicio.
      tags = ["urlprefix-/clients"]

      # Health check HTTP que Consul ejecuta periódicamente. Si falla, Fabio deja
      # de enviar trafico a esa allocation.
      check {
        type     = "http"
        path     = "/clients/api/q/health/ready"
        interval = "10s"
        timeout  = "3s"
      }
    }

    # Tarea principal del grupo. Nomad usara el driver Docker para descargar y
    # ejecutar la imagen JVM de Quarkus.
    task "clients" {
      driver = "docker"

      # Permite que esta tarea pida secretos a Vault usando la policy indicada.
      # start-local.sh configura Vault y la integración Workload Identity antes
      # de lanzar los jobs.
      vault {
        policies = ["nomad-cluster"]
      }

      # Template renderizado por Nomad antes de arrancar la tarea. Lee credenciales
      # desde Vault KV y las escribe como variables de entorno en secrets.env.
      template {
        data = <<EOH
QUARKUS_DATASOURCE_USERNAME="{{ with secret "kv/data/mysql" }}{{ .Data.data.user }}{{ end }}"
QUARKUS_DATASOURCE_PASSWORD="{{ with secret "kv/data/mysql" }}{{ .Data.data.password }}{{ end }}"
QUARKUS_DATASOURCE_JDBC_URL="{{ with secret "kv/data/mysql" }}{{ .Data.data.url }}{{ end }}"
EOH
        destination = "local/secrets.env"
        env         = true
      }

      # Configuración específica del driver Docker: imagen a ejecutar y puertos
      # definidos en el bloque network que deben exponerse al contenedor.
      config {
        image = "apuntesdejava/clients-hc-example-jvm:0.0.1"
        ports = ["http"]
      }

      # Variables de entorno propias de Quarkus. QUARKUS_HTTP_PORT toma el puerto
      # dinámico asignado por Nomad para que el proceso escuche donde corresponde.
      env {
        QUARKUS_HTTP_PORT           = "${NOMAD_PORT_http}"
        QUARKUS_DATASOURCE_DB_KIND  = "mysql"
        JAVA_OPTS_APPEND            = "-Dquarkus.http.host=0.0.0.0"
      }

      # Límites/reservas de recursos para que Nomad pueda planificar el workload
      # y evitar que una allocation consuma todo el nodo.
      resources {
        cpu    = 500
        memory = 384
      }
    }
  }
}
