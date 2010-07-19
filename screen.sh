#!/usr/bin/env bash

DIR=$(dirname $(readlink -f $0))

CONF="$DIR/$1"

if [ "$CONF" == "" ]; then
  CONF="$DIR/config.yaml"
fi

screen -dmS rubino $DIR/rubino.rb $CONF
