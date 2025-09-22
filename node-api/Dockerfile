FROM node:16.20.0-bullseye-slim

LABEL maintainer="Yuvraj"

WORKDIR /app

# Copy package files for caching
COPY package*.json ./

# Install dependencies
RUN npm install

# Copy everything
COPY . .

# Install git if needed
RUN apt-get update -y && apt-get install -y git --no-install-recommends \
    && rm -rf /var/lib/apt/lists/*

# Build app using Makefile
RUN make build

# Install serve globally
RUN npm install -g serve

EXPOSE 3000

ENTRYPOINT ["serve", "-s", "build"]
