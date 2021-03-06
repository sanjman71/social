#! /bin/sh

### BEGIN INIT INFO
# Provides:          unicorn
# Required-Start:    $local_fs $remote_fs $network $syslog
# Required-Stop:     $local_fs $remote_fs $network $syslog
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: starts the unicorn web server
# Description:       starts unicorn
### END INIT INFO

PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
DAEMON=/home/app/.rvm/gems/ruby-1.9.2-p0/bin/unicorn_rails
DAEMON_OPTS="-c /usr/apps/social/current/config/unicorn.rb -E production -D"
NAME=unicorn_rails
DESC=unicorn_rails
PID=/usr/apps/social/shared/pids/unicorn.pid

case "$1" in
  start)
	echo -n "Starting $DESC: "
	$DAEMON $DAEMON_OPTS
	echo "$NAME."
	;;
  stop)
	echo -n "Stopping $DESC: "
        kill -QUIT `cat $PID`
	echo "$NAME."
	;;
  restart)
	echo -n "Restarting $DESC: "
        kill -QUIT `cat $PID`
	sleep 1
	$DAEMON $DAEMON_OPTS
	echo "$NAME."
	;;
  reload)
        echo -n "Reloading $DESC configuration: "
        kill -HUP `cat $PID`
        echo "$NAME."
        ;;
  *)
	echo "Usage: $NAME {start|stop|restart|reload}" >&2
	exit 1
	;;
esac

exit 0
