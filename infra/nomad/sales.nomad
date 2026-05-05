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
        data = <<EOF
{{ with secret "kv/data/mysql" }}
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE resources PUBLIC
        "-//GlassFish.org//DTD GlassFish Application Server 3.1 Resource Definitions//EN"
        "http://glassfish.java.net/dtd/glassfish-resources_1_5.dtd">
<resources>
    <jdbc-connection-pool
            name="sales-pool"
            datasource-classname="com.mysql.cj.jdbc.MysqlDataSource"
            res-type="javax.sql.DataSource">
        <property name="url"      value="{{ .Data.data.url }}"/>
        <property name="user"     value="{{ .Data.data.user }}"/>
        <property name="password" value="{{ .Data.data.password }}"/>
    </jdbc-connection-pool>

    <jdbc-resource
            jndi-name="jdbc/sales"
            pool-name="sales-pool"/>
</resources>
{{ end }}
EOF
        destination = "local/payara-resources.xml"
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
          "--deploymentDir", "/opt/payara/deployments",
          "--nocluster"
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
