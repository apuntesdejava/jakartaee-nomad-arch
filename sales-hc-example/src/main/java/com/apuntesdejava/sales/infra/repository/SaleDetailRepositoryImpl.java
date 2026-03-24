package com.apuntesdejava.sales.infra.repository;

import com.apuntesdejava.sales.dao.entity.SaleDetailEntity;
import com.apuntesdejava.sales.dao.repository.SaleDetailEntityRepository;
import com.apuntesdejava.sales.domain.model.SaleDetail;
import com.apuntesdejava.sales.domain.repository.SaleDetailRepository;
import com.apuntesdejava.sales.infra.mapper.SaleDetailMapper;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import jakarta.transaction.Transactional;
import lombok.extern.java.Log;

import java.util.Collection;
import java.util.List;

@ApplicationScoped
@Transactional
@Log
public class SaleDetailRepositoryImpl implements SaleDetailRepository {

    @Inject
    private SaleDetailMapper detailMapper;

    @Inject
    private SaleDetailEntityRepository detailEntityRepository;

    @Override
    public List<SaleDetailEntity> saveAll(Collection<SaleDetail> detailsModel) {

        var entities = detailsModel
            .stream()
            .map(detailMapper::modelToEntity)
            .toList();
        return detailEntityRepository.saveAll(entities);
    }
}
