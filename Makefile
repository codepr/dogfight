# Variables
DOCKER_COMPOSE = docker-compose -f ./server/docker-compose.yml
SERVER_DIR = ./server
CLIENT_DIR = ./client

# Targets

# Build the Elixir server (with Docker)
build-server:
	cd $(SERVER_DIR) && docker-compose build

# Run the Elixir server (with Docker)
run-server:
	cd $(SERVER_DIR) && docker-compose up

# Build the Zig client
build-client:
	cd $(CLIENT_DIR) && zig build

# Run the Zig client
run-client:
	cd $(CLIENT_DIR) && zig run main.zig

# Build both the server and client
build-all: build-server build-client

# Run both the server and client
run-all: run-server run-client

# Clean build artifacts (both client and server)
clean:
	cd $(CLIENT_DIR) && zig clean
	cd $(SERVER_DIR) && docker-compose down

# Stop the server (useful for stopping running containers)
stop-server:
	cd $(SERVER_DIR) && docker-compose down

# Start the client (if the server is already running)
start-client:
	cd $(CLIENT_DIR) && zig build run
