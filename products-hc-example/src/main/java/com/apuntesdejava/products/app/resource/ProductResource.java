package com.apuntesdejava.products.app.resource;

import com.apuntesdejava.products.domain.model.Product;
import com.apuntesdejava.products.domain.repository.ProductRepository;
import jakarta.inject.Inject;
import jakarta.ws.rs.Consumes;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.PathParam;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.Response;

import static jakarta.ws.rs.core.MediaType.APPLICATION_JSON;

@Path("product")
@Produces(APPLICATION_JSON)
@Consumes(APPLICATION_JSON)
public class ProductResource {

    private final ProductRepository productRepository;

    @Inject
    public ProductResource(ProductRepository productRepository) {
        this.productRepository = productRepository;
    }

    @GET
    public Response findAll() {
        var productsList = productRepository.findAll();
        return Response.ok(productsList).build();
    }

    @POST
    public Response create(Product request) {
        var created = productRepository.save(request);
        return Response.status(Response.Status.CREATED)
            .entity(created)
            .build();
    }

    @GET
    @Path("{id}")
    public Response findById(@PathParam("id") Integer id) {
        var product = productRepository.findById(id);
        return product.map(Response::ok)
            .orElse(Response.status(Response.Status.NOT_FOUND))
            .build();
    }

}
