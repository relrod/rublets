#!/bin/bash
version="$1"
if [ "$version" == "1.8" ]; then
  export PATH=/usr/lib/jvm/java-1.8.0/bin/:$PATH
fi
javac Rublets.java && java Rublets
