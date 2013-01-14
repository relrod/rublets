#!/bin/bash

# We do SML evaluations this way so that we can force CM_VERBOSE=false.
# The inability to set environment variables is a limitation of `sandbox`, not
# of Ruby or Rublets. If we can figure out a way to set envrionment variables
# from `sandbox`, we can probably relatively easily use that from Rublets.
export CM_VERBOSE=false
sml $1
