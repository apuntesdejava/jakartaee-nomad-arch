package com.apuntesdejava.products.app.resource;

import jakarta.inject.Inject;
import jakarta.json.Json;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.Response;

import javax.sql.DataSource;
import java.net.InetAddress;
import java.net.UnknownHostException;
import java.sql.SQLException;

import static jakarta.ws.rs.core.MediaType.APPLICATION_JSON;

@Path("/check-database")
@Produces(APPLICATION_JSON)

public class CheckDatabaseResource {

    private final DataSource dataSource;

    @Inject
    public CheckDatabaseResource(DataSource dataSource) {
        this.dataSource = dataSource;
    }

    @GET
    public Response getStatus() {
        var response = Json.createObjectBuilder();
        try {
            response.add("node", InetAddress.getLocalHost().getHostName());
            response.add("framework", "Quarkus - Supersonic Subatomic Java");
            response.add("orchestrator", "HashiCorp Nomad");
        } catch (UnknownHostException e) {
            response.add("error_host", e.getMessage());
        }

        try (var con = dataSource.getConnection()) {
            boolean valid = con.isValid(2);
            response.add("database_status", valid ? "CONECTADO 🟢" : "FALLO 🔴");
            response.add("db_metadata", con.getMetaData().getDatabaseProductVersion());
            response.add("db_name", con.getMetaData().getDatabaseProductName());
        } catch (SQLException e) {
            response.add("database_status", "ERROR: " + e.getMessage());
        }

        return Response
            .ok(response.build())
            .build();
    }

}
