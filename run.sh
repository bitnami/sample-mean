#!/bin/bash -e

# Make sure only root can run our script
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

# Load deployment environment
. /root/.deployment.env

case "$1" in
  start)
    # --uid and --gid are the unpriviledge user and group that will run the service
    # You can use a different one as long as it exists in the machine or you have created it before.
    pm2 start ${APP_FOLDER}/server.js --name node-todo --uid bitnami --gid bitnami
    exit $?
    ;;
  stop)
    pm2 stop node-todo --uid bitnami --gid bitnami
    exit $?
    ;;
  restart|force-reload|reload)
    pm2 restart node-todo --uid bitnami --gid bitnami
    exit $?
    ;;
  init)
    # Sleep randomly between 1 and 10 seconds to avoid race conditions between the different nodes
    # trying to initialize the data.
    sleep $(($RANDOM % 10 + 1))

    # Data initialization
    # The .initialized file is a semaphore to diffenciate when initialize the data
    # and when only start the application
    if [[ ! -f ${DATA_FOLDER}/.initialized ]]; then
      echo "==> Data not initialized. Initializing now..."
      # Create data folder
      mkdir -p ${DATA_FOLDER}
      # Touch semaphore
      touch ${DATA_FOLDER}/.initialized

      # Move static files to mount point
      mv ${APP_FOLDER}/public ${DATA_FOLDER}
      ln -sf ${DATA_FOLDER}/public ${APP_FOLDER}/public

      # Fix permissions
      # We set bitnami as user and group as is the user that will run the service.
      chown -R bitnami:bitnami ${DATA_FOLDER}
      chmod 600 ${DATA_FOLDER}/.initialized
    else
      echo "==> Data already initialized. Skipping..."
      # Restore data from ${DATA_FOLDER}
      rm -rf ${APP_FOLDER}/public
      ln -sf ${DATA_FOLDER}/public ${APP_FOLDER}/public
    fi

    # Application initialization
    echo "==> Initializing application..."

    # Fix permissions
    # We set bitnami as user and group as is the user that will run the service.
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
