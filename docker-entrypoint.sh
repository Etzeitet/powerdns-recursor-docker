#!/bin/bash
set -e

check_env() {
    if [[ -z ${DNS_AUTH_SERVICE} ]] && [[ -z ${DNS_AUTH_IP_ADDRESSES} ]]; then
        echo "One of DNS_AUTH_SERVICE or DNS_AUTH_IP_ADDRESSES environment variables must be set."
        exit 1
    fi

    if [[ -z ${DNS_FORWARDER_SERVICE} ]] && [[ -z ${DNS_FORWARDER_IP_ADDRESSES} ]]; then
        echo "One of DNS_FORWARDER_SERVICE or DNS_FORWARDER_IP_ADDRESSES environment variables must be set."
        exit 1
    fi

    if [[ -z ${DNS_AUTH_ZONES} ]]; then
        echo "DNS_AUTH_ZONES environment variable must be set."
        exit 1
    fi
}

get_ip_list_from_service() {
    SERVICE_NAME="${1}"
    SEPARATOR="${2:-;}"

    IP_LIST="$(getent ahostsv4 tasks."${SERVICE_NAME}"|awk '/STREAM/ {print $1}'|tr '\n' "${SEPARATOR}")"
    echo "${IP_LIST::-1}"
}

build_forwarder_config() {
    local ZONES_LIST="${1}"
    local FORWARDERS="${2}"

    IFS=", "  read -r -a zones <<< "${ZONES_LIST}"

    CONFIG=""
    for zone in "${zones[@]}"; do
        CONFIG="${CONFIG}${zone}=${FORWARDERS},"
    done

    echo "${CONFIG::-1}"
}

update_recursor_forwarder_config() {
    local FORWARDERS=$1
    local RECURSORS=$2
    local CONFIG_FILE="${3:-/etc/pdns-recursor/recursor.conf}"

    FORWARD_ZONES="forward-zones=${FORWARDERS}"
    RECURSE_ZONES="forward-zones-recurse=${RECURSORS}"

    sed -i -e "s/# forward-zones=/${FORWARD_ZONES}/" "${CONFIG_FILE}"
    sed -i -e "s/# forward-zones-recurse=/${RECURSE_ZONES}/" "${CONFIG_FILE}"
}

main() {
    # --help, --version
    [[ ${1} == "--help" ]] || [[ ${1} == "--version" ]] && exec /usr/local/sbin/pdns_recursor "${1}"

    # treat everything except "--" as exec cmd
    [[ ${1:0:2} != "--" ]] && exec "${@}"

    check_env

    if [[ -n ${DNS_AUTH_SERVICE} ]]; then
        FORWARDERS="$(get_ip_list_from_service "${DNS_AUTH_SERVICE}")"
    elif [[ -n ${DNS_AUTH_IP_ADDRESSES} ]]; then
        FORWARDERS="${DNS_AUTH_IP_ADDRESSES}"
    fi

    if [[ -n ${DNS_FORWARDER_SERVICE} ]]; then
        FORWARDER_IP_LIST="$(get_ip_list_from_service "${DNS_FORWARDER_SERVICE}")"
    elif [[ -n ${DNS_FORWARDER_IP_ADDRESSES} ]]; then
        FORWARDER_IP_LIST="${DNS_FORWARDER_IP_ADDRESSES}"
    fi

    FORWARDER_CONFIG="$(build_forwarder_config "${DNS_AUTH_ZONES}" "${FORWARDERS}")"
    RECURSOR_CONFIG="$(build_forwarder_config "." "${FORWARDER_IP_LIST}")"

    update_recursor_forwarder_config "${FORWARDER_CONFIG}" "${RECURSOR_CONFIG}"

    trap "rec_control quit" SIGHUP SIGINT SIGTERM

    /usr/local/sbin/pdns_recursor "$@" &

    wait
}

main "$@"
