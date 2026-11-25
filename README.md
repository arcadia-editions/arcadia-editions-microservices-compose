# Arcadia Editions - Microservices Compose

Runs the five Arcadia Editions microservices of the
[Place Order flow](https://github.com/arcadia-editions/arcadia-editions-architecture/blob/main/business-flows/place-order-flow.zfl)
together with their infrastructure (PostgreSQL, Kafka, Schema Registry) using docker-compose.

## Quick start

```bash
git clone https://github.com/arcadia-editions/arcadia-editions-microservices-compose.git
cd arcadia-editions-microservices-compose
./checkout.sh            # clones every service next to this repo (or pulls if already there); ./checkout.sh <branch>
./build-images.sh        # mvn -DskipTests spring-boot:build-image in each one; ./build-images.sh <service> for one
docker compose up -d
```

Layout after `./checkout.sh` (sibling folders):

```
<parent>/
  arcadia-editions-microservices-compose/   (this repo)
  orders-checkout-service-java/
  catalog-inventory-service-java/
  payments-processing-service-java/
  fulfillment-shipping-service-java/
  notifications-consumer-service-java/
```

Requirements: Git Bash, Java 25, Maven, Docker. `ARCADIA_GIT_BASE` overrides the GitHub organization URL used by
`checkout.sh`.

## Ports

| Service | Repository | HTTP port | Swagger UI | Database |
|---|---|---|---|---|
| Orders Checkout | [orders-checkout-service-java](https://github.com/arcadia-editions/orders-checkout-service-java) | **8101** | http://localhost:8101/swagger-ui/index.html | `orders_checkout` |
| Catalog Inventory | [catalog-inventory-service-java](https://github.com/arcadia-editions/catalog-inventory-service-java) | **8102** | http://localhost:8102/swagger-ui/index.html | `catalog_inventory` |
| Payments Processing | [payments-processing-service-java](https://github.com/arcadia-editions/payments-processing-service-java) | **8103** | http://localhost:8103/swagger-ui/index.html | `payments_processing` |
| Fulfillment Shipping | [fulfillment-shipping-service-java](https://github.com/arcadia-editions/fulfillment-shipping-service-java) | **8104** | http://localhost:8104/swagger-ui/index.html | `fulfillment_shipping` |
| Notifications Consumer | [notifications-consumer-service-java](https://github.com/arcadia-editions/notifications-consumer-service-java) | **8105** | http://localhost:8105/swagger-ui/index.html | `notifications_consumer` |

| Infrastructure | Port (host) | Port (inside compose) |
|---|---|---|
| PostgreSQL (shared, one database per service, `postgres` / `admin123`) | 5432 | `postgresql:5432` |
| Kafka | 9092 | `kafka:19093` |
| Schema Registry | 8081 | `schema-registry:8081` |
| Zookeeper | 2181 | `zookeeper:2181` |

Each service reads its port from `SERVER_PORT` (default in its `application.yml` is the port above), so running a
service from the IDE or with `mvn spring-boot:run` uses the same port as in docker-compose. HTTP basic auth:
`admin` / `password`.

## Synchronous calls between services

Most of the flow goes through Kafka events. These steps call another service over HTTP and wait for the result:

| Caller | Step (ZFL) | Calls | Property (caller) | Env var | docker-compose value | Local default |
|---|---|---|---|---|---|---|
| Orders Checkout | `startOrderCheckout`, `confirmOrder` | Catalog Inventory `reserveStock`, `confirmStockReservation` | `arcadia.clients.catalog-inventory.base-url` | `CATALOG_INVENTORY_URL` | `http://catalog-inventory-service:8102/api` | `http://localhost:8102/api` |
| Catalog Inventory | `expireReservation` | Payments Processing `getPaymentStatus` | `arcadia.clients.payments-processing.base-url` | `PAYMENTS_PROCESSING_URL` | `http://payments-processing-service:8103/api` | `http://localhost:8103/api` |

Credentials: `<CLIENT>_USERNAME` / `<CLIENT>_PASSWORD` (default `admin` / `password`). The HTTP clients themselves are
still to be built: see `docs/backlog/http-clients.md` in each caller.

## Configuration passed to every service

| Env var | Value |
|---|---|
| `DATASOURCE_URL` | `jdbc:postgresql://postgresql:5432/<database>` |
| `DATASOURCE_USERNAME` / `DATASOURCE_PASSWORD` | `postgres` / `admin123` |
| `KAFKA_BOOTSTRAP_SERVERS` | `kafka:19093` |
| `SPRING_KAFKA_PROPERTIES_SCHEMA_REGISTRY_URL` | `http://schema-registry:8081` |
| `SPRING_JPA_HIBERNATE_DDL_AUTO` | `update` (schema created on startup) |

The databases are created by `postgres/init-databases.sql` on the first start of the PostgreSQL volume. After adding
a database, recreate it: `docker compose down -v && docker compose up -d`.

## Useful commands

```bash
docker compose up -d postgresql kafka schema-registry   # infrastructure only, run services from the IDE
docker compose logs -f orders-checkout-service
docker compose down -v                                  # stop and drop data
```
