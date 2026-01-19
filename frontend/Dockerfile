FROM nginx:alpine

# Copy frontend static files
COPY frontend/ /usr/share/nginx/html/

# Remove default nginx config (we'll use custom one via docker-compose)
RUN rm /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
