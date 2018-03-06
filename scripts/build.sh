#!/bin/bash
set -e
set -x

# For circleci

source scripts/functions.sh

startZero &
start &
testing 

#./gradlew check jacocoTestReport coveralls

quit 0