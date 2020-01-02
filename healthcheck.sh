#!/bin/bash
set -e

FAILED=0

check_domain() {
    local domain="${1}"

    result="$(dig +short ${domain} @localhost)"
    if [[ -n ${result} ]]; then
        printf "Domain check for %s: success\n" "${domain}"
    else
        printf "Domain check for %s: failed\n" "${domain}"
        FAILED=1
    fi
}

main() {
    local auth_domain_to_check="${1}"
    local recurse_domain_to_check="${2}"

    check_domain "${auth_domain_to_check}"
    check_domain "${recurse_domain_to_check}"

    if [[ ${FAILED} == 1 ]]; then
        exit 1
    else
        exit 0
    fi
}

main "$@"
