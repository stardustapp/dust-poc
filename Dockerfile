# node:8-buster with meteor installed
FROM gcr.io/stardust-156404/meteor-buildenv AS build

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
FROM mhart/alpine-node:8 AS install
RUN apk add --no-cache build-base python

# rebuild sass under musl
COPY --from=build /app/bundle/programs/server/npm/node_modules/meteor/barbatus_scss-compiler/node_modules /opt/scss/node_modules
RUN cd /opt/scss/node_modules \
 && npm rebuild node-sass

# install fibers, etc under musl
COPY --from=build /app/bundle/programs/server/package.json /opt/server/
RUN cd /opt/server \
 && npm install --production

# make lean app container
FROM mhart/alpine-node:8
COPY --from=build /app/bundle /app
COPY --from=install /opt/server/node_modules /app/programs/server/node_modules
COPY --from=install /opt/scss/node_modules/node-sass /app/programs/server/npm/node_modules/meteor/barbatus_scss-compiler/node_modules/node-sass
WORKDIR /app
CMD [ "node", "main.js" ]
