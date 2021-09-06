FROM node:current-alpine as builder
RUN apk add -U build-base python3 python2
WORKDIR /usr/src/app
COPY wetty /usr/src/app
RUN yarn && \
    yarn build && \
    yarn install --production --ignore-scripts --prefer-offline

FROM node:current-alpine
LABEL maintainer="firstlife22@gmail.com"
WORKDIR /usr/src/app
ENV NODE_ENV=production
EXPOSE 3000
COPY --from=builder /usr/src/app/build /usr/src/app/build
COPY --from=builder /usr/src/app/node_modules /usr/src/app/node_modules
COPY wetty/package.json /usr/src/app

COPY entrypoint.sh /entrypoint.sh

RUN apk update && \
    apk add --no-cache \
        coreutils \
        openssh-client \
        sshpass \
        curl \
        openssl && \
    rm -rf /var/cache/apk/* && \
    mkdir /home/node/.ssh && \
    chown node:node /home/node/.ssh && \
    chmod +x /entrypoint.sh && \
    chown root:root -R /usr/src/app && \
    chmod u=rwX,og=rX -R /usr/src/app

# setup healthcheck
HEALTHCHECK --interval=15s --timeout=20s \
  CMD curl -sS --fail --insecure https://localhost:3000${BASEURL} || exit 1

VOLUME /home/node

USER node

ENTRYPOINT [ "/entrypoint.sh" ]
