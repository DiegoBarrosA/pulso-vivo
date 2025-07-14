-- Sample data for testing the inventory service
INSERT INTO product (name, description, quantity, category, active, price, last_price_update, previous_price, version) VALUES 
('Laptop Dell XPS 13', 'High-performance ultrabook with 13-inch display', 25, 'Electronics', 1, 1299.99, SYSTIMESTAMP, 1199.99, 0);

INSERT INTO product (name, description, quantity, category, active, price, last_price_update, previous_price, version) VALUES 
('iPhone 15', 'Latest Apple smartphone with advanced features', 50, 'Electronics', 1, 999.99, SYSTIMESTAMP, 899.99, 0);

INSERT INTO product (name, description, quantity, category, active, price, last_price_update, previous_price, version) VALUES 
('Samsung Galaxy S24', 'Premium Android smartphone', 30, 'Electronics', 1, 899.99, SYSTIMESTAMP, 799.99, 0);

INSERT INTO product (name, description, quantity, category, active, price, last_price_update, previous_price, version) VALUES 
('Office Chair', 'Ergonomic office chair with lumbar support', 15, 'Furniture', 1, 299.99, SYSTIMESTAMP, 249.99, 0);

INSERT INTO product (name, description, quantity, category, active, price, last_price_update, previous_price, version) VALUES 
('Standing Desk', 'Height-adjustable standing desk', 8, 'Furniture', 1, 499.99, SYSTIMESTAMP, 459.99, 0);

INSERT INTO product (name, description, quantity, category, active, price, last_price_update, previous_price, version) VALUES 
('Wireless Mouse', 'Bluetooth wireless mouse', 100, 'Accessories', 1, 49.99, SYSTIMESTAMP, 39.99, 0);

INSERT INTO product (name, description, quantity, category, active, price, last_price_update, previous_price, version) VALUES 
('Mechanical Keyboard', 'RGB backlit mechanical keyboard', 45, 'Accessories', 1, 129.99, SYSTIMESTAMP, 119.99, 0);

INSERT INTO product (name, description, quantity, category, active, price, last_price_update, previous_price, version) VALUES 
('Monitor 27 inch', '4K UHD monitor 27 inch', 20, 'Electronics', 1, 399.99, SYSTIMESTAMP, 379.99, 0);

INSERT INTO product (name, description, quantity, category, active, price, last_price_update, previous_price, version) VALUES 
('Headphones', 'Noise-cancelling wireless headphones', 35, 'Accessories', 1, 199.99, SYSTIMESTAMP, 189.99, 0);

INSERT INTO product (name, description, quantity, category, active, price, last_price_update, previous_price, version) VALUES 
('Tablet Pro', 'Professional tablet for creative work', 12, 'Electronics', 1, 699.99, SYSTIMESTAMP, 649.99, 0);

-- Low stock items for testing low-stock endpoint
INSERT INTO product (name, description, quantity, category, active, price, last_price_update, previous_price, version) VALUES 
('Printer Ink', 'Black ink cartridge', 5, 'Office Supplies', 1, 29.99, SYSTIMESTAMP, NULL, 0);

INSERT INTO product (name, description, quantity, category, active, price, last_price_update, previous_price, version) VALUES 
('USB Cable', 'USB-C charging cable', 3, 'Accessories', 1, 19.99, SYSTIMESTAMP, NULL, 0);
