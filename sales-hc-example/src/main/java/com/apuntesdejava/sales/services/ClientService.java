package com.apuntesdejava.sales.services;

import com.apuntesdejava.sales.domain.model.Client;
import com.apuntesdejava.sales.services.exceptions.ClientExceptionMapper;
import jakarta.ws.rs.Consumes;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.PathParam;
import jakarta.ws.rs.Produces;
import org.eclipse.microprofile.rest.client.annotation.RegisterProvider;
import org.eclipse.microprofile.rest.client.inject.RegisterRestClient;

import static jakarta.ws.rs.core.MediaType.APPLICATION_JSON;

@Path("client")
@Produces(APPLICATION_JSON)
@Consumes(APPLICATION_JSON)
@RegisterRestClient
@RegisterProvider(ClientExceptionMapper.class)
public interface ClientService {

    @GET
    @Path("{id}")
    Client findById(@PathParam("id") Integer id);
}
