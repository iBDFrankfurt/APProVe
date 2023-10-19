#!/bin/bash
container=$POSTGRES_CONTAINER_URL
mongoContainer=$MONGO_URL
echo 'dumping database for postgres container:'
echo $container
docker exec -t $container pg_dump --dbname="$APPROVE_AUTH_DB" --create --clean --if-exists --format=p --column-inserts  -U $APPROVE_POSTGRES_USER | gzip > dump_approve_auth-`date +%d-%m-%Y"_"%H_%M_%S`.sql.gz
docker exec -t $container pg_dump --dbname="$APPROVE_PROJECT_DB" --create --clean --if-exists --format=p --column-inserts  -U $APPROVE_POSTGRES_USER | gzip > dump_approve_db-`date +%d-%m-%Y"_"%H_%M_%S`.sql.gz
echo 'dumping database for mongo container:'
echo $mongoContainer
# Mongo
docker exec $mongoContainer sh -c 'mongodump --authenticationDatabase admin -u $APPROVE_MONGO_USER -p $APPROVE_MONGO_PASSWORD --db store --archive' > mongo-`date +%d-%m-%Y"_"%H_%M_%S`.dump
