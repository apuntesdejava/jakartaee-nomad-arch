package com.apuntesdejava.sales.domain.repository;

import com.apuntesdejava.sales.dao.entity.SaleDetailEntity;
import com.apuntesdejava.sales.domain.model.SaleDetail;

import java.util.Collection;
import java.util.List;

public interface SaleDetailRepository {
    List<SaleDetailEntity> saveAll(Collection<SaleDetail> detailsModel);
}
