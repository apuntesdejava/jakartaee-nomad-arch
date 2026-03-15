package com.apuntesdejava.clients.app.resource;


import com.apuntesdejava.clients.domain.model.Client;
import com.apuntesdejava.clients.domain.repository.ClientRepository;
import jakarta.inject.Inject;
import jakarta.ws.rs.Consumes;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.Response;

import static jakarta.ws.rs.core.MediaType.APPLICATION_JSON;

@Path("client")
@Produces(APPLICATION_JSON)
@Consumes(APPLICATION_JSON)
public class ClientResource {

    @Inject
    private ClientRepository clientRepository;

    @GET
    public Response findAll(){
        return Response.ok(
            clientRepository.findAll()
        ).build();
    }

    @POST
    public Response create(Client client){
        var created = clientRepository.save(client);
        return Response.status(Response.Status.CREATED)
            .entity(created)
            .build();
    }
}
