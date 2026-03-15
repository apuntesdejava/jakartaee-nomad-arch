CREATE TABLE IF NOT EXISTS product (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    price DECIMAL(10, 2)
);

INSERT INTO product (name, description, price) VALUES
('Laptop', 'High performance laptop', 1200.50),
('Mouse', 'Wireless mouse', 25.00);


--

CREATE TABLE IF NOT EXISTS client (
  id INT AUTO_INCREMENT PRIMARY KEY,
  first_name VARCHAR(100) NOT NULL,
  last_name VARCHAR(100) NOT NULL,
  email varchar(100)
);

insert into client (first_name, last_name, email) values
      ('Tomasina', 'Kerwood', 'tkerwood0@google.co.jp'),
      ('Lucho', 'Gunner', 'lgunner1@woothemes.com'),
      ('Erin', 'Sorby', 'esorby2@addthis.com'),
      ('Augustine', 'Fieldhouse', 'afieldhouse3@adobe.com'),
      ('Theo', 'Yurlov', 'tyurlov4@pinterest.com'),
      ('Birch', 'Wilkison', 'bwilkison5@goo.ne.jp'),
      ('Conroy', 'Van der Spohr', 'cvanderspohr6@sakura.ne.jp'),
      ('Roger', 'Gori', 'rgori7@virginia.edu'),
      ('Feodor', 'Mulliss', 'fmulliss8@nytimes.com'),
      ('Maren', 'Bunner', 'mbunner9@google.pl');

--

CREATE TABLE IF NOT EXISTS sale (
    id INT AUTO_INCREMENT PRIMARY KEY,
    sale_date DATETIME,
    client_id int,
    total_price decimal(10,2),
    constraint fk_client_id foreign key (client_id) references client(id)
);

CREATE TABLE IF NOT EXISTS sale_detail (
    id INT AUTO_INCREMENT PRIMARY KEY,
    sale_id INT NOT NULL,
    product_id int not null,
    count decimal(10,2),
    total_price decimal(10,2),
    constraint fk_sale_id foreign key (sale_id) references sale(id),
    constraint fk_product_id foreign key (product_id) references product(id)


);