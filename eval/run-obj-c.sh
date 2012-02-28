#!/bin/bash
gcc -Wall -x objective-c -framework Foundation $1 && ./a.out
