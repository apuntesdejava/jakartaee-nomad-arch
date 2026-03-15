package com.apuntesdejava.products.domain.repository;

import com.apuntesdejava.products.domain.model.Product;

import java.util.List;
import java.util.Optional;

public interface ProductRepository {

    Product save(Product product);

    List<Product> findAll();

    Optional<Product> findById(Integer id);
}
