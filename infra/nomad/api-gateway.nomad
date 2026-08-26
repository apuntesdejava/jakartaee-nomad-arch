# Job de Nomad para Fabio, el gateway HTTP dinámico.
# Fabio observa el catálogo de Consul y crea rutas automáticamente a partir de
# tags como urlprefix-/clients, urlprefix-/products y urlprefix-/sales.
job "api-gateway" {
  # type = "system" significa que Nomad ejecuta una instancia por cada cliente
  # elegible. En local hay un solo cliente, asi que queda un Fabio.
  datacenters = ["dc1"]
  type        = "system"

  # Grupo que contiene la tarea Fabio y sus puertos públicos.
  group "fabio" {
    # Fabio necesita puertos estáticos porque es la entrada pública de la demo:
    # 8000 para trafico API y 9998 para la UI de Fabio.
    network {
      mode = "host"
      port "lb" {
        static = 8000
      }
      port "ui" {
        static = 9998
      }
    }

    # Tarea de contenedor con la imagen oficial de Fabio.
    task "fabio" {
      driver = "podman"
      
      # Expone los puertos declarados en network hacia el contenedor.
      config {
        image = "docker.io/fabiolb/fabio:1.7.3"
        network_mode = "host"
        ports = ["lb", "ui"]
      }

      # Fabio se conecta a Consul en el host local del nodo. Desde Consul lee los
      # servicios saludables y sus tags urlprefix para construir la tabla de rutas.
      env {
        FABIO_REGISTRY_CONSUL_ADDR = "${attr.unique.network.ip-address}:8500"
        FABIO_PROXY_ADDR = ":8000"
      }

      # Gateway ligero: reserva pocos recursos en comparación con los backends.
      resources {
        cpu    = 200
        memory = 128
      }
    }
  }
}
