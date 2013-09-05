#!/bin/bash
### BEGIN INIT INFO
# Provides:          apprentice
# Required-Start:    mysql
# Required-Stop:
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: a MariaDB cluster integrity checker
### END INIT INFO

NAME="`basename ${0/.sh/}`"
DAEMON="`which apprentice`"
PIDFILE="/var/run/${NAME}.pid"

[ -r /etc/default/${NAME} ] && source /etc/default/${NAME}

for file in /lib/init/vars.sh /lib/lsb/init-functions ; do
  source ${file}
done

#
# Function that starts the daemon/service
#
do_start()
{
    log_begin_msg "Starting ${NAME}..."

    if [ ! "${START}" = "true" ]; then
      log_failure_msg "this service is disabled. Enable it in /etc/default/$NAME"
      return 2
    elif [ ! "${SERVER}" ] || [ ! "${PASSWORD}" ] || [ ! ${USER} ] ; then
      log_failure_msg "Missing variables inside defaults file."
      return 2
    fi

    pidfile_dirname=`dirname ${PIDFILE}`

    [ -d "$pidfile_dirname" ] || mkdir -p "$pidfile_dirname"
    chown $USER:$GROUP "$pidfile_dirname"
    chmod 0750 "$pidfile_dirname"

    DAEMON_ARGS="--password ${PASSWORD} --user ${USER} --server ${SERVER} ${EXTRA_ARGS}"

    start-stop-daemon --start --background --make-pidfile --quiet \
            --pidfile ${PIDFILE} --exec ${DAEMON} --test > /dev/null || return 1
    start-stop-daemon --start --background --make-pidfile --quiet \
            --pidfile ${PIDFILE} --exec ${DAEMON} -- ${DAEMON_ARGS} || return 2
    log_end_msg $?
}

do_stop()
{
    log_begin_msg "Stopping ${NAME}..."

    start-stop-daemon --stop --quiet --retry=TERM/30/KILL/5 --signal 15 --pidfile ${PIDFILE}
    RETVAL="$?"
    [ "$RETVAL" = 2 ] && return 2
    [ "$?" = 2 ] && return 2
    rm -f ${PIDFILE}
    log_end_msg $?
    return "$RETVAL"
}

case "$1" in
  start)
    do_start
    ;;
  stop)
    do_stop
    ;;
  reload)
    do_stop
    do_start
    ;;
  restart|force-reload)
    do_stop
    do_start
    ;;
  *)
    echo "Usage: ${NAME} {start|stop|restart|reload|force-reload}" >&2
    exit 3
    ;;
esac