#!/bin/bash

current_dir=$(pwd)
echo "Current working directory: $current_dir"

# Reset
rm -rf "$current_dir/tempdir"
docker compose down -v 2>/dev/null || true

mkdir -p "$current_dir/tempdir/templates"
mkdir -p "$current_dir/tempdir/static"
mkdir -p "$current_dir/tempdir/scheduler"
mkdir -p "$current_dir/tempdir/worker"

cp "$current_dir/.env" "$current_dir/tempdir/" 2>/dev/null || true
cp "$current_dir/app.py" "$current_dir/tempdir/" 2>/dev/null || true
cp "$current_dir/requirements.txt" "$current_dir/tempdir/" 2>/dev/null || true

cp "$current_dir/requirements.txt" "$current_dir/tempdir/scheduler/" 2>/dev/null || true
cp "$current_dir/scheduler/"*.py "$current_dir/tempdir/scheduler/" 2>/dev/null || true
cp "$current_dir/worker/"*.py "$current_dir/tempdir/worker/" 2>/dev/null || true
cp -r "$current_dir/templates"/* "$current_dir/tempdir/templates/" 2>/dev/null || true
cp -r "$current_dir/static"/* "$current_dir/tempdir/static/" 2>/dev/null || true

cat << 'EOF' > "$current_dir/tempdir/Dockerfile"
FROM python
WORKDIR /home/myapp
COPY ./requirements.txt .
COPY ./static ./static
COPY ./templates ./templates
COPY ./app.py .
RUN sed -i '/apturl/d' requirements.txt && \
    pip install --no-cache-dir -r requirements.txt
EXPOSE 8080
CMD ["python3", "app.py"]
EOF

cat << 'EOF' > "$current_dir/tempdir/scheduler/Dockerfile"
FROM python
WORKDIR /home/scheduler
COPY ./requirements.txt .
COPY ./*.py .
RUN sed -i '/apturl/d' requirements.txt && \
    pip install --no-cache-dir -r requirements.txt
EXPOSE 2973
CMD ["python3", "scheduler.py"]
EOF

cat << 'EOF' > "$current_dir/tempdir/worker/Dockerfile"
FROM python
WORKDIR /home/worker
COPY ./*.py .
RUN pip install --no-cache-dir pika pymongo "paramiko<4" netmiko ntc-templates
CMD ["python3", "consumer.py"]
EOF

cat << 'EOF' > "$current_dir/tempdir/docker-compose.yml"
services:
  web:
    build: .
    ports:
      - "8080:8080"
    depends_on:
      - mongo
    networks:
      - app-net
    env_file:
      - .env
    environment:
      MONGO_URI: "mongodb://${MONGO_INITDB_ROOT_USERNAME}:${MONGO_INITDB_ROOT_PASSWORD}@mongo:27017/"
      DB_NAME: "${DB_NAME}"

  mongo:
    image: mongo:6
    ports:
      - "27017:27017"
    volumes:
      - mongo-data:/data/db
    networks:
      - app-net
    env_file:
      - .env

  rabbitmq:
    image: rabbitmq:3-management
    ports:
      - "5672:5672" # AMQP Protocol port
      - "15672:15672" # Web Management UI
    networks:
      - app-net
    env_file:
      - .env
    environment:
      RABBITMQ_DEFAULT_USER: ${RABBITMQ_DEFAULT_USER}
      RABBITMQ_DEFAULT_PASS: ${RABBITMQ_DEFAULT_PASS}
    volumes:
      - rabbitmq_data:/data/rabbitmq

  scheduler:
    build: ./scheduler/
    ports:
      - 2973:2973
    networks:
      - app-net
    depends_on:
      - mongo
      - rabbitmq
    env_file:
      - .env
    environment:
      MONGO_URI: "mongodb://${MONGO_INITDB_ROOT_USERNAME}:${MONGO_INITDB_ROOT_PASSWORD}@mongo:27017/"
      DB_NAME: "${DB_NAME}"
      COLLECTIONS_NAME: "${COLLECTIONS_NAME}"
      RABBITMQ_DEFAULT_USER: ${RABBITMQ_DEFAULT_USER}
      RABBITMQ_DEFAULT_PASS: ${RABBITMQ_DEFAULT_PASS}
      RABBITMQ_ROUTER_QUEUE_JOBS: ${RABBITMQ_ROUTER_QUEUE_JOBS}
      RABBITMQ_ROUTER_EXCHANGE: ${RABBITMQ_ROUTER_EXCHANGE}
      RABBITMQ_ROUTER_ROUTING_KEY: ${RABBITMQ_ROUTER_ROUTING_KEY}
      PRODUCER_HOST: ${PRODUCER_HOST}

  worker:
    build: ./worker/
    networks:
      - app-net
    depends_on:
      - rabbitmq
      - mongo
    env_file:
      - .env
    environment:
      MONGO_URI: "mongodb://${MONGO_INITDB_ROOT_USERNAME}:${MONGO_INITDB_ROOT_PASSWORD}@mongo:27017/"
      DB_NAME: "${DB_NAME}"
      RABBITMQ_HOST: ${PRODUCER_HOST}
      RABBITMQ_DEFAULT_USER: ${RABBITMQ_DEFAULT_USER}
      RABBITMQ_DEFAULT_PASS: ${RABBITMQ_DEFAULT_PASS}


volumes:
  mongo-data:
  rabbitmq_data:

networks:
  app-net:
EOF

cd "$current_dir/tempdir"
# docker compose up --build --detach 
# Make 3 workers containers to scaling workload.
docker compose up --build -d --scale worker=3

echo "============= | Container Status | ============="
docker ps -a
echo "================================================"
