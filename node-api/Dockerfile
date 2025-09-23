FROM node:16.15.1

MAINTAINER Opstree Solutions

COPY . /app

WORKDIR /app/

# Use Debian archive mirrors to fix apt-get 404 errors
RUN sed -i 's|http://deb.debian.org/debian|http://archive.debian.org/debian|g' /etc/apt/sources.list && \
    sed -i 's|http://security.debian.org/debian-security|http://archive.debian.org/debian-security|g' /etc/apt/sources.list && \
    apt-get update -y && \
    apt-get install -y git && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

RUN npm install 

RUN npm run build

RUN yarn global add serve

EXPOSE 3000

ENTRYPOINT ["serve", "-s", "build"]
