#!/bin/bash
set -x
set -e
nvm install node
curl -o- -L https://yarnpkg.com/install.sh | bash -s -- --version 1.7.0
export PATH=$HOME/.yarn/bin:$PATH
npm install
bundle install --without development production
"export DISPLAY=:99.0"
"/sbin/start-stop-daemon --start --quiet --pidfile /tmp/custom_xvfb_99.pid --make-pidfile --background --exec /usr/bin/Xvfb -- :99 -ac -screen 0 1600x1200x16"
sleep 3
cp config/database.yml.travis config/database.yml
cp config/secrets.yml.example config/secrets.yml
mkdir tmp/
mkdir tmp/downloads
bundle exec rake db:create RAILS_ENV=test # database user by default is `travis` 
bundle exec rake db:migrate RAILS_ENV=test
ls -alh bin 
ls -alh public/packs-test 
bundle exec rake assets:precompile
bundle exec rspec
