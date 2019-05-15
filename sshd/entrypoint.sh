#!/bin/bash

set -eo pipefail
IFS=$'\n\t'

# set -x

export DEBIAN_FRONTEND=noninteractive

# _check_var VAR $VAR
_check_var() {
	if [ -z "$2" ] ; then
		_err "$1 is not specified. Please set this as a docker environment variable. Exiting."
	fi
}
_err() {
	echo $1
	exit 5
}

# sanity checks

[ -z "$WETTY_USER" ] && WETTY_USER=term
echo "Username: $WETTY_USER"

_check_var WETTY_PASSWORD "$WETTY_PASSWORD"
echo "Password: $WETTY_PASSWORD"

if [ -n "$SSHHOST" ] ; then
	_check_var SSHUSER "$SSHUSER"
	[ -n "$SSHPORT" ] && SSHPORT="-p $SSHPORT"
	echo "WeTTY (after login) will connect to: ssh $SSHPORT $SSHUSER@$SSHHOST"
else
	echo "WARNING: SSHHOST was not specified, so no ForceCommand will not be set."
	echo "Once anyone successfully logs into wetty, they will have a full shell. Just fyi."
fi

if [ -z "$(mount | grep /data)" ] ; then
	echo "Warning: /data does not appear to be mounted. If this is not mounted, saved ssh keys will not persist across container recreations, which could lead to a 'Mismatched key' error on SSH, where it correctly sees that the container's key has changed, and won't let you login because it thinks someone is messing with you connection."
	echo "Please mount a volume to /data."
fi

# wetty does not work with google auth
#if ! [ -f /data/.google_authenticator ] ; then
#	_err "No .google_authenticator file found in the data folder! Exiting"
#fi

# setup user
tag_file=/root/user-setup-complete
if ! [ -f $tag_file ] ; then

	useradd -m $WETTY_USER -u 1000
	echo "$WETTY_USER:$WETTY_PASSWORD" | chpasswd

	mkdir -p /home/$WETTY_USER/.ssh
	chown 1000:1000 /home/$WETTY_USER/.ssh
	[ -f /data/known_hosts ] || touch /data/known_hosts
	chmod 644 /data/known_hosts
	chown 1000:1000 /data/known_hosts
	rm -f /home/$WETTY_USER/.ssh/known_hosts
	ln -s /data/known_hosts /home/$WETTY_USER/.ssh/known_hosts

#	cp -a /data/.google_authenticator /home/$WETTY_USER/.google_authenticator
#	chown $WETTY_USER /home/$WETTY_USER/.google_authenticator
#	chmod 400 /home/$WETTY_USER/.google_authenticator

	touch $tag_file

fi

sshd_tag=/root/sshd-forcecommand-set
if [ -n "$SSHHOST" ] && ! [ -f $sshd_tag ] ; then

	# set these as a 'just in case', but only if ForceCommand will be used
	echo "exit" >> /home/$WETTY_USER/.bashrc
	echo "exit" >> /home/$WETTY_USER/.profile
	
	# final settings on sshd
	cat << EOF >> /etc/ssh/sshd_config

AllowUsers $WETTY_USER
Match User $WETTY_USER
       ForceCommand ssh $SSHPORT $SSHUSER@$SSHHOST

EOF

	if [ -n "$(ls /data/sshd_keys/ssh_host_*)" ] ; then
		echo "Copying ssh server keys from data folder..."
		rm -f /etc/ssh/ssh_host_*
		cp -a /data/sshd_keys/ssh_host_* /etc/ssh/
		chmod 600 /etc/ssh/ssh_host_*
		chmod 644 /etc/ssh/ssh_host_*.pub
	else
		echo "No backup ssh keys were found. Creating new ones..."
		rm -f /etc/ssh/ssh_host_*
		dpkg-reconfigure openssh-server
		mkdir -p /data/sshd_keys
		chmod 700 /data/sshd_keys
		echo "Copying to data folder"
		cp -a /etc/ssh/ssh_host_* /data/sshd_keys/
	fi
	echo "Done"

	touch $sshd_tag
fi

/usr/sbin/sshd -t
if [ $? -ne 0 ] ; then
	echo "Error in SSH config file. Exiting"
	exit 1
fi

/usr/sbin/sshd -D -e

