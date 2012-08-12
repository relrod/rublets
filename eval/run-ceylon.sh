#!/bin/bash
mkdir source
cp `pwd`/$1 ./source/rublets.ceylon
ceylonc source/rublets.ceylon
ceylon -run rublets default
