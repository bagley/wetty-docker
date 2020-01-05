#!/bin/bash

_check() {
	if [ $? -eq 0 ] ; then
		echo "$2 Succeeded"
	else
		echo "$2 Failed"
    _errout
	fi
}

_cleanup() {
	if [ -n "$docker_compose_file" ] ; then
		rm -f $docker_compose_file
	fi
}

_test_show_debug() {
	echo "Debug:"
	$docker_compose ps
	$docker_compose logs --tail 10
}

_errout() {
	_cleanup
	exit 1
}

_build() {

	if ! [ -f Dockerfile ] || ! [ -f Dockerfile-ssh ] ; then
		echo "Failed to find both Dockerfiles. Exiting"
		exit 1
	fi

  tag=latest
	[ $test -eq 1 ] && tag=test

	echo "Building WeTTy:$tag"
	docker build $cache --pull=true -f Dockerfile-ssh -t mydigitalwalk/wetty-ssh:$tag .
	_check $? "Building WeTTY-ssh"

  echo "Building WeTTy SSH:$tag"
	docker build $cache --pull=true -f Dockerfile -t mydigitalwalk/wetty:$tag .
	_check $? "Building WeTTy"

	[ $test -eq 1 ] && _test
}

_upload() {
	echo "Pushing WeTTy"
	docker push mydigitalwalk/wetty:latest
	_check $? "Pushing WeTTy"

	echo "Pushing WeTTy-ssh"
	docker push mydigitalwalk/wetty-ssh:latest
	_check $? "Pushing WeTTy-ssh"
}

_test() {
	echo "Setting up for test"
	docker_compose_file=test-docker-compose.yml
	rm -f $docker_compose_file
	docker_compose="docker-compose -f $docker_compose_file --project-name testwetty"
	cp docker-compose.yml $docker_compose_file || _errout "Failed to copy to $docker_compose_file"
	sed -i "s|mydigitalwalk/wetty:latest|mydigitalwalk/wetty:test|g" $docker_compose_file
	sed -i "s|mydigitalwalk/wetty-ssh:latest|mydigitalwalk/wetty-ssh:test|g" $docker_compose_file
	sed -i "s|wetty_ssh-data|testwetty_ssh-data|g" $docker_compose_file
	sed -i "s|wetty-data|testwetty-data|g" $docker_compose_file
	sed -i "s|SSHHOST: 'wetty-ssh'|SSHHOST: 'testwetty-ssh'|g" $docker_compose_file
	sed -i "s|container_name: 'wetty-ssh'|container_name: 'testwetty-ssh'|g" $docker_compose_file
	sed -i "s|container_name: wetty|container_name: testwetty|g" $docker_compose_file
	sed -i "s|  wetty:|  testwetty:|g" $docker_compose_file
	sed -i "s|  wetty-ssh:|  testwetty-ssh:|g" $docker_compose_file
	sed -i "s|  - .env|  - .env.example|g" $docker_compose_file
	sed -i "s|traefik.backend=wetty|traefik.backend=testwetty|g" $docker_compose_file
  # sed -i "s|- default|- testdefault|g" $docker_compose_file

  [ -f env-wetty-ssh ] || _errout "No config file found for ssh"

	$docker_compose down -v
	$docker_compose up -d
	_check $? "Starting WeTTy"
	echo "Waiting for healthy state"
	x=180
	while [ $x -gt 0 ] && [ $($docker_compose ps | grep -c 'Up (healthy)') -ne 2 ] ; do
		x=$(($x - 1))
		sleep 1
	done

	if [ $($docker_compose ps | grep -c 'Up (healthy)') -ne 2 ] ; then
    _test_show_debug
		$docker_compose down -v
		_errout "Failed to start app"
	fi
	# give it time to run for a bit
	sleep 30

	echo Starting tests
  . .env
	#. env-wetty-ssh
	echo "Checking WeTTy"
	$docker_compose exec -T testwetty curl --fail --insecure -sS https://localhost:3000${BASEURL} > /dev/null
	_check $? "Checking WeTTy"
	$docker_compose exec -T testwetty-ssh /healthcheck | grep "SSH is available"
  _check $? "Checking WeTTy SSH"

  echo Checking for errors in log
	if [ -n "$(docker-compose logs | grep -i Error)" ] ; then
		echo Found the following errors:
		docker-compose logs | grep -i Error
		_test_show_debug
		$docker_compose down -v
		_errout "Found errors in log"
	fi
	# take them down
	$docker_compose down -v
	_cleanup

	# retag test
	echo "Tests passed. Tagging it as latest"
	docker tag mydigitalwalk/wetty:test mydigitalwalk/wetty:latest
	docker tag mydigitalwalk/wetty-ssh:test mydigitalwalk/wetty-ssh:latest

  docker rmi mydigitalwalk/wetty:test
	docker rmi mydigitalwalk/wetty-ssh:test
}

_update() {
	git pull
	git submodule update --init --recursive
}

_help() {
	echo "Usage: $0 [publish|build|upload|update] -t (test) -f (force build without cache)"
  exit 1
}

action=""
test=0
cache=""
for each in $@ ; do
  case $each in
	  publish) action=publish ;;
	  upload)  action=upload ;;
	  update)  action=update ;;
	  build)   action=build ;;
		-t) 		 test=1 ;;
		-f)      cache="--no-cache" ;;
	  *) _help ;;
	esac
done


case $action in

	publish)
    _build
		_upload
		;;

	upload)
		_upload
		;;

	update)
		_update
		;;

	build)
		_build
		;;

	*) _help ;;

esac
