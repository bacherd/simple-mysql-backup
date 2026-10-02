# simple-mysql-backup

## how to use

The container creates a backup file (`<database>.sql`) for each database in `BACKUP_PATH`
once a day at `DUMP_TIME`. System schemas (`information_schema`, `performance_schema`, `sys`)
are skipped. A failed dump never overwrites the previous backup.

#### docker run
```
docker run --name backup -d \
    -e MYSQL_HOST=mysql \
    -e MYSQL_PASS=secret \
    -v ./backup:/backup \
    bacherd/simple-mysql-backup
```

### docker-compose
```
backup:
   image: bacherd/simple-mysql-backup
   environment:
     - MYSQL_HOST=mysql
     - MYSQL_PORT=3306
     - MYSQL_USER=root
     - MYSQL_PASS=
     - MYSQL_OPTS=
     - DUMP_AT_START=false
     - DUMP_TIME=00:00
     - BACKUP_PATH=/backup
     - TZ=Europe/Berlin
   volumes:
     - ./backup:/backup
   restart: always
```

### environment variables

| Variable        | Default   | Description                                                     |
|-----------------|-----------|-----------------------------------------------------------------|
| `MYSQL_HOST`    | –         | **required** database host                                      |
| `MYSQL_PASS`    | –         | **required** database password                                  |
| `MYSQL_PORT`    | `3306`    | database port                                                   |
| `MYSQL_USER`    | `root`    | database user                                                   |
| `MYSQL_OPTS`    | –         | additional client options, e.g. `--skip-ssl-verify-server-cert` |
| `DUMP_AT_START` | `false`   | create a backup when the container starts                       |
| `DUMP_TIME`     | `00:00`   | daily backup time (`HH:MM`, in `TZ`)                            |
| `BACKUP_PATH`   | `/backup` | target directory inside the container                           |
| `TZ`            | `UTC`     | time zone used for `DUMP_TIME`                                  |

### TLS

The client verifies the server certificate by default. For MySQL servers or MariaDB servers
with a self-signed certificate set `MYSQL_OPTS=--skip-ssl-verify-server-cert`
(or `MYSQL_OPTS=--skip-ssl` to disable TLS completely).

### manual backup

```
docker exec backup /entrypoint.sh backup
```
