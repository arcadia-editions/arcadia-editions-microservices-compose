#!/usr/bin/env bash
# Builds the Docker image of every sibling microservice with `mvn spring-boot:build-image`.
# Image names: <artifactId>:0.0.1-SNAPSHOT (Spring Boot default), as used by docker-compose.yml.
# Usage: ./build-images.sh [service ...]   (default: all)
set -euo pipefail

PARENT=$(cd "$(dirname "$0")/.." && pwd)
SERVICES=("$@")
if [ ${#SERVICES[@]} -eq 0 ]; then
  SERVICES=(
    orders-checkout-service-java
    catalog-inventory-service-java
    payments-processing-service-java
    fulfillment-shipping-service-java
    notifications-consumer-service-java
  )
fi

for svc in "${SERVICES[@]}"; do
  echo "== $svc"
  (cd "$PARENT/$svc" && mvn -q -DskipTests spring-boot:build-image)
done
