FROM nginx:latest

# Install necessary packages
RUN apt-get update && apt-get install -y certbot python3-certbot-nginx dnsutils

# Remove default nginx configuration files
RUN rm /etc/nginx/nginx.conf
RUN mv /etc/nginx/conf.d/default.conf /etc/nginx/conf.d/project.conf

# Copy your custom nginx main and site configuration files
COPY nginx.conf /etc/nginx/

# Copy the SSL & proxy parameter configuration
COPY ssl-params.conf /etc/nginx/snippets/
COPY proxy-params.conf /etc/nginx/snippets/

# Copy entrypoint script
COPY entrypoint.sh /entrypoint.sh

# Expose HTTP and HTTPS ports
EXPOSE 80 443

# Make scripts executable
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
