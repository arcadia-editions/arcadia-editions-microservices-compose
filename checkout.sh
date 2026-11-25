#!/usr/bin/env bash
# Clones (or updates) every microservice next to this repository, as siblings:
#   <parent>/arcadia-editions-microservices-compose  (this repo)
#   <parent>/orders-checkout-service-java ...
# Usage: ./checkout.sh [branch]   (default: main)
set -euo pipefail

BRANCH=${1:-main}
ORG=${ARCADIA_GIT_BASE:-https://github.com/arcadia-editions}
PARENT=$(cd "$(dirname "$0")/.." && pwd)

REPOS=(
  orders-checkout-service-java
  catalog-inventory-service-java
  payments-processing-service-java
  fulfillment-shipping-service-java
  notifications-consumer-service-java
)

for repo in "${REPOS[@]}"; do
  dir="$PARENT/$repo"
  if [ -d "$dir/.git" ]; then
    echo "== $repo: pull ($BRANCH)"
    git -C "$dir" fetch -q origin
    git -C "$dir" checkout -q "$BRANCH"
    git -C "$dir" pull -q --ff-only origin "$BRANCH"
  else
    echo "== $repo: clone ($BRANCH)"
    git clone -q --branch "$BRANCH" "$ORG/$repo.git" "$dir"
  fi
done
