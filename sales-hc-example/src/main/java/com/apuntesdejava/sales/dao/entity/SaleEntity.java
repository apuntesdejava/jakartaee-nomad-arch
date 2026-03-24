package com.apuntesdejava.sales.dao.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.OneToMany;
import jakarta.persistence.Table;
import lombok.EqualsAndHashCode;
import lombok.Getter;
import lombok.Setter;

import java.time.LocalDateTime;
import java.util.Set;

@Entity
@Table(name = "sale")
@Getter
@Setter
@EqualsAndHashCode(of = "id")
public class SaleEntity {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;

    @Column(name = "sale_date")
    private LocalDateTime saleDate;

    @Column(name = "client_id")
    private Integer clientId;

    @Column(name = "total_price")
    private Double totalPrice;

//    @OneToMany(mappedBy = "sale", cascade = jakarta.persistence.CascadeType.ALL, orphanRemoval = true)
    @OneToMany(mappedBy = "sale")
    private Set<SaleDetailEntity> details;
}
