package com.apuntesdejava.sales.services;

import com.apuntesdejava.sales.domain.model.Sale;
import com.apuntesdejava.sales.domain.model.SaleDetail;
import com.apuntesdejava.sales.domain.repository.SaleDetailRepository;
import com.apuntesdejava.sales.domain.repository.SaleRepository;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import lombok.extern.java.Log;
import org.eclipse.microprofile.rest.client.inject.RestClient;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Set;
import java.util.logging.Level;

@ApplicationScoped
@Log
public class SaleService {

    @Inject
    private SaleRepository saleRepository;

    @Inject
    private SaleDetailRepository saleDetailRepository;

    @Inject
    @RestClient
    private ProductService productService;

    @Inject
    @RestClient
    private ClientService clientService;

    public void sale(Sale sale) {
        log.log(Level.INFO, "clientId:{0}", sale.clientId());
        clientService.findById(sale.clientId()); // verify client exists

        var saleModel = new Sale(0, LocalDateTime.now(),
            sale.clientId(), sale.totalPrice(), Set.of());

        var saleSaved = saleRepository.save(saleModel);
        log.log(Level.INFO, "sale saved:{0}", saleSaved);

        var details = sale.details()
            .stream()
            .map(saleDetail -> {
                var product = productService.findById(saleDetail.productId());
                return new SaleDetail(product.id(),
                    saleDetail.count(),
                    product.price() * saleDetail.count(),
                    saleSaved);
            }).toList();
        saleDetailRepository.saveAll(details);

        var saleTotal = details.stream()
            .mapToDouble(SaleDetail::totalPrice)
            .sum();
        saleRepository.updateSalePrice(saleSaved.id(), saleTotal);

    }

    public List<Sale> findAll() {
        return saleRepository.findAll();
    }
}
