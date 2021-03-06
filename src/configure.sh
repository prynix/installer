#!/usr/bin/env bash
source $(dirname $(readlink -f "$0"))/_functions.sh --root
echo " > $0 $*"

CONFIG_FILE=${ETC_DIR}/config.env
if [[ -f ${CONFIG_FILE} ]]
then
    set -a
    source ${CONFIG_FILE}
    set +a
fi

read_env ${VENDOR_DIR}/adserver/.env || read_env ${VENDOR_DIR}/adserver/.env.dist

configDefault HOSTNAME "`php -r 'if(count($argv) == 3) echo parse_url($argv[1])[$argv[2]];' "$ADPANEL_URL" host 2>/dev/null`" INSTALL

configDefault API_HOSTNAME "`php -r 'if(count($argv) == 3) echo parse_url($argv[1])[$argv[2]];' "$APP_URL" host 2>/dev/null`" INSTALL

configDefault DATA_HOSTNAME "`php -r 'if(count($argv) == 3) echo parse_url($argv[1])[$argv[2]];' "$ADUSER_BASE_URL" host 2>/dev/null`" INSTALL

configDefault ADSERVER 1 INSTALL
readOption ADSERVER "Install local >AdServer< service?" 1 INSTALL

configDefault APP_NAME "Best Adshares Adserver" INSTALL

INSTALL_SCHEME=https
BANNER_FORCE_HTTPS=true

