package com.apuntesdejava.sales.services.exceptions;

import jakarta.ws.rs.core.Response;
import jakarta.ws.rs.ext.Provider;
import lombok.extern.java.Log;
import org.eclipse.microprofile.rest.client.ext.ResponseExceptionMapper;

@Provider
@Log
public class ProductExceptionMapper implements ResponseExceptionMapper<RuntimeException> {

    @Override
    public RuntimeException toThrowable(Response response) {

        return new RuntimeException("Error HTTP:" + response.getStatus());
    }
}
