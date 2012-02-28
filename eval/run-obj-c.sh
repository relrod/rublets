#!/bin/bash
gcc -Wall -x objective-c -fconstant-string-class=NSConstantString -lobjc -lgnustep-base $1 && ./a.out
