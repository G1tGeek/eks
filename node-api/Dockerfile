# Use official Node.js LTS image
FROM node:18

# Set working directory
WORKDIR /app

# Copy package.json and package-lock.json
COPY package*.json ./

# Install npm dependencies (ignoring peer dependency conflicts)
RUN npm install --legacy-peer-deps

# Copy the rest of the application
COPY . .

# Expose the application port
EXPOSE 3000

# Default command to start the application
CMD ["npm", "start"]
