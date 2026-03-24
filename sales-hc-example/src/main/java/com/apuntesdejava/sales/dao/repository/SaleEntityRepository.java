package com.apuntesdejava.sales.dao.repository;

import com.apuntesdejava.sales.dao.entity.SaleEntity;
import jakarta.data.repository.CrudRepository;
import jakarta.data.repository.Query;
import jakarta.data.repository.Repository;
import jakarta.transaction.Transactional;

@Repository
public interface SaleEntityRepository extends CrudRepository<SaleEntity, Integer> {

    @Transactional
    @Query("UPDATE SaleEntity s SET s.totalPrice = :salePrice WHERE s.id = :id")
    int updateSalePrice(Integer id, Double salePrice);

}
