package com.apuntesdejava.sales.domain.model;

import jakarta.json.bind.annotation.JsonbProperty;

public record Client(
    Integer id,
    @JsonbProperty("firstName")
    String firstName, String lastName, String email) {
}
