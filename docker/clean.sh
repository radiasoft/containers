#!/bin/bash
docker rm $(docker ps -aq)
docker rmi $(docker images --filter dangling=true -q)
