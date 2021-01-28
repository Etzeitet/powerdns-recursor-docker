get_ip_list_from_service() {
    local SERVICE_NAME="${1}"
    local SEPARATOR="${2:-;}"

    local IP_LIST="$(getent ahostsv4 tasks.${SERVICE_NAME}|awk '/STREAM/ {print $1}'|tr '\n' "${SEPARATOR}")"
    echo "${IP_LIST::-1}"
}
