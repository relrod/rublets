#!/usr/bin/env bash
# Sets up rublets' rvm directory based on the current user's ~/.rvm
# Part of the Rublets Project: https://github.com/codeblock/rublets
# (c) 2012-present   Ricky Elrod <ricky@elrod.me>
# ISC Licensed.

DIR="$( cd "$( dirname "$0" )" && pwd )"

if [[ -d "$DIR/rvm" ]]; then
  echo "Not messing with existing rvm directory. Exiting prematurely."
  exit
fi

echo "Copying `whoami`'s ~/.rvm/."
cp -r ~/.rvm/ $DIR/rvm/

echo "Removing useless files."
rm -rf $DIR/rvm/{gems,archives,examples,man,patches,patchsets,README,src,tmp,user,VERSION}

echo "Moving 'rubies' out."
mv -v $DIR/rvm/rubies/ $DIR/rubies

echo "Done."
