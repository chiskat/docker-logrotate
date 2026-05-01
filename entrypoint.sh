#!/bin/sh
set -eu

LOGROTATE_INCLUDE_DIR="${LOGROTATE_INCLUDE_DIR:-/etc/logrotate.d}"
LOGROTATE_MAIN_CONFIG="${LOGROTATE_MAIN_CONFIG:-/etc/logrotate.conf}"
LOGROTATE_STATE_FILE="${LOGROTATE_STATE_FILE:-/var/lib/logrotate/logrotate.status}"
LOGROTATE_OPTIONS="${LOGROTATE_OPTIONS:--v}"
LOGROTATE_CRON="${LOGROTATE_CRON:-}"
LOGROTATE_DEFAULT_CONFIG="/etc/logrotate.conf.default"
LOGROTATE_RUNNER="/usr/local/bin/run-logrotate.sh"
CRONTAB_FILE="/etc/crontabs/root"
PERIODIC_DAILY_LOGROTATE="/etc/periodic/daily/logrotate"

if [ ! -f "${LOGROTATE_MAIN_CONFIG}" ]; then
  sed "s|__LOGROTATE_INCLUDE_DIR__|${LOGROTATE_INCLUDE_DIR}|g" "${LOGROTATE_DEFAULT_CONFIG}" >"${LOGROTATE_MAIN_CONFIG}"
fi

cat >"${LOGROTATE_RUNNER}" <<EOF
#!/bin/sh
set -eu
logrotate -s "${LOGROTATE_STATE_FILE}" ${LOGROTATE_OPTIONS} "${LOGROTATE_MAIN_CONFIG}" || true
EOF
chmod +x "${LOGROTATE_RUNNER}"

touch "${CRONTAB_FILE}"
sed -i "\|${LOGROTATE_RUNNER}|d" "${CRONTAB_FILE}"

if [ -n "${LOGROTATE_CRON}" ]; then
  rm -f "${PERIODIC_DAILY_LOGROTATE}"
  printf "%s %s\n" "${LOGROTATE_CRON}" "${LOGROTATE_RUNNER}" >>"${CRONTAB_FILE}"
else
  cat >"${PERIODIC_DAILY_LOGROTATE}" <<EOF
#!/bin/sh
set -eu
"${LOGROTATE_RUNNER}"
EOF
  chmod +x "${PERIODIC_DAILY_LOGROTATE}"
fi

exec crond -f -l 8 -L /dev/stdout
