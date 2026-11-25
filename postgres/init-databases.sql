-- One database per microservice in the shared PostgreSQL.
CREATE DATABASE orders_checkout;
CREATE DATABASE catalog_inventory;
CREATE DATABASE payments_processing;
CREATE DATABASE fulfillment_shipping;
CREATE DATABASE notifications_consumer;
