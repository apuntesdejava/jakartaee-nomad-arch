package com.apuntesdejava.sales.domain.model;

import java.time.LocalDateTime;

public record Sale(
    Integer id,
    LocalDateTime saleDate,
    Integer clientId,
    Double totalPrice
) {
}
