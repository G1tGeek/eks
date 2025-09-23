FROM node:16-bullseye

WORKDIR /app

# Copy package files first
COPY package.json ./

# Install dependencies ignoring peer conflicts
RUN npm install --legacy-peer-deps

# Copy the rest of the app
COPY . .

# Build React app
RUN npm run build

# Install serve globally
RUN yarn global add serve

EXPOSE 3000
ENTRYPOINT ["serve", "-s", "build"]
