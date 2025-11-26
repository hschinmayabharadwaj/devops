# Docker Deployment Guide

## Build and Run with Docker

### Option 1: Using Docker directly

1. **Build the Docker image:**
   ```bash
   docker build -t drumkit-app .
   ```

2. **Run the container:**
   ```bash
   docker run -d -p 8080:80 --name drumkit drumkit-app
   ```

3. **Access the application:**
   Open your browser and navigate to: `http://localhost:8080`

4. **Stop the container:**
   ```bash
   docker stop drumkit
   ```

5. **Remove the container:**
   ```bash
   docker rm drumkit
   ```

### Option 2: Using Docker Compose

1. **Build and start the application:**
   ```bash
   docker-compose up -d
   ```

2. **Access the application:**
   Open your browser and navigate to: `http://localhost:8080`

3. **View logs:**
   ```bash
   docker-compose logs -f
   ```

4. **Stop the application:**
   ```bash
   docker-compose down
   ```

## Useful Docker Commands

- **View running containers:**
  ```bash
  docker ps
  ```

- **View all containers:**
  ```bash
  docker ps -a
  ```

- **View images:**
  ```bash
  docker images
  ```

- **Remove image:**
  ```bash
  docker rmi drumkit-app
  ```
