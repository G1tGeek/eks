FROM node:16-bullseye

WORKDIR /app

# Copy package files first
COPY package.json package-lock.json* ./

# Clean install dependencies
RUN npm ci --legacy-peer-deps

# Copy rest of the app
COPY . .

# Build React app
RUN npm run build

# Install serve globally
RUN yarn global add serve

EXPOSE 3000
ENTRYPOINT ["serve", "-s", "build"]
