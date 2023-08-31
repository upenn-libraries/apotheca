#!/bin/sh
set -e

if [ "$1" = "bundle" -a "$2" = "exec" -a "$3" = "puma" ] || [ "$1" = "bundle" -a "$2" = "exec" -a "$3" = "sidekiq" ]; then
    if [ ! -z "${APP_UID}" ] && [ ! -z "${APP_GID}" ]; then
        usermod -u ${APP_UID} app
        groupmod -g ${APP_GID} app
    fi

    if [ "${RAILS_ENV}" = "development" ]; then
        bundle config --local path ${PROJECT_ROOT}/vendor/bundle
        bundle config set --local with 'development:test:assets'
        bundle install -j$(nproc) --retry 3

        # since we are running a dev env we remove node_modules and install our dependencies
        # su - app -c $(rm -rf node_modules && yarn install --no-bin-links)
    fi

    # remove puma server.pid
    if [ -f ${PROJECT_ROOT}/tmp/pids/server.pid ]; then
        rm -f ${PROJECT_ROOT}/tmp/pids/server.pid
    fi

    # run db migrations
    if [ "$1" = "bundle" -a "$2" = "exec" -a "$3" = "puma" ]; then
        bundle exec rake db:migrate

        if [ "${RAILS_ENV}" = "development" ]; then
            bundle exec rake db:create RAILS_ENV=test
            bundle exec rake db:migrate RAILS_ENV=test

            bundle exec rake apotheca:create_buckets
            bundle exec rake apotheca:create_buckets RAILS_ENV=test
        fi
    fi

    chown -R app:app .

    # run the application as the app user
    exec gosu app "$@"
fi

exec "$@"