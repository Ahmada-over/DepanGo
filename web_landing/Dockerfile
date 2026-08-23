FROM node:20-alpine AS build-stage
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
RUN npm run build

FROM nginx:stable-alpine AS production-stage
COPY --from=build-stage /app/dist /usr/share/nginx/html

# Cloud Run injecte la variable d'environnement PORT (8080 par défaut)
ENV PORT=8080
EXPOSE $PORT

# Remplacer le port 80 par défaut de Nginx par la variable PORT de Cloud Run
# et créer un fichier de config personnalisé simple et robuste
RUN rm /etc/nginx/conf.d/default.conf
RUN echo "server { \
    listen       \${PORT}; \
    server_name  localhost; \
    location / { \
        root   /usr/share/nginx/html; \
        index  index.html index.htm; \
        try_files \$uri \$uri/ /index.html; \
    } \
}" > /etc/nginx/conf.d/default.conf.template

CMD envsubst '\$PORT' < /etc/nginx/conf.d/default.conf.template > /etc/nginx/conf.d/default.conf && nginx -g 'daemon off;'
