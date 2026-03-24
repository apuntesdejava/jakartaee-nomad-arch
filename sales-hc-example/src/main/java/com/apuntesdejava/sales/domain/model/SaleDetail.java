package com.apuntesdejava.sales.domain.model;

public record SaleDetail(
    Integer productId,
    Double count,
    Double totalPrice,
    Sale sale
) {
}
