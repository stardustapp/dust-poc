# debian node:8 with meteor installed
FROM gcr.io/stardust-156404/meteor-buildenv AS build

# grap node dependencies
WORKDIR /src
ADD package*.json ./
RUN npm ci

# build into a temp directory
ADD . ./
RUN mkdir /app \
 && meteor build \
    --allow-superuser \
    --directory "/app"

# rebuild sass under musl
FROM mhart/alpine-node:8 AS rebuild
RUN apk add --no-cache build-base python
COPY --from=build /app/bundle/programs/server/npm/node_modules/meteor/barbatus_scss-compiler/node_modules /opt/node_modules
RUN cd /opt/node_modules \
 && npm rebuild node-sass

# make app container
FROM mhart/alpine-node:8
COPY --from=build /app/bundle /app
COPY --from=rebuild /opt/node_modules /app/bundle/programs/server/npm/node_modules/meteor/barbatus_scss-compiler/node_modules
WORKDIR /app
CMD [ "node", "main.js" ]
