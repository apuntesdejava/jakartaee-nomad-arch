# Job de Nomad para el microservicio de ventas.
# Este servicio es Jakarta EE sobre Payara Micro; ademas de conectarse a MySQL,
# consume clients y products por REST a traves del gateway Fabio.
job "sales-backend" {
  # "dc1" coincide con el datacenter local del agente Nomad dev. El tipo service
  # hace que Nomad mantenga la aplicacion viva y registrada.
  datacenters = ["dc1"]
  type        = "service"

  # Grupo web del servicio sales. count = 1 define una instancia inicial; luego
  # se puede escalar con "nomad job scale sales-backend web N".
  group "web" {
    count = 1

    # Publicacion de red para Payara. Nomad asigna un puerto del host y lo conecta
    # al puerto 8080 del contenedor.
    network {
      mode = "host"
      port "http" {
#        Puede fijarse para depurar, pero el gateway no necesita puertos fijos.
#        static = 8083
        to     = 8080
      }
    }

    # Registro de sales en Consul. Fabio usa este registro y el tag urlprefix para
    # enrutar las llamadas publicas /sales hacia la allocation saludable.
    service {
      name = "sales-backend"
      port = "http"
      tags = ["urlprefix-/sales"]

      # Health check de Payara Micro. Si no responde, Consul marca la instancia
      # como no saludable y Fabio deja de balancear trafico hacia ella.
      check {
        type     = "http"
        path     = "/health"
        interval = "10s"
        timeout  = "5s"
      }
    }

    # Tarea de contenedor que ejecuta la imagen Payara Micro con el WAR de sales.
    task "sales" {
      driver = "podman"

      # Habilita el acceso de esta tarea a Vault con la policy creada para Nomad.
      vault {
        policies = ["nomad-cluster"]
      }

      # Genera el XML de recursos JDBC que Payara necesita para crear el pool
      # sales-pool y el recurso JNDI jdbc/sales. Los valores salen de Vault.
      template {
        data = <<EOF
{{- with secret "kv/data/mysql" -}}
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE resources PUBLIC
        "-//GlassFish.org//DTD GlassFish Application Server 3.1 Resource Definitions//EN"
        "http://glassfish.java.net/dtd/glassfish-resources_1_5.dtd">
<resources>
    <jdbc-connection-pool
            name="sales-pool"
            datasource-classname="com.mysql.cj.jdbc.MysqlDataSource"
            res-type="javax.sql.DataSource">
        <property name="url"      value="{{ .Data.data.url | replaceAll "&" "&amp;" }}"/>
        <property name="user"     value="{{ .Data.data.user }}"/>
        <property name="password" value="{{ .Data.data.password }}"/>
    </jdbc-connection-pool>

    <jdbc-resource
            jndi-name="jdbc/sales"
            pool-name="sales-pool"/>
</resources>
{{- end -}}
EOF
        destination = "local/payara-resources.xml"
      }

      # Ademas del XML de Payara, se exponen las credenciales como variables de
      # entorno por si la aplicacion o herramientas auxiliares las necesitan.
      template {
        data = <<EOH
DB_USER="{{ with secret "kv/data/mysql" }}{{ .Data.data.user }}{{ end }}"
DB_PASSWORD="{{ with secret "kv/data/mysql" }}{{ .Data.data.password }}{{ end }}"
JDBC_URL="{{ with secret "kv/data/mysql" }}{{ .Data.data.url }}{{ end }}"
EOH
        destination = "local/secrets.env"
        env         = true
      }

      # Payara ejecuta comandos post-boot al arrancar. Este archivo le indica que
      # cargue el XML JDBC generado dinamicamente por Nomad.
      template {
        data        = "add-resources /local/payara-resources.xml"
        destination = "local/post-boot.txt"
      }

      # Configuracion del contenedor Payara: imagen, puerto y argumentos de
      # arranque. --deploymentDir despliega el WAR incluido en la imagen.
      config {
        image = "docker.io/apuntesdejava/sales-hc-example:0.0.1"
        ports = ["http"]
        args  = [
          "--postbootcommandfile", "/local/post-boot.txt",
          "--deploymentDir", "/opt/payara/deployments",
          "--nocluster"
        ]
      }

      # URLs de servicios externos para los clientes REST de MicroProfile. Se usa
      # Fabio en el puerto 8000 del host para que sales consuma clients/products
      # igual que un consumidor externo.
      env {
        COM_APUNTESDEJAVA_SALES_SERVICES_PRODUCTSERVICE_MP_REST_URL = "http://${attr.unique.network.ip-address}:8000/products/api"
        COM_APUNTESDEJAVA_SALES_SERVICES_CLIENTSERVICE_MP_REST_URL  = "http://${attr.unique.network.ip-address}:8000/clients/api"
        # PAYARA_ARGS ajusta el puerto real asignado por Nomad y desactiva cluster
        # interno de Payara para esta demo.
        PAYARA_ARGS = "--port ${NOMAD_PORT_http} --nocluster"
      }

      # Sales reserva un poco mas de memoria que Quarkus porque corre Payara Micro.
      resources {
        cpu    = 500
        memory = 512
      }
    }
  }
}
