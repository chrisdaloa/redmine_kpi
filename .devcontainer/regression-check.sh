#!/bin/sh
set -ex

cd $(dirname $0)

cd ..
rubocop

cd /usr/local/redmine

bundle exec rake redmine:plugins:test
