package com.apuntesdejava.clients.infra.mapper;

import com.apuntesdejava.clients.dao.entity.ClientEntity;
import com.apuntesdejava.clients.domain.model.Client;
import org.mapstruct.Mapper;
import org.mapstruct.MappingConstants;

@Mapper(componentModel = MappingConstants.ComponentModel.JAKARTA_CDI)

public interface ClientMapper {
    Client entityToModel(ClientEntity entity);

    ClientEntity modelToEntity(Client model);
}
