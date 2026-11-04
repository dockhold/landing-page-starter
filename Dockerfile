# Dockhold builds this image and runs it as a non-root user (uid 1001).
# A plain HTML site has no build step, so this just adds a small static server.
FROM node:22-alpine

RUN npm install -g serve@14 && npm cache clean --force

WORKDIR /site
COPY . .

# Shell form so $PORT expands at runtime. serve binds 0.0.0.0 by default.
CMD serve -l $PORT .
