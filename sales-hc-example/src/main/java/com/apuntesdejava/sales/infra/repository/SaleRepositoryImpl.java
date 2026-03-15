package com.apuntesdejava.sales.infra.repository;

import com.apuntesdejava.sales.dao.repository.SaleEntityRepository;
import com.apuntesdejava.sales.domain.model.Sale;
import com.apuntesdejava.sales.domain.repository.SaleRepository;
import com.apuntesdejava.sales.infra.mapper.SaleMapper;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import jakarta.transaction.Transactional;

import java.util.List;
import java.util.Optional;

@ApplicationScoped
@Transactional
public class SaleRepositoryImpl implements SaleRepository {

    @Inject
    private SaleMapper saleMapper;

    @Inject
    private SaleEntityRepository saleEntityRepository;

    @Override
    public Sale save(Sale sale) {
        var entity = saleMapper.modelToEntity(sale);
        var result = saleEntityRepository.save(entity);
        return saleMapper.entityToModel(result);
    }

    @Override
    public List<Sale> findAll() {
        return saleEntityRepository
            .findAll()
            .map(saleMapper::entityToModel)
            .toList();
    }

    @Override
    public Optional<Sale> findById(Integer id) {
        return saleEntityRepository.findById(id)
            .map(saleMapper::entityToModel);
    }
}
