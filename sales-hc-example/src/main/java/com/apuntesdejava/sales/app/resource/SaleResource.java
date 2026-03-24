package com.apuntesdejava.sales.app.resource;

import com.apuntesdejava.sales.domain.model.Sale;
import com.apuntesdejava.sales.services.SaleService;
import jakarta.inject.Inject;
import jakarta.ws.rs.Consumes;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.Response;

import static jakarta.ws.rs.core.MediaType.APPLICATION_JSON;

@Path("sale")
@Produces(APPLICATION_JSON)
@Consumes(APPLICATION_JSON)
public class SaleResource {

    @Inject
    private SaleService saleService;

    @GET
    public Response findAll() {
        var sales = saleService.findAll();
        return Response
            .ok(sales)
            .build();
    }

    @POST
    public Response sale(Sale request) {
        saleService.sale(request);
        return Response.ok().build();
    }


}