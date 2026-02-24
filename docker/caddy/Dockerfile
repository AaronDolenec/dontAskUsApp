FROM caddy:2-alpine

# Create app directory
RUN mkdir -p /srv/app
WORKDIR /srv/app

# Add Caddy config
COPY Caddyfile /etc/caddy/Caddyfile

# Add entrypoint that will generate runtime env file (env.json) from env vars
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 80

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
