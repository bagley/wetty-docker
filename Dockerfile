#FROM node:boron-alpine as builder
FROM node:lts-alpine as builder
RUN apk add -U build-base python
WORKDIR /usr/src/app
COPY wetty /usr/src/app
RUN yarn && \
    yarn build && \
    yarn install --production --ignore-scripts --prefer-offline


#FROM node:boron-alpine
FROM node:lts-alpine

LABEL maintainer="firstlife22@gmail.com"
ENV NODE_ENV=production

COPY --from=builder /usr/src/app/dist /usr/src/app/dist
COPY --from=builder /usr/src/app/node_modules /usr/src/app/node_modules
COPY wetty/package.json /usr/src/app
COPY wetty/index.js /usr/src/app

COPY entrypoint.sh /entrypoint.sh

RUN apk update && \
    apk add --no-cache \
        openssh-client \
        sshpass \
        curl \
        openssl && \
    rm -rf /var/cache/apk/* && \
    mkdir /home/node/.ssh && \
    chown node:node /home/node/.ssh && \
    chmod +x /entrypoint.sh

# setup healthcheck
HEALTHCHECK --interval=15s --timeout=20s \
  CMD curl -sS --fail --insecure https://localhost:3000${BASEURL} || exit 1

VOLUME /home/node

WORKDIR /usr/src/app
EXPOSE 3000

USER node

# ENTRYPOINT [ "node", "." ]
ENTRYPOINT [ "/entrypoint.sh" ]
