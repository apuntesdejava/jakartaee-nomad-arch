package com.apuntesdejava.clients.dao.repository;

import com.apuntesdejava.clients.dao.entity.ClientEntity;
import io.quarkus.hibernate.orm.panache.PanacheRepositoryBase;
import jakarta.enterprise.context.ApplicationScoped;

@ApplicationScoped
public class ClientEntityRepository implements PanacheRepositoryBase<ClientEntity, Integer> {
}
