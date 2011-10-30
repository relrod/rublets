#!/usr/bin/env bash

DIR=$(dirname $(readlink -f $0))

CONF="$DIR/$1"

if [ ! -f "$CONF" ]; then
  CONF="$DIR/config.yaml"
fi

if [ ! -f "$CONF" ]; then
  echo "Config does not exist."
  exit 1
fi

screen -dmS rubino $DIR/rubino.rb $CONF
