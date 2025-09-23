# Use Amazon Linux 2 as base image
FROM amazonlinux:2

# Install dependencies
RUN yum update -y && \
    yum install -y git curl gcc-c++ make python3 tar gzip bzip2 xz sudo && \
    yum clean all

# Install Node.js 16.x
RUN curl -fsSL https://rpm.nodesource.com/setup_16.x | bash - && \
    yum install -y nodejs && \
    npm install -g yarn && \
    node -v && npm -v && yarn -v

# Set working directory
WORKDIR /app

# Copy application files
COPY . .

# Install dependencies & build
RUN npm install
RUN npm run build

# Install serve globally
RUN yarn global add serve

# Expose port
EXPOSE 3000

# Start app
ENTRYPOINT ["serve", "-s", "build"]
