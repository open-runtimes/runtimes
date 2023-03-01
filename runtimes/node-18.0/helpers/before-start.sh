#!/bin/sh
echo "Preparing for start ..."

# Extract gzipped code from mounted volume to function folder
tar -zxf /mnt/code/code.tar.gz -C /usr/local/server/src/function

# Apply env vars from build step
set -o allexport
source /usr/local/server/src/function/.open-runtimes
set +o allexport

# Prepare empty node_modules to prevent errors with copying
mkdir -p /usr/local/server/src/function/node_modules

# Merge user's node_modules into server's node_modules
setopt no_nomatch
cp -R /usr/local/server/src/function/node_modules/* /usr/local/server/node_modules
setopt nomatch

# Enter server folder
cd /usr/local/server

echo 'Starting ...'