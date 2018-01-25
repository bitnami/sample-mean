#!/bin/bash -e

# Load deployment environment
. /bitnami/.env

# Move to application folder first
cd ${APP_FOLDER}

case "$1" in
  start)
    pm2 start server.js --name node-todo
    exit $?
    ;;
  stop)
    pm2 stop node-todo
    exit $?
    ;;
  restart|force-reload|reload)
    pm2 restart node-todo
    exit $?
    ;;
  init)
    if [[ ! -f .initialized ]]; then
      echo "==> Aplication not initialized. Initializing now..."

      # Install node modules
      npm install

      # Move static files to mount point
      rm -rf ${DATA_FOLDER}
      mkdir -p ${DATA_FOLDER}
      mv public ${DATA_FOLDER}
      ln -sf ${DATA_FOLDER}/public public

      # Touch semaphore
      touch .initialized
    else
      echo "==> Aplication already initialized. Skipping..."
    fi
esac
