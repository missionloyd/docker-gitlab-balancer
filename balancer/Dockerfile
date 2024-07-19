FROM nginx:latest

RUN apt-get update && apt-get install -y certbot python3-certbot-nginx

RUN rm /etc/nginx/nginx.conf
COPY nginx.conf /etc/nginx/
RUN rm /etc/nginx/conf.d/default.conf
COPY project.conf /etc/nginx/conf.d/

COPY entrypoint.sh /entrypoint.sh

# Expose HTTP and HTTPS ports
EXPOSE 80 443

# Make scripts executable
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
