package com.apuntesdejava.clients.infra.repository;

import com.apuntesdejava.clients.dao.repository.ClientEntityRepository;
import com.apuntesdejava.clients.domain.model.Client;
import com.apuntesdejava.clients.domain.repository.ClientRepository;
import com.apuntesdejava.clients.infra.mapper.ClientMapper;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import jakarta.transaction.Transactional;
import lombok.extern.java.Log;

import java.util.List;
import java.util.Optional;

@ApplicationScoped
@Log
public class ClientRepositoryImpl implements ClientRepository {

    private final ClientMapper clientMapper;

    private final ClientEntityRepository clientEntityRepository;

    @Inject
    public ClientRepositoryImpl(ClientMapper clientMapper, ClientEntityRepository clientEntityRepository) {
        this.clientMapper = clientMapper;
        this.clientEntityRepository = clientEntityRepository;
    }

    @Override
    @Transactional
    public Client save(Client client) {
        log.info("-- Saving model: " + client);
        var entity = clientMapper.modelToEntity(client);
        log.info("** Saving entity: " + entity);
        clientEntityRepository.persist(entity);
        return clientMapper.entityToModel(entity);
    }

    @Override
    public List<Client> findAll() {
        return clientEntityRepository.streamAll()
            .map(clientMapper::entityToModel)
            .toList();
    }

    @Override
    public Optional<Client> findById(Integer id) {
        return clientEntityRepository.findByIdOptional(id)
            .map(clientMapper::entityToModel);
    }
}
