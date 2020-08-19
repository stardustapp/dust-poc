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

# rebuild fibers, node-sass, etc under musl
# meteor doesn't include the original package.json sadly
COPY --from=build /app/bundle/programs/server/npm /opt/server/npm
WORKDIR /opt/server/npm
RUN npm rebuild

# install extra packages that meteor didn't include the first time around
COPY --from=build /app/bundle/programs/server/package.json /opt/server/
COPY --from=build /app/bundle/programs/server/npm-shrinkwrap.json /opt/server/
WORKDIR /opt/server
RUN npm install --production

# clean up extra junk
RUN find . -type f \( \
    -name "*.md" -o \
    -name "*.markdown" -o \
    -name "*.ts" -o \
    -name "*.exe" \
    \) -delete
RUN find . -type d \( \
    -name "*-garbage-*" -o \
    -name ".temp-*" -o \
    -name "docs" -o \
    -name "examples" -o \
    -name "samples" -o \
    -name "babel-compiler" -o \
    -name "phantomjs-prebuilt" \
    \) -exec rm -rf {} +

# make lean app container
FROM node:12-alpine
COPY --from=build /app/bundle /app
COPY --from=install /opt/server/node_modules /app/programs/server/node_modules
COPY --from=install /opt/server/npm /app/programs/server/npm
WORKDIR /app
CMD [ "node", "main.js" ]
