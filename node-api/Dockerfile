FROM node:16-bullseye

COPY . /app
WORKDIR /app/

RUN apt-get update -y && \
    apt-get install -y git

RUN npm install
RUN npm run build
RUN yarn global add serve

EXPOSE 3000
ENTRYPOINT ["serve", "-s", "build"]
