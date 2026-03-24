package com.apuntesdejava.sales.infra.mapper;

import com.apuntesdejava.sales.dao.entity.SaleEntity;
import com.apuntesdejava.sales.domain.model.Sale;
import org.mapstruct.AfterMapping;
import org.mapstruct.Mapper;
import org.mapstruct.MappingTarget;

import static org.mapstruct.MappingConstants.ComponentModel.JAKARTA_CDI;

@Mapper(componentModel = JAKARTA_CDI, uses = {SaleDetailMapper.class})
public interface SaleMapper {

    Sale entityToModel(SaleEntity entity);

    SaleEntity modelToEntity(Sale model);

    @AfterMapping
    default void linkDetails(@MappingTarget SaleEntity saleEntity) {
        if (saleEntity.getDetails() != null) {
            saleEntity.getDetails().forEach(detail -> detail.setSale(saleEntity));
        }
    }
}
