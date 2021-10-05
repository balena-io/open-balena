#!/usr/bin/env bash

# the acme.sh client script, installed via Git in the Dockerfile...
ACME_BIN="$(realpath ~/.acme.sh/acme.sh)"

# the path to a bundle of certs to verify a LetsEncrypt staging certificate until Apr 2036...
ACME_STAGING_CA="/usr/src/app/fake-le-bundle.pem"

# the path to a file which stores the last successful mode of certificate we acquired...
ACME_MODE_FILE="/usr/src/app/certs/last_run_mode"

# colour output helpers...
reset=$(tput -T xterm sgr0)
red=$(tput -T xterm setaf 1)
green=$(tput -T xterm setaf 2)
yellow=$(tput -T xterm setaf 3)
blue=$(tput -T xterm setaf 4)

logError() {
    echo "${red}[Error]${reset} $1"
}

logWarn() {
    echo "${yellow}[Warn]${reset} $1"
}

logInfo() {
    echo "${blue}[Info]${reset} $1"
}

logSuccess() {
    echo "${green}[Success]${reset} $1"
}

logErrorAndStop() {
    logError "$1 [Stopping]"
    while true; do
        # do nothing forever...
        sleep 60
    done
}

retryWithDelay() {
    RETRIES=${2:-3}
    DELAY=${3:-5}

    local ATTEMPT=0
    while [ "$RETRIES" -gt "$ATTEMPT" ]; do
        (( ATTEMPT++ ))
        logInfo "($ATTEMPT/$RETRIES) Connecting..."
        if $1; then
            logInfo "($ATTEMPT/$RETRIES) Success!"
            return $?
        fi

        if [ "$RETRIES" -gt "$ATTEMPT" ]; then
            logInfo "($ATTEMPT/$RETRIES) Failed. Retrying in ${DELAY} seconds..."
            sleep "$DELAY"
        else
            logInfo "($ATTEMPT/$RETRIES) Failed!"
        fi
    done

    return 1
}

waitForOnline() {
    ADDRESS="${1,,}"

    logInfo "Waiting for ${ADDRESS} to be available via HTTP..."
    retryWithDelay "curl --output /dev/null --silent --head --fail --max-time 5 http://${ADDRESS}"
}

isUsingStagingCert() {
    HOST="${1,,}"
    echo "" | openssl s_client -host "$HOST" -port 443 -showcerts 2>/dev/null | awk '/BEGIN CERT/ {p=1} ; p==1; /END CERT/ {p=0}' | openssl verify -CAfile "$ACME_STAGING_CA" > /dev/null 2>&1
}

pre-flight() {
    case "$ACTIVE" in
        "true"|"yes")
            ;;
        *)
            logError "ACTIVE variable is not enabled. Value should be \"true\" or \"yes\" to continue."
            return 1
            ;;
    esac

    if [ -z "$DOMAINS" ]; then
        logError "DOMAINS must be set. Value should be a comma-delimited string of domains."
        return 1
    else
        IFS=, read -r -a ACME_DOMAINS <<< "$DOMAINS"
        IFS=' ' read -r -a ACME_DOMAIN_ARGS <<< "${ACME_DOMAINS[@]/#/-d }"
    fi

    if [ -z "$VALIDATION" ]; then
        logInfo "VALIDATION not set. Using default: http-01"
        VALIDATION="http-01"
    else
        case "$VALIDATION" in
            "http-01")
                logInfo "Using validation method: $VALIDATION"
                ;;
            *)
                logError "VALIDATION is invalid. Use a valid value: http-01"
                return 1
                ;;
        esac
    fi

    if [ -z "$OUTPUT_PEM" ]; then
        logError "OUTPUT_PEM must be set. Value should be the path to install your certificate to."
        return 1
    fi
}

waitToSeeStagingCert() {
    logInfo "Waiting for ${ACME_DOMAINS[0]} to use a staging certificate..."
    retryWithDelay "isUsingStagingCert ${ACME_DOMAINS[0]}" 3 5
}

lastAcquiredCertFor() {
    ACME_MODE="${1:-none}"
    ACME_LAST_MODE="$(cat $ACME_MODE_FILE || echo '')"
    logInfo "Last acquired certificate for ${ACME_LAST_MODE^^}"
    [ "${ACME_LAST_MODE,,}" == "${ACME_MODE,,}" ]
}

acquireCertificate() {
    ACME_MODE="${1:-staging}"
    ACME_FORCE="${2:-false}"
    ACME_OPTS=()

    if [ "${ACME_FORCE,,}" == "true" ];then ACME_OPTS+=("--force"); fi
    case "$ACME_MODE" in
        "production")
            logInfo "Using PRODUCTION mode"
            ;;
        *)
            logInfo "Using STAGING mode"
            ACME_OPTS+=("--staging")
            ;;
    esac

    case "$VALIDATION" in
        "http-01")
            ACME_OPTS+=("--standalone")
            ;;
        *)
            logError "VALIDATION is invalid. Use a valid value: http-01"
            return 1
            ;;
    esac

    if ! waitForOnline "${ACME_DOMAINS[0]}"; then
        logError "Unable to access site over HTTP"
        return 1
    fi

    logInfo "Issuing certificates..."
    "$ACME_BIN" --server letsencrypt --issue "${ACME_OPTS[@]}" "${ACME_DOMAIN_ARGS[@]}"

    logInfo "Installing certificates..." && \
    "$ACME_BIN" --install-cert "${ACME_DOMAIN_ARGS[@]}" \
    --cert-file      /tmp/cert.pem  \
    --key-file       /tmp/key.pem  \
    --fullchain-file /tmp/fullchain.pem \
    --reloadcmd     "cat /tmp/fullchain.pem /tmp/key.pem > $OUTPUT_PEM" && \

    echo "${ACME_MODE}" > "${ACME_MODE_FILE}"
}

pre-flight || logErrorAndStop "Unable to continue due to misconfiguration. See errors above."

while ! waitForOnline "${ACME_DOMAINS[0]}"; do
    logInfo "Unable to access ${ACME_DOMAINS[0]} on port 80. This is needed for certificate validation. Retrying in 30 seconds..."
    sleep 30
done

if ! lastAcquiredCertFor "production"; then
    acquireCertificate "staging" || logErrorAndStop "Unable to acquire a staging certificate."
    waitToSeeStagingCert || logErrorAndStop "Unable to detect certificate change over. Cannot issue a production certificate."
    acquireCertificate "production" "true" || logErrorAndStop "Unable to acquire a production certificate."
fi

logSuccess "Done!"

logInfo "Running cron..."
crond -f -d 7