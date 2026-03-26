package com.apuntesdejava.clients.app.resource;


import com.apuntesdejava.clients.domain.model.Client;
import com.apuntesdejava.clients.domain.repository.ClientRepository;
import jakarta.inject.Inject;
import jakarta.ws.rs.Consumes;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.PathParam;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.Response;
import org.jboss.logging.Logger;

import static jakarta.ws.rs.core.MediaType.APPLICATION_JSON;

@Path("client")
@Produces(APPLICATION_JSON)
@Consumes(APPLICATION_JSON)
public class ClientResource {
    private static final Logger LOGGER = Logger.getLogger(ClientResource.class);

    @Inject
    private ClientRepository clientRepository;

    @GET
    public Response findAll() {
        return Response.ok(
            clientRepository.findAll()
        ).build();
    }

    @POST
    public Response create(Client client) {
        var created = clientRepository.save(client);
        return Response.status(Response.Status.CREATED)
            .entity(created)
            .build();
    }

    @GET
    @Path("{id}")
    public Response findById(@PathParam("id") Integer id) {
        LOGGER.infof("findById:%s", id);
        return clientRepository.findById(id)
            .map(client -> Response.ok(client).build())
            .orElseGet(() -> Response.status(Response.Status.NOT_FOUND).build());

    }
}
