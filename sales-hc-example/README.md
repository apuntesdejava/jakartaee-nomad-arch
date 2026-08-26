# Sales service

`sales-hc-example` is the sales API used by the demo. It is a Jakarta EE web application packaged as a WAR and run with Payara Micro. The service coordinates sales operations with the clients and products APIs.

The default development profile runs Payara Micro with H2 on port `8070`. The production profile uses MySQL and produces the container image consumed by the local Nomad deployment.

Build and run it in development mode:

```bash
./mvnw package payara-micro:dev
```

Build the WAR without starting Payara Micro:

```bash
./mvnw package
```

For the complete architecture and local startup procedure, see the [repository README](../README.md) and [local environment guide](../docs/local-environment.md).

