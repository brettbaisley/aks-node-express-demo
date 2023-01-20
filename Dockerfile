FROM node:19-slim

ENV NODE_ENV=production

WORKDIR /app

COPY "package.json" .

RUN npm install --production

COPY . .

CMD [ "node", "server.js" ]