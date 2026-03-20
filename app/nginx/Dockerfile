#FROM nginx:alpine3.23

#EXPOSE 80 443
#COPY certs/* /etc/nginx/ssl/localhost/
#COPY config/localhost.conf /etc/nginx/nginx.conf

FROM nginx:1.23.3-alpine

EXPOSE 80 8080

COPY config/localhost.conf /etc/nginx/nginx.conf

# COPY certs/* /etc/nginx/ssl/localhost/