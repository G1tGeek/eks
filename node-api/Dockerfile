# Use Amazon Linux 2 with Node 16
FROM amazonlinux:2

# Set working directory
WORKDIR /app

# Install Node.js 16, npm, git, and curl
RUN curl -fsSL https://rpm.nodesource.com/setup_16.x | bash - && \
    yum install -y nodejs git tar gzip && \
    npm install -g npm@latest && \
    yum clean all

# Copy application code
COPY . .

# Install Node.js dependencies (resolve peer conflicts)
RUN npm install --legacy-peer-deps

# Build the application
RUN npm run build

# Install serve globally to serve the build folder
RUN npm install -g serve

# Expose port 3000
EXPOSE 3000

# Start the app
ENTRYPOINT ["serve", "-s", "build"]
