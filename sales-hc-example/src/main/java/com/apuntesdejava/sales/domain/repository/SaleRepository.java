package com.apuntesdejava.sales.domain.repository;

import com.apuntesdejava.sales.domain.model.Sale;

import java.util.List;
import java.util.Optional;

public interface SaleRepository {

    Sale save(Sale sale);

    List<Sale> findAll();

    Optional<Sale> findById(Integer id);
}