if [[ ${INSTALL_ADSERVER:-0} -eq 1 ]]
then
    if [[ -f /etc/nginx/sites-enabled/default ]]
    then
        echo "Default configuration of nginx must be deleted \"rm /etc/nginx/sites-enabled/default\""
        exit 1
    fi

    readOption APP_NAME "Adserver name" 0 INSTALL
    readOption API_HOSTNAME "AdServer domain (backend)" 0 INSTALL

    configDefault API_HOSTNAME_SERVE ${INSTALL_API_HOSTNAME} INSTALL
    readOption API_HOSTNAME_SERVE "AdServer domain (for serving banners, might get adblocked)" 0 INSTALL
    configDefault API_HOSTNAME_MAIN_JS ${INSTALL_API_HOSTNAME} INSTALL
    readOption API_HOSTNAME_MAIN_JS "AdServer domain (for serving scripts, might get adblocked)" 0 INSTALL

    unset APP_PORT
    unset APP_HOST
    unset APP_NAME
    unset APP_ENV

    read_env ${VENDOR_DIR}/adserver/.env || read_env ${VENDOR_DIR}/adserver/.env.dist
    APP_URL="${INSTALL_SCHEME}://${INSTALL_API_HOSTNAME}"
    APP_ID=${APP_ID:-"_`echo "${INSTALL_API_HOSTNAME}" | sha256sum | head -c 16`"}
    APP_KEY=${APP_KEY:-"base64:`date | sha256sum | head -c 32 | base64`"}
    ADSERVER_APP_NAME=${APP_NAME:-$INSTALL_APP_NAME}
    ADSERVER_DB_DATABASE=${DB_DATABASE:-"${VENDOR_NAME}_adserver"}
    ADSERVER_DB_USERNAME=${DB_USERNAME:-"${VENDOR_NAME}"}
    ADSERVER_DB_PASSWORD=${DB_PASSWORD:-"${VENDOR_NAME}"}

    if [[ -z ${INSTALL_API_HOSTNAME_SERVE} ]]
    then
        SERVE_BASE_URL=""
    else
        SERVE_BASE_URL="${INSTALL_SCHEME}://${INSTALL_API_HOSTNAME_SERVE}"
    fi
    if [[ -z ${INSTALL_API_HOSTNAME_MAIN_JS} ]]
    then
        MAIN_JS_BASE_URL=""
    else
        MAIN_JS_BASE_URL="${INSTALL_SCHEME}://${INSTALL_API_HOSTNAME_MAIN_JS}"
    fi

    readOption ADSHARES_ADDRESS "ADS wallet address"
    readOption ADSHARES_SECRET "ADS wallet secret"
    readOption ADSHARES_NODE_HOST "ADS node hostname"
    readOption ADSHARES_NODE_PORT "ADS node port"
    readOption ADSHARES_OPERATOR_EMAIL "ADS wallet owner email (for balance alerts)"
    ADSHARES_COMMAND=`which ads`
    ADSHARES_WORKINGDIR="${VENDOR_DIR}/adserver/storage/wallet"

    configDefault ADSERVER_CLASSIFIER_EXTERNAL 1 INSTALL
    readOption ADSERVER_CLASSIFIER_EXTERNAL "Install Adshares external classifier for AdServer?" 1 INSTALL
    if [[ ${INSTALL_ADSERVER_CLASSIFIER_EXTERNAL:-0} -eq 1 ]]
    then
        readOption CLASSIFIER_EXTERNAL_API_KEY_NAME "External classifier API Key Name"
        readOption CLASSIFIER_EXTERNAL_API_KEY_SECRET "External classifier API Key Secret"
        CLASSIFIER_EXTERNAL_NAME="0001000000081a67"
        CLASSIFIER_EXTERNAL_BASE_URL="https://adclassify.adshares.net"
        CLASSIFIER_EXTERNAL_PUBLIC_KEY="614DA6DE6ACD8996E0D9124D437F477FE96CB7AFE2A3E2D9B852F58626A0F695"
    else
        CLASSIFIER_EXTERNAL_API_KEY_NAME=""
        CLASSIFIER_EXTERNAL_API_KEY_SECRET=""
        CLASSIFIER_EXTERNAL_NAME=""
        CLASSIFIER_EXTERNAL_BASE_URL=""
        CLASSIFIER_EXTERNAL_PUBLIC_KEY=""
    fi

    readOption MAIL_HOST "mail smtp host"
    readOption MAIL_PORT "mail smtp port"
    readOption MAIL_USERNAME "mail smtp username"
    readOption MAIL_PASSWORD "mail smtp password"
    readOption MAIL_FROM_ADDRESS "mail from address"
    readOption MAIL_FROM_NAME "mail from name"

    MAIL_ENCRYPTION=${MAIL_ENCRYPTION:-"tls"}
    readOption MAIL_ENCRYPTION "mail encryption ('none' to skip encryption, usually 'tls')"

    configDefault ADSERVER_CRON 1 INSTALL
    readOption ADSERVER_CRON "Install AdServer cron jobs?" 1 INSTALL

    configDefault ADSERVER_CRON_REMOVE 1 INSTALL
    if [[ ${INSTALL_ADSERVER_CRON:-0} -eq 0 ]]
    then
        readOption ADSERVER_CRON_REMOVE "Clear cron jobs?" 1 INSTALL
    fi
else
    configDefault API_HOSTNAME ${API_HOSTNAME:-"${INSTALL_SCHEME}://app.example.com"}
    readOption API_HOSTNAME "External (or previously installed) AdServer domain (backend)"
fi

configDefault ADPANEL 1 INSTALL
readOption ADPANEL "Install local >AdPanel< service?" 1 INSTALL

