#!/bin/bash
set -e
set -x

# For semaphoreci
# Current obsolete.
# Using direct commands
source scripts/functions.sh

startZero &
start &

#./gradlew check jacocoTestReport coveralls

# quit 0