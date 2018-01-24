#!/bin/bash -e

# Load deployment environment
. /bitnami/.env

# Load balancer will redirect HTTP (port 80) traffic to port 8080
export PORT=8080

# Move to application folder first
cd ${APP_FOLDER}

# TODOC: Bash + npm style
start () {
  npm start &
  ps x -o  "%p %r" | grep $! | awk '{print $2}' > ${APP_FOLDER}/app.pid
}

stop () {
  pid=$(cat ${APP_FOLDER}/app.pid)
  if [ -n "${pid}" ]; then
    kill -SIGTERM -- -${pid}
    rm ${APP_FOLDER}/app.pid
  fi
}

case "$1" in
  start)
    su bitnami pm2 start server.js --name node-todo
    exit $?
    ;;
  stop)
    su bitnami pm2 stop node-todo
    exit $?
    ;;
  restart|force-reload|reload)
    # `--update-env` will allow to load environment variables from /bitnami/.env
    # in case they changed
    su bitnami pm2 restart node-todo --update-env
    exit $?
    ;;
  init)
    if [[ ! -f ${DATA_FOLDER}/.initialized ]]; then
      echo "==> Aplication not initialized. Initializing now..."

      # Move static files to mount point
      rm -rf ${DATA_FOLDER}
      mkdir -p ${DATA_FOLDER}
      mv public ${DATA_FOLDER}
      ln -sf ${DATA_FOLDER}/public public

      # Fix permissions
      chown -R bitnami:bitnami ${APP_FOLDER}
      chown -R bitnami:bitnami ${DATA_FOLDER}
      chown root:root ${APP_FOLDER}/run.sh

      # Install node modules
      su bitnami npm install

      # Touch semaphore
      su bitnami ${DATA_FOLDER}/.initialized
    else
      echo "==> Aplication already initialized. Skipping..."
    fi
    exit 0
    ;;
  *)
    echo "Invalid option!"
    exit 1
    ;;
esac
