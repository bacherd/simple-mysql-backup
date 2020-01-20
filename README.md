# simple-mysql-backup

## how to use

The container create an backupfile foreach table in database to /backup.

#### docker run
```
docker run --name backup -d \
    -v ./backup:/opt/backup \
    bacherd/simple-mysql-backup
```    

### docker-compose
```
websvn:
   image: bacherd/simple-mysql-backup
   environment:
     - MYSQL_HOST=mysql
     - MYSQL_PORT=3306
     - MYSQL_USER=root
     - MYSQL_PASS=
     - DUMP_AT_START=false
     - DUMP_TIME=00:00
     - BACKUP_PATH=/backup
   volumes:
     - ./backup:/backup
   restart: always
```   
