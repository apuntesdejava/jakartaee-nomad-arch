package com.apuntesdejava.sales.domain.model;

import java.time.LocalDateTime;
import java.util.Collection;

public record Sale(
        Integer id,
        LocalDateTime saleDate,
        Integer clientId,
        Double totalPrice,
        Collection<SaleDetail> details) {
}
