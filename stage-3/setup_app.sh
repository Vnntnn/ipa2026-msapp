#!/bin/bash

current_dir=$(pwd)

# Reset
rm -rf "$current_dir/tempdir"
pip3 freeze > "$current_dir/requirements.txt"
docker compose down -v 2>/dev/null || true

mkdir -p "$current_dir/tempdir/templates"
mkdir -p "$current_dir/tempdir/static"

cp "$current_dir/.env" "$current_dir/tempdir/" 2>/dev/null || true
cp "$current_dir/app.py" "$current_dir/tempdir/"
cp "$current_dir/requirements.txt" "$current_dir/tempdir/"
cp -r "$current_dir/templates"/* "$current_dir/tempdir/templates/" 2>/dev/null || true
cp -r "$current_dir/static"/* "$current_dir/tempdir/static/" 2>/dev/null || true

cat << 'EOF' > "$current_dir/tempdir/Dockerfile"
FROM python
WORKDIR /home/myapp
COPY ./requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY ./static ./static
COPY ./templates ./templates
COPY ./app.py .
EXPOSE 8080
CMD ["python3", "app.py"]
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
      DB_NAME: "ipa2026_db"

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

volumes:
  mongo-data:

networks:
  app-net:
EOF

cd "$current_dir/tempdir"
docker compose up --build --detach 

echo "============= | Container Status | ============="
docker ps -a
echo "================================================"
