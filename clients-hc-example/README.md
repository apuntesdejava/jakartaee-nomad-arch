# Clients service

`clients-hc-example` is the clients API used by the demo. It is a Quarkus JVM application built with Quarkus REST JSON-B, Hibernate ORM with Panache, and SmallRye Health.

The default development profile uses H2. The production profile uses MySQL and produces the container image consumed by the local Nomad deployment.

Run it in Quarkus development mode:

```bash
./mvnw quarkus:dev
```

Build the application:

```bash
./mvnw package
```

For the complete architecture and local startup procedure, see the [repository README](../README.md) and [local environment guide](../docs/local-environment.md).
