package com.apuntesdejava.sales.dao.repository;

import com.apuntesdejava.sales.dao.entity.SaleDetailEntity;
import jakarta.data.repository.BasicRepository;
import jakarta.data.repository.Repository;

@Repository
public interface SaleDetailEntityRepository extends BasicRepository<SaleDetailEntity, Integer> {
}
