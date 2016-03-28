#!/bin/bash

set -ex

# Required vars
export ELASTICSEARCH_SERVICE=${ELASTICSEARCH_SERVICE:-transport_port.elasticsearch-executor}
export ELASTICSEARCH_CLUSTER_NAME=${ELASTICSEARCH_CLUSTER_NAME:-mantl}

CONSUL_TEMPLATE=${CONSUL_TEMPLATE:-/usr/local/bin/consul-template}
CONSUL_CONFIG=${CONSUL_CONFIG:-/consul-template/config.d}
CONSUL_CONNECT=${CONSUL_CONNECT:-consul.service.consul:8500}
CONSUL_MINWAIT=${CONSUL_MINWAIT:-30s}
CONSUL_MAXWAIT=${CONSUL_MAXWAIT:-60s}
CONSUL_LOGLEVEL=${CONSUL_LOGLEVEL:-warn}
CONSUL_SSL_VERIFY=${CONSUL_SSL_VERIFY:-true}

# we need the host ip to set the publish address
export PUBLISH_HOST=$(getent hosts $HOST | awk '{ print $1 ; exit }')

[[ -n "${CONSUL_CONNECT}" ]] && ctargs="${ctargs} -consul ${CONSUL_CONNECT}"
[[ -n "${CONSUL_SSL}" ]] && ctargs="${ctargs} -ssl"
[[ -n "${CONSUL_SSL}" ]] && ctargs="${ctargs} -ssl-verify=${CONSUL_SSL_VERIFY}"
[[ -n "${CONSUL_TOKEN}" ]] && ctargs="${ctargs} -token ${CONSUL_TOKEN}"

wait_for_service() {
    ${CONSUL_TEMPLATE} -config ${CONSUL_CONFIG} \
                       -log-level ${CONSUL_LOGLEVEL} \
                       -wait ${CONSUL_MINWAIT}:${CONSUL_MAXWAIT} \
                       -once \
                       ${ctargs}

    # make sure we found an elasticsearch service to connect to
    grep discovery.zen.ping.unicast.hosts \
         /usr/share/elasticsearch/config/elasticsearch.yml 1>/dev/null
}

ATTEMPT=0
until wait_for_service || [ $ATTEMPT -eq 5 ]; do
    echo "waiting for $ELASTICSEARCH_SERVICE service..."
    echo "attempt: $(( ATTEMPT++ ))"
    sleep 30
done

if [[ $ATTEMPT -eq 5 ]]; then
    echo "$ELASTICSEARCH_SERVICE not found."
    exit 1
fi

( exec /docker-entrypoint.sh $@ )
