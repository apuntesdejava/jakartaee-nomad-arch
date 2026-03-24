package com.apuntesdejava.sales.services;

import com.apuntesdejava.sales.domain.model.Product;
import com.apuntesdejava.sales.services.exceptions.ProductExceptionMapper;
import jakarta.ws.rs.Consumes;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.PathParam;
import jakarta.ws.rs.Produces;
import org.eclipse.microprofile.rest.client.annotation.RegisterProvider;
import org.eclipse.microprofile.rest.client.inject.RegisterRestClient;

import static jakarta.ws.rs.core.MediaType.APPLICATION_JSON;

@Path("product")
@Produces(APPLICATION_JSON)
@Consumes(APPLICATION_JSON)
@RegisterRestClient
@RegisterProvider(ProductExceptionMapper.class)
public interface ProductService {

    @GET
    @Path("{id}")
    Product findById(@PathParam("id") Integer id);
}
