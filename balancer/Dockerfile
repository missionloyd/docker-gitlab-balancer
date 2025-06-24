FROM nginx:latest

# Install packages for DNS lookup, time zone configuration, JSON parsing
RUN apt-get update && apt-get install -y dnsutils tzdata jq

# Set timezone
ARG BALANCER_TIMEZONE
ENV TZ=${BALANCER_TIMEZONE}

# Remove default Nginx config files
RUN rm /etc/nginx/nginx.conf
RUN mv /etc/nginx/conf.d/default.conf /etc/nginx/conf.d/project.conf

# Copy custom Nginx configuration
COPY nginx.conf /etc/nginx/
COPY ssl-params.conf /etc/nginx/snippets/
COPY proxy-params.conf /etc/nginx/snippets/

# Create directory for stream configs
RUN mkdir -p /etc/nginx/conf.stream.d

# Copy additional modules
COPY modules /etc/nginx/modules/

# Copy entrypoint script and set permissions
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh /etc/nginx/modules/*.sh

# Expose HTTP and HTTPS
EXPOSE 80 443

ENTRYPOINT ["/entrypoint.sh"]
