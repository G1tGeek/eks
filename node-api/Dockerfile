# Use Amazon Linux 2 as base image
FROM amazonlinux:2

# Install required dependencies
RUN yum update -y && \
    yum install -y \
      git \
      tar \
      gzip \
      curl \
      which \
      gzip \
      bzip2 \
      xz \
      sudo \
      make \
      gcc-c++ \
      python3 && \
    yum clean all

# Install Node.js (16.x) using NodeSource
RUN curl -fsSL https://rpm.nodesource.com/setup_16.x | bash - && \
    yum install -y nodejs && \
    npm install -g yarn && \
    node -v && npm -v && yarn -v

# Copy app files
COPY . /app
WORKDIR /app

# Install dependencies and build
RUN npm install
RUN npm run build

# Install 'serve' globally
RUN yarn global add serve

# Expose port
EXPOSE 3000

# Start the app
ENTRYPOINT ["serve", "-s", "build"]
