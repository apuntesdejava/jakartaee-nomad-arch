package com.apuntesdejava.products.dao.repository;

import com.apuntesdejava.products.dao.entity.ProductEntity;
import io.quarkus.hibernate.orm.panache.PanacheRepositoryBase;
import jakarta.enterprise.context.ApplicationScoped;

@ApplicationScoped
public class ProductEntityRepository implements PanacheRepositoryBase<ProductEntity, Integer> {
}
