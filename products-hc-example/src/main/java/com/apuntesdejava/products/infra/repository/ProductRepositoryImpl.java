package com.apuntesdejava.products.infra.repository;

import com.apuntesdejava.products.dao.repository.ProductEntityRepository;
import com.apuntesdejava.products.domain.model.Product;
import com.apuntesdejava.products.domain.repository.ProductRepository;
import com.apuntesdejava.products.infra.mapper.ProductMapper;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import jakarta.transaction.Transactional;

import java.util.List;
import java.util.Optional;

@ApplicationScoped
public class ProductRepositoryImpl implements ProductRepository {

    private final ProductEntityRepository productEntityRepository;

    private final ProductMapper productMapper;

    @Inject
    public ProductRepositoryImpl(
        ProductEntityRepository productEntityRepository,
        ProductMapper productMapper
    ) {
        this.productEntityRepository = productEntityRepository;
        this.productMapper = productMapper;
    }

    @Override
    @Transactional
    public Product save(Product product) {
        var entity = productMapper.modelToEntity(product);
        productEntityRepository.persist(entity);
        return productMapper.entityToModel(entity);
    }

    @Override
    public List<Product> findAll() {
        return productEntityRepository
            .streamAll()
            .map(productMapper::entityToModel)
            .toList();
    }

    @Override
    public Optional<Product> findById(Integer id) {
        return productEntityRepository.findByIdOptional(id)
            .map(productMapper::entityToModel);

    }
}
