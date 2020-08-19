# node:8-buster with meteor installed
FROM gcr.io/stardust-156404/meteor-buildenv:node-12 AS build

# grab build dependencies
WORKDIR /src
ADD package*.json ./
RUN npm ci

# compile app into a temp directory
ADD . ./
RUN mkdir /app \
 && meteor build \
    --allow-superuser \
    --directory "/app"

# build native stuff under musl
FROM node:12-alpine AS install
RUN apk add --no-cache build-base python

# install fibers, node-sass, etc under musl
# meteor doesn't include the original package.json sadly
COPY --from=build /app/bundle/programs/server/npm /opt/server/npm
RUN cd /opt/server/npm \
 && npm rebuild

# make lean app container
FROM node:12-alpine
COPY --from=build /app/bundle /app
COPY --from=install /opt/server/npm /app/programs/server/npm
WORKDIR /app
CMD [ "node", "main.js" ]
