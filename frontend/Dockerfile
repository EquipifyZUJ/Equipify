FROM node:20-alpine AS build
WORKDIR /app

COPY equipify-app/package.json equipify-app/package-lock.json* ./
RUN npm install

COPY equipify-app/ .
ENV VITE_API_URL=/api
RUN npm run build

# ── Nginx runtime ──
FROM nginx:alpine
COPY --from=build /app/dist /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
