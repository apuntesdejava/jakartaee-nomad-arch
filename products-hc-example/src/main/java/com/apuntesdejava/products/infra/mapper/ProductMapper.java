package com.apuntesdejava.products.infra.mapper;

import com.apuntesdejava.products.dao.entity.ProductEntity;
import com.apuntesdejava.products.domain.model.Product;
import org.mapstruct.Mapper;
import org.mapstruct.MappingConstants;

@Mapper(componentModel = MappingConstants.ComponentModel.JAKARTA_CDI)
public interface ProductMapper {

    Product entityToModel(ProductEntity entity);

    ProductEntity modelToEntity(Product model);
}
