#!/bin/sh
cp /tmp/code.tar.gz /usr/workspace/code.tar.gz 
cd /usr/workspace/
tar -zxf /usr/workspace/code.tar.gz -C /usr/code-start
rm /usr/workspace/code.tar.gz

set -o allexport
source /usr/code-start/.open-runtimes
set +o allexport

cp -r /usr/code-start/vendor /usr/local/src/vendor
cd /usr/local/src/
php server.php