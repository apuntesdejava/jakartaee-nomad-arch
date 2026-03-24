package com.apuntesdejava.clients.infra.repository;

import com.apuntesdejava.clients.dao.repository.ClientEntityRepository;
import com.apuntesdejava.clients.domain.model.Client;
import com.apuntesdejava.clients.domain.repository.ClientRepository;
import com.apuntesdejava.clients.infra.mapper.ClientMapper;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import jakarta.transaction.Transactional;
import org.jboss.logging.Logger;

import java.util.List;
import java.util.Optional;

@ApplicationScoped
public class ClientRepositoryImpl implements ClientRepository {

    private final static Logger LOGGER = Logger.getLogger(ClientRepositoryImpl.class);

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
        LOGGER.infof("-- Saving model: %s" , client);
        var entity = clientMapper.modelToEntity(client);
        LOGGER.infof("** Saving entity: %s" , entity);
        clientEntityRepository.persist(entity);
        return clientMapper.entityToModel(entity);
    }

    @Override
    public List<Client> findAll() {
        return clientEntityRepository.streamAll()
//            .peek(entity -> LOGGER.infof("found: %s",entity))
            .map(clientMapper::entityToModel)
            .toList();
    }

    @Override
    public Optional<Client> findById(Integer id) {
        return clientEntityRepository.findByIdOptional(id)

            .map(clientMapper::entityToModel);
    }
}
