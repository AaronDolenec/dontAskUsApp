FROM nginx:alpine

# Remove default nginx website
RUN rm -rf /usr/share/nginx/html/*

# Add nginx config (path relative to repository root when build context is the repo)
COPY docker/nginx.conf /etc/nginx/conf.d/default.conf

# Copy built web assets into nginx html folder
COPY build/web/ /usr/share/nginx/html/

EXPOSE 80

CMD ["/usr/sbin/nginx","-g","daemon off;"]
