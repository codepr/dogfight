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

start-server:
	$(DOCKER_COMPOSE) up -d

stop-server:
	$(DOCKER_COMPOSE) down

# Build the Zig client
build-client:
	cd $(CLIENT_DIR) && zig build

# Run the Zig client
run-client:
	cd $(CLIENT_DIR) && zig run main.zig

build-all: build-server build-client

run-all: run-server run-client

# Clean build artifacts (both client and server)
clean:
	cd $(CLIENT_DIR) && zig clean
	cd $(SERVER_DIR) && docker-compose down

# Start the client (if the server is already running)
start-client:
	cd $(CLIENT_DIR) && zig build run
