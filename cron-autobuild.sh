#!/bin/bash

# Remember to cd to this dir before running.
# 0 * * * *   root   cd /path/to/wetty-repo && bash cron-autobuild.sh

config=cron-autobuild.conf
log=cron-autobuild.log
if ! [ -f $config ] ; then
	echo "Failed to find config file $config. Exiting"
	exit 1
fi
. $config
exit_code=0
echo > "$log"

if [ -n "$update_as_user" ] ; then
	su $update_as_user -c "bash autobuild.sh update" >> "$log" 2>&1
	exit_code=$(( $exit_code + $? ))
else
	bash autobuild.sh update >> "$log" 2>&1
	exit_code=$(( $exit_code + $? ))
fi

bash autobuild.sh publish -t >> "$log" 2>&1
exit_code=$(( $exit_code + $? ))

echo "Images:"  >> "$log" 2>&1
docker images | grep mydigitalwalk/wetty  >> "$log" 2>&1

if [ $exit_code -eq 0 ] ; then
	msg="Successfully built and published wetty"
	if [ -z "$email" ] || [ "$email" == "always" ] ; then
		cat "$log" | mail -s "$msg" root
	fi
else
	msg="FAILED to build/publish wetty. Exit code $exit_code"
	cat "$log" | mail -s "$msg" root
fi
