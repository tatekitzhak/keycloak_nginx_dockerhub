FROM quay.io/keycloak/keycloak:20.0.0
# Pre-build Keycloak for faster startup
RUN /opt/keycloak/bin/kc.sh build
ENTRYPOINT ["/opt/keycloak/bin/kc.sh"]