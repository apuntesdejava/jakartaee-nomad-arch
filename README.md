# Ejecutando la aplicación

## Construyendo la aplicación Java

```shell
mvn clean package -P prod
```



## Preparando entorno de ejecución (En WSL)


**Consul**

```bash
consul agent -dev -client 0.0.0.0
```

**Agente Nomad**

```bash
sudo nomad agent -dev -bind=0.0.0.0 -network-interface=eth0 -log-level=DEBUG
```

Para sacar el IP del WSL

hostname -I | awk '{print $1}'