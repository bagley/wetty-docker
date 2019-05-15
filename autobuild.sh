#!/bin/bash

docker build --pull=true -f Dockerfile-ssh -t mydigitalwalk/wetty-ssh:latest .

docker build --pull=true -f Dockerfile -t mydigitalwalk/wetty:latest .

