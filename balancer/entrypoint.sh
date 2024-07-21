#!/bin/bash

# Declare an associative array
declare -A services

# Read key-value pairs from JSON and add to the associative array
while IFS="=" read -r key value; do
    services[$key]=$value
done < <(jq -r "to_entries | map(\"\(.key)=\(.value)\") | .[]" ${BALANCER_NGINX_SERVICES_FILE})

# To demonstrate, print the array elements
for key in "${!services[@]}"; do
    echo "$key -> ${services[$key]}"
done

# Load or source additional script modules
update_config() {
    source /etc/nginx/modules/initialize_project_conf.sh
    source /etc/nginx/modules/generate_certificate.sh
    source /etc/nginx/modules/generate_dh_params.sh
    source /etc/nginx/modules/create_nginx_server_block.sh
    source /etc/nginx/modules/generate_certificates_and_nginx_blocks.sh
    nginx -s reload
}

# Function to check DNS availability and use fallbacks
initialize_dns_check_with_fallback() {
    for service in "${!services[@]}"; do
        local hostname=$(echo "${services[$service]}" | cut -d: -f1)
        if ! host $hostname > /dev/null 2>&1; then
            echo "DNS resolution failed for $hostname, using fallback."
            services[$service]="gitlab-runner:404"  # Set fallback host and port
        fi
    done
}

# Update services, configure NGINX, and start NGINX
initialize_dns_check_with_fallback
update_config
nginx -g "daemon off;" &

# Initialize original settings in a separate array to ensure they are preserved
declare -A original_services
for key in "${!services[@]}"; do
    original_services[$key]=${services[$key]}
done

update_services_and_reload_nginx() {
    local changed=false
    for service in "${!services[@]}"; do
        local original_setting="${original_services[$service]}"
        local hostname=$(echo $original_setting | cut -d: -f1)

        if ! host $hostname > /dev/null 2>&1; then
            if [ "${services[$service]}" != "gitlab-runner:404" ]; then
                services[$service]="gitlab-runner:404"
                changed=true
            fi
        else
            if [ "${services[$service]}" != "$original_setting" ]; then
                services[$service]="$original_setting"
                changed=true
            fi
        fi
    done

    if [ "$changed" = true ]; then
        update_config
        nginx -s reload
        echo "*** Detected change in local DNS - config was updated ***"
    fi
}

# Periodically check service DNS and update NGINX config as needed
while true; do
    update_services_and_reload_nginx
    sleep ${BALANCER_SLEEP_BUFFER}
done