if [[ ${INSTALL_ADPANEL:-0} -eq 1 ]]
then
    INSTALL_ADPANEL=1
    ADSERVER_URL="$APP_URL"

    unset APP_PORT
    unset APP_HOST
    unset APP_NAME
    unset APP_ENV

    if [[ ${INSTALL_ADSERVER:-0} -eq 0 ]]
    then
        readOption APP_NAME "Adserver name" 0 INSTALL
    fi
    readOption HOSTNAME "AdPanel domain (UI for advertisers and publishers)" 0 INSTALL

    APP_HOST=${INSTALL_HOSTNAME}

    read_env ${VENDOR_DIR}/adpanel/.env || read_env ${VENDOR_DIR}/adpanel/.env.dist
    APP_NAME=${APP_NAME:-$INSTALL_APP_NAME}

    ADPANEL_URL="${INSTALL_SCHEME}://$INSTALL_HOSTNAME"

    BRAND_ASSETS_DIR=${ADPANEL_BRAND_ASSETS_DIR:-""}

    save_env ${VENDOR_DIR}/adpanel/.env.dist ${VENDOR_DIR}/adpanel/.env adpanel

    ADPANEL_BRAND_ASSETS_DIR=${ADPANEL_BRAND_ASSETS_DIR:-""}
    readOption ADPANEL_BRAND_ASSETS_DIR "Directory where custom brand assets are stored. If dir does not exist, standard assets will be used"

    if ! [[ -z ${ADPANEL_BRAND_ASSETS_DIR} ]] && ! [[ -d "${ADPANEL_BRAND_ASSETS_DIR}" ]]
    then
        echo "Directory ${ADPANEL_BRAND_ASSETS_DIR} doesn't exist. IGNORING"
    fi
else
    configDefault ADPANEL_ENDPOINT ${ADPANEL_URL:-"${INSTALL_SCHEME}://example.com"}
    readOption ADPANEL_ENDPOINT "External (or previously installed) AdPanel service endpoint"
    ADPANEL_URL=${ADPANEL_ENDPOINT:-${ADPANEL_URL}}
fi

configDefault ADSELECT 1 INSTALL
readOption ADSELECT "Install local >AdSelect< service?" 1 INSTALL

if [[ ${INSTALL_ADSELECT:-0} -eq 1 ]]
then
    INSTALL_ADSELECT=1

    unset APP_PORT
    unset APP_HOST
    unset APP_NAME

    read_env ${VENDOR_DIR}/adselect/.env.local || read_env ${VENDOR_DIR}/adselect/.env

    APP_SECRET=${APP_SECRET:-"`date | sha256sum | head -c 64`"}
    APP_VERSION=$(versionFromGit ${VENDOR_DIR}/adselect)

    APP_PORT=${APP_PORT:-8011}
    APP_HOST=${APP_HOST:-127.0.0.1}

    ES_NAMESPACE="${VENDOR_NAME}_adselect"

    save_env ${VENDOR_DIR}/adselect/.env ${VENDOR_DIR}/adselect/.env.local adselect

    ADSELECT_ENDPOINT="http://${APP_HOST}:${APP_PORT}"
    readOption ADSELECT_ENDPOINT "Internal AdSelect service endpoint"
    X_ADSELECT_VERSION=php
else
    INSTALL_ADSELECT=0
    ADSELECT_ENDPOINT=${ADSELECT_ENDPOINT:-"http://localhost:8011"}
    readOption ADSELECT_ENDPOINT "External (or previously installed) AdSelect service endpoint"
fi

configDefault ADPAY 1 INSTALL
readOption ADPAY "Install local >AdPay< service?" 1 INSTALL

if [[ ${INSTALL_ADPAY:-0} -eq 1 ]]
then
    INSTALL_ADPAY=1

    unset APP_PORT
    unset APP_HOST
    unset APP_NAME
    unset APP_ENV
    unset DB_DATABASE
    unset DB_USERNAME
    unset DB_PASSWORD
    unset DATABASE_URL

    read_env ${VENDOR_DIR}/adpay/.env.local || read_env ${VENDOR_DIR}/adpay/.env

    APP_ENV=prod
    APP_SECRET=${APP_SECRET:-"`date | sha256sum | head -c 64`"}
    APP_VERSION=$(versionFromGit ${VENDOR_DIR}/adpay)

    APP_PORT=${APP_PORT:-8012}
    APP_HOST=${APP_HOST:-127.0.0.1}

    DB_DATABASE=${DB_DATABASE:-"${VENDOR_NAME}_adpay"}
    DB_USERNAME=${DB_USERNAME:-"${VENDOR_NAME}"}
    DB_PASSWORD=${DB_PASSWORD:-"${VENDOR_NAME}"}
    DATABASE_URL=${DATABASE_URL:-"mysql://${DB_USERNAME}:${DB_PASSWORD}@localhost:3306/${DB_DATABASE}"}

    LOG_FILE_PATH=${LOG_DIR}/adpay.log

    save_env ${VENDOR_DIR}/adpay/.env ${VENDOR_DIR}/adpay/.env.local adpay

    ADPAY_ENDPOINT="http://${APP_HOST}:${APP_PORT}"
    readOption ADPAY_ENDPOINT "Internal AdPay service endpoint"
