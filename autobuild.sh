#!/bin/bash

_check() {
	if [ $? -eq 0 ] ; then
		echo "$2 Succeeded"
	else
		echo "$2 Failed"
	fi
}

_build() {

	if ! [ -f Dockerfile ] || ! [ -f Dockerfile-ssh ] ; then
		echo "Failed to find both Dockerfiles. Exiting"
		exit 1
	fi

	docker build --pull=true -f Dockerfile-ssh -t mydigitalwalk/wetty-ssh:latest .
	_check $? "Building WeTTY-ssh"

	docker build --pull=true -f Dockerfile -t mydigitalwalk/wetty:latest .
	_check $? "Building WeTTy"
}

_upload() {
	echo "Pushing WeTTy"
	docker push mydigitalwalk/wetty:latest
	_check $? "Pushing WeTTy"
	echo "Pushing WeTTy-ssh"
	docker push mydigitalwalk/wetty-ssh:latest
	_check $? "Pushing WeTTy-ssh"
}

case $1 in

	publish)
		_build
		_upload
		;;

	upload)
		_upload
		;;

	*)
		_build
		;;
esac		

