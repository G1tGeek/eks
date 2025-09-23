# Use a maintained Node 16 image based on Debian Bullseye
FROM node:16-bullseye

# Set working directory
WORKDIR /app

# Copy package files first for caching
COPY package*.json ./

# Install system dependencies (git)
RUN apt-get update -y && \
    apt-get install -y git && \
    rm -rf /var/lib/apt/lists/*

# Install npm dependencies ignoring peer conflicts
RUN npm install --legacy-peer-deps

# Copy the rest of the app
COPY . .

# Build React app
RUN npm run build

# Install serve globally to serve the build
RUN yarn global add serve

# Expose port 3000
EXPOSE 3000

# Start the app
ENTRYPOINT ["serve", "-s", "build"]
