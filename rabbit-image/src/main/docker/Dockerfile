################
# Docker file to build a RabbitMQ image for use in a Kubernetes StatefulSet
################
FROM rabbitmq:3.6.9-alpine

#Send logs to STDOUT
# Use FQDN as host name
# Define default mnesia directory
ENV RABBITMQ_LOGS="-" \
    RABBITMQ_SASL_LOGS="-" \
    RABBITMQ_USE_LONGNAME="true" \
    AUTOCLUSTER_CLEANUP=true \
    CLEANUP_INTERVAL=60

#Add auto-cluster plugin
COPY autocluster-1e7f9710e8802ef51d23692c344f64b051a8c331.tgz /autocluster-plugin.tgz
RUN tar -xzf /autocluster-plugin.tgz \
 && rabbitmq-plugins enable autocluster rabbitmq_management --offline

COPY run.sh /run.sh
COPY live_check.sh /live_check.sh
COPY shutdown.sh /shutdown.sh
COPY rabbitmq.config /etc/rabbitmq/rabbitmq.config
COPY rabbitmq_definitions.json /etc/rabbitmq/rabbitmq_definitions.json

CMD ["/run.sh"]
