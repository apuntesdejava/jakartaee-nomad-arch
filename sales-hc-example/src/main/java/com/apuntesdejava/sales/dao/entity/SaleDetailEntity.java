package com.apuntesdejava.sales.dao.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import lombok.EqualsAndHashCode;
import lombok.Getter;
import lombok.Setter;

@Entity
@Table(name = "sale_detail")
@Getter
@Setter
@EqualsAndHashCode(of = "id")
public class SaleDetailEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;

    @Column(name = "product_id")
    private Integer productId;

    @ManyToOne
    @JoinColumn(name = "sale_id")
    private SaleEntity sale;

    @Column(name = "total_price")
    private double totalPrice;

    @Column(name = "count")
    private double count;

}
