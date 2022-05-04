FROM quay.io/project-flotta/edgedevice:latest

COPY ca.pem /etc/pki/consumer/
COPY cert.pem /etc/pki/consumer/
COPY key.pem /etc/pki/consumer/

RUN echo 'ca-root = ["/etc/pki/consumer/ca.pem"]' >> /etc/yggdrasil/config.toml
RUN sudo systemctl enable podman
RUN sudo systemctl enable yggdrasild

ENV CLIENTID=device

ENTRYPOINT echo "client-id = \"$CLIENTID\"" >> /etc/yggdrasil/config.toml; /sbin/init
