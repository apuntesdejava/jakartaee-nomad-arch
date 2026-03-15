package com.apuntesdejava.sales.dao.repository;

import com.apuntesdejava.sales.dao.entity.SaleEntity;
import jakarta.data.repository.BasicRepository;
import jakarta.data.repository.Repository;

@Repository
public interface SaleEntityRepository extends BasicRepository<SaleEntity, Integer> {


}
