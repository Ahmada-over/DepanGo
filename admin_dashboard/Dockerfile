# DepanGo Admin Dashboard on Google Cloud Run
FROM nginx:alpine

ENV PORT=8080

# Template automatically processed by envsubst on container startup
COPY default.conf.template /etc/nginx/templates/default.conf.template

# Static web files
COPY . /usr/share/nginx/html

EXPOSE 8080

CMD ["nginx", "-g", "daemon off;"]
