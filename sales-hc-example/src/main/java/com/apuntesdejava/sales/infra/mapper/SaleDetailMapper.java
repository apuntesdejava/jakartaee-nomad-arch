package com.apuntesdejava.sales.infra.mapper;

import com.apuntesdejava.sales.dao.entity.SaleDetailEntity;
import com.apuntesdejava.sales.domain.model.SaleDetail;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;

import static org.mapstruct.MappingConstants.ComponentModel.JAKARTA_CDI;

@Mapper(componentModel = JAKARTA_CDI)
public interface SaleDetailMapper {

    @Mapping(target = "sale", ignore = true)
    SaleDetail entityToModel(SaleDetailEntity entity);
 
    SaleDetailEntity modelToEntity(SaleDetail model);
}