else
    INSTALL_ADPAY=0
    ADPAY_ENDPOINT=${ADPAY_ENDPOINT:-"http://localhost:8012"}
    readOption ADPAY_ENDPOINT "External (or previously installed) AdPay service endpoint"
fi

configDefault ADUSER 0 INSTALL
readOption ADUSER "Install local >AdUser< service?" 1 INSTALL

#configDefault UPDATE_DATA 0 ADUSER

if [[ ${INSTALL_ADUSER:-0} -eq 1 ]]
then
    INSTALL_ADUSER=1

    unset APP_PORT
    unset APP_HOST
    unset APP_NAME
    unset APP_ENV
    unset DB_DATABASE
    unset DB_USERNAME
    unset DB_PASSWORD

    read_env ${VENDOR_DIR}/aduser/.env.local || read_env ${VENDOR_DIR}/aduser/.env

    APP_ENV=prod
    APP_SECRET=${APP_SECRET:-"`date | sha256sum | head -c 64`"}
    APP_VERSION=$(versionFromGit ${VENDOR_DIR}/aduser)

    APP_PORT=${APP_PORT:-80}
    APP_HOST=${APP_HOST:-127.0.0.1}

    readOption RECAPTCHA_SITE_KEY "Google reCAPTCHA v3 site key"
    readOption RECAPTCHA_SECRET_KEY "Google reCAPTCHA v3 secret key"

    ADUSER_TRACKING_SECRET=${ADUSER_TRACKING_SECRET:-"`date | sha256sum | head -c 64`"}
    DB_DATABASE=${DB_DATABASE:-"${VENDOR_NAME}_aduser"}
    DB_USERNAME=${DB_USERNAME:-"${VENDOR_NAME}"}
    DB_PASSWORD=${DB_PASSWORD:-"${VENDOR_NAME}"}

    LOG_FILE_PATH=${LOG_DIR}/aduser.log

    save_env ${VENDOR_DIR}/aduser/.env ${VENDOR_DIR}/aduser/.env.local aduser

    ADUSER_ENDPOINT="http://${APP_HOST}:${APP_PORT}"
    readOption ADUSER_ENDPOINT "Internal AdUser service endpoint"

    ADUSER_BASE_URL="$ADUSER_ENDPOINT"

#    readOption UPDATE_DATA "Update context discovery data?" 1 ADUSER
else
    INSTALL_ADUSER=0
    configDefault ADUSER_ENDPOINT "https://gitoku.com"
    readOption ADUSER_ENDPOINT "External AdUser service endpoint"

    ADUSER_BASE_URL="$ADUSER_ENDPOINT"
fi

APP_HOST=${INSTALL_API_HOSTNAME}
APP_NAME=${APP_NAME:-$INSTALL_APP_NAME}

configDefault LICENSE_SERVER_URL "https://account.adshares.pl" ADSHARES
LICENSE_SERVER_URL="https://account.adshares.pl"
configDefault LICENSE_KEY "SRV-000000" ADSHARES

configDefault HAVE_LICENSE 0 ADSHARES
readOption HAVE_LICENSE "Do you have support license from ${LICENSE_SERVER_URL}?" 1 ADSHARES

if [[ ${ADSHARES_HAVE_LICENSE:-0} -eq 1 ]]
then
    readOption LICENSE_KEY "Adshares Network LICENSE Key" 0 ADSHARES
