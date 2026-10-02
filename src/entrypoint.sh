#!/bin/sh
set -eu

: "${MYSQL_HOST:?ERROR: MYSQL_HOST variable is required.}"
: "${MYSQL_PASS:?ERROR: MYSQL_PASS variable is required.}"
: "${MYSQL_PORT:=3306}"
: "${MYSQL_USER:=root}"
: "${MYSQL_OPTS:=}"
: "${DUMP_AT_START:=false}"
: "${DUMP_TIME:=00:00}"
: "${BACKUP_PATH:=/backup}"

# Pass credentials via option file instead of command line (hidden from ps)
CLIENT_CNF="/tmp/client.cnf"
umask 077
escaped_pass=$(printf '%s' "${MYSQL_PASS}" | sed 's/[\\"]/\\&/g')
cat > "${CLIENT_CNF}" <<CNF
[client]
host="${MYSQL_HOST}"
port=${MYSQL_PORT}
user="${MYSQL_USER}"
password="${escaped_pass}"
CNF
umask 022

mkdir -p "${BACKUP_PATH}"

###############################################################################

backup_db() {
    db="$1"
    target="${BACKUP_PATH}/${db}.sql"
    echo "-> backup \"${db}\""

    # Dump to temp file first so a failed dump never overwrites the last good backup
    # shellcheck disable=SC2086 # MYSQL_OPTS is intentionally word-split
    if mariadb-dump --defaults-extra-file="${CLIENT_CNF}" ${MYSQL_OPTS} \
        --single-transaction --routines --triggers --events \
        "${db}" > "${target}.tmp"; then
        mv "${target}.tmp" "${target}"
    else
        echo "ERROR: backup of \"${db}\" failed" >&2
        rm -f "${target}.tmp"
        return 1
    fi
}

###############################################################################

backup_all() {
    echo "$(date '+%F %T') backup all databases"
    failed=0

    # shellcheck disable=SC2086 # MYSQL_OPTS is intentionally word-split
    if ! dbs=$(mariadb --defaults-extra-file="${CLIENT_CNF}" ${MYSQL_OPTS} -N -e "SHOW DATABASES"); then
        echo "ERROR: could not list databases" >&2
        return 1
    fi

    for db in ${dbs}; do
        case "${db}" in
            information_schema|performance_schema|sys) continue ;;
        esac
        backup_db "${db}" || failed=1
    done

    return ${failed}
}

###############################################################################

case "${1:-}" in
    "")
        case "${DUMP_TIME}" in
            [0-9]:[0-5][0-9]|[01][0-9]:[0-5][0-9]|2[0-3]:[0-5][0-9]) ;;
            *) echo "ERROR: DUMP_TIME must be HH:MM (00:00-23:59)" >&2; exit 1 ;;
        esac
        hour="${DUMP_TIME%%:*}"; hour="${hour#0}"
        min="${DUMP_TIME##*:}";  min="${min#0}"

        if [ "${DUMP_AT_START}" = "true" ]; then
            backup_all || echo "WARNING: initial backup failed" >&2
        fi

        # Redirect job output to PID 1 so it shows up in `docker logs`
        echo "${min} ${hour} * * * /entrypoint.sh backup >/proc/1/fd/1 2>/proc/1/fd/2" \
            > /var/spool/cron/crontabs/root

        # exec: replace shell so tini forwards signals directly to crond
        exec /usr/sbin/crond -f -l 8
        ;;
    backup)
        backup_all
        ;;
    *)
        echo "ERROR: unknown parameter \"$1\"" >&2
        exit 1
        ;;
esac
