package com.apuntesdejava.sales.infra.mapper;

import com.apuntesdejava.sales.dao.entity.SaleEntity;
import com.apuntesdejava.sales.domain.model.Sale;
import org.mapstruct.Mapper;
import org.mapstruct.MappingConstants;

@Mapper(componentModel = MappingConstants.ComponentModel.JAKARTA_CDI)
public interface SaleMapper {

    Sale entityToModel(SaleEntity entity);

    SaleEntity modelToEntity(Sale model);
}
