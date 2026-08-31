#!/bin/bash

current_dir=$(pwd)

# Reset
rm -rf "$current_dir/tempdir"
pip3 freeze > "$current_dir/requirements.txt"
docker rm -f web mongo 2>/dev/null || true
docker network rm app-net 2>/dev/null || true

mkdir -p "$current_dir/tempdir/templates"
mkdir -p "$current_dir/tempdir/static"

cp "$current_dir/app.py" "$current_dir/tempdir/"
cp "$current_dir/requirements.txt" "$current_dir/tempdir/"
cp -r "$current_dir/templates"/* "$current_dir/tempdir/templates/" 2>/dev/null || true
cp -r "$current_dir/static"/* "$current_dir/tempdir/static/" 2>/dev/null || true

echo "FROM python:3.10-slim" > "$current_dir/tempdir/Dockerfile"
echo "WORKDIR /home/myapp" >> "$current_dir/tempdir/Dockerfile"
echo "COPY ./requirements.txt ." >> "$current_dir/tempdir/Dockerfile"
echo "RUN pip install --no-cache-dir -r requirements.txt" >> "$current_dir/tempdir/Dockerfile"
echo "COPY ./static ./static" >> "$current_dir/tempdir/Dockerfile"
echo "COPY ./templates ./templates" >> "$current_dir/tempdir/Dockerfile"
echo "COPY ./app.py ." >> "$current_dir/tempdir/Dockerfile"
echo "EXPOSE 8080" >> "$current_dir/tempdir/Dockerfile"
echo "CMD python3 /home/myapp/app.py" >> "$current_dir/tempdir/Dockerfile"

cd "$current_dir/tempdir"

docker network create app-net
docker run -d -p 27017:27017 --network app-net -v mongo-data:/data/db --name mongo mongo:6
docker build -t web .
docker run -d -p 8080:8080 --network app-net --name web web

echo "============= | Container Status | ============="
docker ps -a
echo "================================================"
