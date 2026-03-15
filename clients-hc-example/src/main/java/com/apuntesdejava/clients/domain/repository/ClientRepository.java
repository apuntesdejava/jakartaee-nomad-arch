package com.apuntesdejava.clients.domain.repository;

import com.apuntesdejava.clients.domain.model.Client;

import java.util.List;
import java.util.Optional;

public interface ClientRepository {
    Client save(Client client);

    List<Client> findAll();

    Optional<Client> findById(Integer id);
}
