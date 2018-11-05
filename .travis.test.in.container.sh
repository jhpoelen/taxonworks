#!/bin/bash
set -x
set -e

# attempt to install firefox and X virtual framebuffer for headless ui testing
export DISPLAY=:99.0
/sbin/start-stop-daemon --start --quiet --pidfile /tmp/custom_xvfb_99.pid --make-pidfile --background --exec /usr/bin/Xvfb -- :99 -ac -screen 0 1600x1200x16

cat config/database.yml
cat config/secrets.yml
cat Gemfile.lock

mkdir -p tmp/
mkdir -p tmp/downloads
export RAILS_ENV=test
bundle exec rake db:create 
bundle exec rake db:migrate
npm install
# make sure to install test dependencies
# see https://stackoverflow.com/a/4143287
rm .bundle/config
bundle install --without development production
npm run webpack-test
ls -alh bin 
ls -alh public/packs-test 
bundle exec rake assets:precompile
bundle exec rspec --format documentation
