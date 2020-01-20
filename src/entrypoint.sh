#!/bin/ash

if [[ -z ${MYSQL_HOST} ]]; then
    echo "ERROR: MYSQL_HOST variable is required."
    exit 1
fi

if [[ -z ${MYSQL_PORT} ]]; then
    MYSQL_PORT="3306"
fi

if [[ -z ${MYSQL_USER} ]]; then
    MYSQL_USER="root"
fi

if [[ -z ${MYSQL_PASS} ]]; then
    echo "ERROR: MYSQL_PASS variable is required."
    exit 1
fi

if [[ -z ${DUMP_AT_START} ]]; then
    DUMP_AT_START=false
fi

if [[ -z ${DUMP_TIME} ]]; then
    DUMP_TIME=00:00
fi

if [[ -z ${BACKUP_PATH} ]]; then
    BACKUP_PATH=/backup
fi

mkdir -p ${BACKUP_PATH}

###############################################################################

function backup_db() {
    echo "-> backup \"${db}\":"
    mysqldump -h${MYSQL_HOST} -P${MYSQL_PORT} -u${MYSQL_USER} -p${MYSQL_PASS} ${db} > ${BACKUP_PATH}/${db}.sql
}

###############################################################################

function backup_all() {
    echo "backup all databases"
    DB_LIST=`echo "show databases;" | mysql -h${MYSQL_HOST} -P${MYSQL_PORT} -u${MYSQL_USER} -p${MYSQL_PASS}`
    for db in ${DB_LIST}; do
        if [ ${db} != "Database" ]; then
            backup_db ${db}
        fi
    done
}

###############################################################################

if [[ $# -eq 0 ]]; then
    if [[ ${DUMP_AT_START} == "true" ]]; then
        backup_all
    fi

    hour=$(echo "${DUMP_TIME}" | cut -d ':' -f 1)
    min=$(echo "${DUMP_TIME}" | cut -d ':' -f 2)

    if [[ ${hour} -gt 23 ]] || [[ ${hour} -lt 0 ]]; then
        echo "ERROR: DUMP_TIME hour is out of range"
        exit 1
    fi
    
    if [[ ${min} -gt 59 ]] || [[ ${min} -lt 0 ]]; then
        echo "ERROR: DUMP_TIME min is out of range"
        exit 1
    fi

    #    min  hour day  month   weekday command
    echo "${min} ${hour} *   *   * /entrypoint.sh backup" > /var/spool/cron/crontabs/root
    /usr/sbin/crond -f -l 8
else
    if [[ $1 == "backup" ]]; then
        backup_all
    else
        echo "ERROR: unknown parameter."
        exit 1
    fi
fi

exit 0
