# Base image
FROM node:16.20.0-bullseye-slim

LABEL maintainer="Opstree Solutions"

# Set working directory
WORKDIR /app

# Copy package files first for caching
COPY package*.json ./

# Install npm dependencies
RUN npm install

# Copy the rest of the application
COPY . .

# Install git and make
RUN apt-get update -y && \
    apt-get install -y git make --no-install-recommends && \
    rm -rf /var/lib/apt/lists/*

# Build the app using Makefile
RUN make build

# Install serve globally
RUN npm install -g serve

# Expose port
EXPOSE 3000

# Start app
ENTRYPOINT ["serve", "-s", "build"]
