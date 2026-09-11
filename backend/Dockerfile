FROM node:20-alpine

WORKDIR /app

# Dependencies install karna
COPY package*.json ./
RUN npm install --omit=dev

# Pura backend code copy karna
COPY . .

# Port expose karna
EXPOSE 8000

# Server start command
CMD ["node", "server.js"]