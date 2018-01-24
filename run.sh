#!/bin/bash -e

# Load deployment environment
. /bitnami/.env

# Load balancer will redirect HTTP (port 80) traffic to port 8080
export PORT=8080

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
    pm2 start ${APP_FOLDER}/server.js --name node-todo --uid bitnami --gid bitnami
    exit $?
    ;;
  stop)
    pm2 stop node-todo --uid bitnami --gid bitnami
    exit $?
    ;;
  restart|force-reload|reload)
    # `--update-env` will allow to load environment variables from /bitnami/.env
    # in case they changed
    pm2 restart node-todo --update-env --uid bitnami --gid bitnami
    exit $?
    ;;
  init)
    # Sleep randomly between 1 and 10 seconds to avoid race conditions
    sleep $(($RANDOM % 10 + 1))

    # Data initialization
    if [[ ! -f ${DATA_FOLDER}/.initialized ]]; then
      echo "==> Data not initialized. Initializing now..."
      # Create data folder
      mkdir -p ${DATA_FOLDER}
      # Touch semaphore
      touch ${DATA_FOLDER}/.initialized

      # Move static files to mount point
      mv public ${DATA_FOLDER}
      ln -sf ${DATA_FOLDER}/public ${APP_FOLDER}/public

      # Fix permissions
      chown -R bitnami:bitnami ${DATA_FOLDER}
      chmod 600 ${DATA_FOLDER}/.initialized
    else
      echo "==> Data already initialized. Skipping..."
      # Link static files
      rm -rf ${APP_FOLDER}/public
      ln -sf ${DATA_FOLDER}/public ${APP_FOLDER}/public
    fi

    # Application initialization
    echo "==> Initializing application..."

    # Fix permissions
    chown -R bitnami:bitnami ${APP_FOLDER}
    chown root:root ${APP_FOLDER}/run.sh

    # Install dependencies
    su - bitnami -c "cd ${APP_FOLDER}; npm install"
    exit 0
    ;;
  *)
    echo "Invalid option!"
    exit 1
    ;;
esac
