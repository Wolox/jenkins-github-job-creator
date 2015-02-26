#!/bin/bash
#
# Written by Patrick McKenzie, 2010.
# I release this work unto the public domain.
#
# sinatra      Startup script for Sinatra server.
# description: Starts Sinatra as an unprivileged user.
#

sudo -u www-data irb /var/lib/jenkins/wolox-jenkins-github-authorize/authorize.rb $1
RETVAL=$?

exit $RETVAL
