CREATE TABLE IF NOT EXISTS sale (
    id INT AUTO_INCREMENT PRIMARY KEY,
    sale_date DATETIME,
    client_id int,
    total_price decimal(10,2)
);

CREATE TABLE IF NOT EXISTS sale_detail
(
    id          INT AUTO_INCREMENT PRIMARY KEY,
    sale_id     INT NOT NULL,
    product_id  int not null,
    count       decimal(10, 2),
    total_price decimal(10, 2) 
);