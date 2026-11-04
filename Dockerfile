# Dockhold builds this image and runs it as a non-root user (uid 1001).
# A plain HTML site has no build step, so this just adds a small static server.
FROM node:22-alpine

RUN npm install -g serve@14 && npm cache clean --force

# serve looks for a newer version of itself each time it starts. A landing
# page has no use for that, so it starts without reaching out anywhere.
ENV NO_UPDATE_CHECK=1

WORKDIR /site
COPY . .

# Shell form so $PORT expands at runtime. serve binds 0.0.0.0 by default.
CMD serve -l $PORT .