fi

unset APP_PORT
unset APP_HOST
unset APP_NAME

APP_NAME=${ADSERVER_APP_NAME}
APP_HOST=${INSTALL_API_HOSTNAME}
LOG_FILE_PATH=${LOG_DIR}/adserver.log
LOG_LEVEL=${LOG_LEVEL:-error}
LOG_CHANNEL=${LOG_CHANNEL:-single}
DB_DATABASE=${ADSERVER_DB_DATABASE}
DB_USERNAME=${ADSERVER_DB_USERNAME}
DB_PASSWORD=${ADSERVER_DB_PASSWORD}

save_env ${VENDOR_DIR}/adserver/.env.dist ${VENDOR_DIR}/adserver/.env adserver

configDefault CERTBOT_NGINX 0 INSTALL
if [[ "${INSTALL_SCHEME^^}" == "HTTPS" ]]
then
    readOption CERTBOT_NGINX "Do you want to setup SSL using Let's Encrypt / certbot" 1 INSTALL
fi

configDefault UPDATE_TARGETING 1 ADSERVER
#readOption UPDATE_TARGETING "Do you want to update targeting options" 1 ADSERVER

configDefault UPDATE_FILTERING 1 ADSERVER
#readOption UPDATE_FILTERING "Do you want to update filtering options" 1 ADSERVER

configDefault CREATE_ADMIN 1 ADSERVER
readOption CREATE_ADMIN "Do you want to create an admin user for $ADSHARES_OPERATOR_EMAIL" 1 ADSERVER

configDefault APP_HOST_SERVE ${INSTALL_API_HOSTNAME_SERVE:-"${API_HOSTNAME}"} ADSERVER
configDefault APP_HOST_MAIN_JS ${INSTALL_API_HOSTNAME_MAIN_JS:-"${ADSERVER_APP_HOST_SERVE}"} ADSERVER

if [[ ${ADSERVER_CREATE_ADMIN:-0} -eq 1 ]]
then
    TMP_ADMIN_PASSWORD=""
    readOption TMP_ADMIN_PASSWORD "Please provide an initial admin password"
    echo "TMP_ADMIN_PASSWORD=\"$TMP_ADMIN_PASSWORD\"" >> ${VENDOR_DIR}/.tmp.env
fi

configDefault FPM_POOL 1 INSTALL
readOption FPM_POOL "Do you want to setup php-fpm pool" 1 INSTALL

configVars | tee ${CONFIG_FILE}

> ${SCRIPT_DIR}/services.txt

if [[ ${INSTALL_ADSELECT:-0} -eq 1 ]]
then
    echo "adselect" | tee -a ${SCRIPT_DIR}/services.txt
    configVars ADSELECT | tee -a ${VENDOR_DIR}/adselect/.env.local
fi

if [[ ${INSTALL_ADPAY:-0} -eq 1 ]]
then
    echo "adpay" | tee -a ${SCRIPT_DIR}/services.txt
    configVars ADPAY | tee -a ${VENDOR_DIR}/adpay/.env.local
fi

if [[ ${INSTALL_ADUSER:-0} -eq 1 ]]
then
    echo "aduser" | tee -a ${SCRIPT_DIR}/services.txt
    configVars ADUSER | tee -a ${VENDOR_DIR}/aduser/.env.local
fi

if [[ ${INSTALL_ADSERVER:-0} -eq 1 ]]
then
    echo "adserver" | tee -a ${SCRIPT_DIR}/services.txt
    configVars ADSERVER | tee -a ${VENDOR_DIR}/adserver/.env
fi

if [[ ${INSTALL_ADPANEL:-0} -eq 1 ]]
then
    echo "adpanel" | tee -a ${SCRIPT_DIR}/services.txt
    configVars ADPANEL | tee -a ${VENDOR_DIR}/adpanel/.env
fi
