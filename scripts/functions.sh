#!/bin/bash


sleepTime=15

function quit {
  echo "🛠 Shutting down dgraph server and zero"
  curl -s localhost:8080/admin/shutdown
  # Kill Dgraphzero
  kill -9 $(pgrep -f "dgraph zero") > /dev/null

  if pgrep -x dgraph > /dev/null
  then
    while pgrep dgraph;
    do
      echo "😴💤 Sleeping for 5 secs so that Dgraph can shutdown."
      sleep 5
    done
  fi

  echo "Clean shutdown done."
  return $1
}

function start {
  echo "😴💤 Sleeping"
	sleep 60
  echo -e "🛠 Starting first server."
  # dgraph v1.0.3 ports changed 
  #dgraph server --memory_mb 2048 --zero localhost:5082 -o 2
  dgraph server --memory_mb 2048 --zero localhost:3080 -o 2
  # Wait for membership sync to happen.
  
  sleep $sleepTime
  echo -e "🛠 dgraph zero is started ------------------------------------- \n"
  return 0
}

function startZero {
  
	echo -e "🛠 Starting dgraph zero.\n"
  dgraph zero --port_offset -2000
  # To ensure dgraph doesn't start before dgraphzero.
	# It takes time for zero to start on travis(mac).

  echo "😴💤 Sleeping"
	sleep $sleepTime
  echo -e "🛠 dgraph zero is started ------------3------------------------- \n"
}

function testing {
  echo -e "Testing."
  
  # Wait for membership sync to happen.
  echo "😴💤 Sleeping"
  sleep $sleepTime
  echo "😴💤 Sleeping"
  sleep $sleepTime
  mix local.rebar --force
  mix local.hex --force
  mix deps.get
  mix deps.compile
  mix test
  echo "--------------------------------------------"
  mix coveralls.json
  echo "--------------------------------------------"
  echo "--------------------Circle CI------------------------"
  bash <(curl -s https://codecov.io/bash)
  # mix coveralls.circle
  # mix inch.report
  echo -e "Finnished Testing --------------------------------------------"
  return 0
}
