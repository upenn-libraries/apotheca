# Global Build Args ----------------------------------
# Bundle home
ARG BUNDLE_HOME=vendor/bundle

# Image tag
ARG IMAGE_TAG=3.2.5-slim-bookworm

# The root of our app
ARG PROJECT_ROOT=/home/app

# Rails env
ARG RAILS_ENV=development


# Build Stage ----------------------------------------
FROM ruby:${IMAGE_TAG} AS base

ARG RUBY_MAJOR
ENV RUBY_MAJOR=3.2.0

ARG BUNDLE_HOME
ENV BUNDLE_HOME=${BUNDLE_HOME}

ARG PROJECT_ROOT
ENV PROJECT_ROOT=${PROJECT_ROOT}

ARG RAILS_ENV=development
ENV RAILS_ENV=${RAILS_ENV}

ENV BUNDLE_APP_CONFIG="${PROJECT_ROOT}/.bundle"

WORKDIR ${PROJECT_ROOT}

# Install build packages
RUN apt-get update && apt-get install -y \
      build-essential \
      ffmpeg \
      git \
      libpq-dev \
      libvips \
      clamav \
      clamav-daemon \
      clamdscan \
      postgresql \
      postgresql-contrib && \
    rm -rf /var/lib/apt/lists/*

COPY Gemfile* ./

RUN bundle config path ${PROJECT_ROOT}/${BUNDLE_HOME} && \
    set -eux; \
    if [ "${RAILS_ENV}" = "development" ]; then \
    bundle config set with "development:test:assets"; \
    else \
    bundle config set without "development:test:assets"; \
    fi && \
    MAKE="make -j $(nproc)" bundle install && \
    rm -rf ${PROJECT_ROOT}/${BUNDLE_HOME}/ruby/${RUBY_MAJOR}/cache/*.gem && \
    find ${PROJECT_ROOT}/${BUNDLE_HOME}/ruby/${RUBY_MAJOR}/gems/ \( -name "*.c" -o -name "*.o" \) -delete

COPY . .


# Development Stage ----------------------------------
FROM ruby:${IMAGE_TAG} AS development

ARG RUBY_MAJOR
ENV RUBY_MAJOR=3.2.0

ARG BUNDLE_HOME
ENV BUNDLE_HOME=${BUNDLE_HOME}

ARG PROJECT_ROOT
ENV PROJECT_ROOT=${PROJECT_ROOT}

ARG RAILS_ENV=development
ENV RAILS_ENV=${RAILS_ENV}

# Set Rails env
ENV BUNDLE_APP_CONFIG="${PROJECT_ROOT}/.bundle"
ENV GEM_HOME="${PROJECT_ROOT}/${BUNDLE_HOME}/ruby/${RUBY_MAJOR}/"
ENV GEM_PATH="${PROJECT_ROOT}/${BUNDLE_HOME}/ruby/${RUBY_MAJOR}/"
ENV NLS_LANG=$LANG
ENV PATH="${PROJECT_ROOT}/${BUNDLE_HOME}/ruby/${RUBY_MAJOR}/bin:${PATH}"

WORKDIR ${PROJECT_ROOT}

RUN apt-get update && apt-get install -y \
      build-essential \
      curl \
      ffmpeg \
      git \
      gosu \
      libpq-dev \
      libvips \
      nodejs \
      clamav \
      clamav-daemon \
      clamdscan \
      postgresql \
      postgresql-contrib && \
    addgroup app && useradd -m -d ${PROJECT_ROOT} -s /bin/bash -g app app && \
    mkdir -p ${PROJECT_ROOT}/tmp/pids && \
    rm -rf /var/lib/apt/lists/*

COPY --chown=app:app --chmod=755 --from=base ${PROJECT_ROOT}/docker-entrypoint.sh /usr/local/bin/

COPY --chown=app:app --chmod=644 --from=base ${PROJECT_ROOT} ${PROJECT_ROOT}

RUN mkdir -p ${PROJECT_ROOT}/app/assets/builds/ && \
  SECRET_KEY_BASE=x bundle exec rake assets:precompile && \
  find . -type d -exec chmod 755 {} + && \
  chmod 744 -R ./bin && \
  chmod +x -R ${PROJECT_ROOT}/${BUNDLE_HOME}/ruby/${RUBY_MAJOR}/bin/

ENTRYPOINT ["docker-entrypoint.sh"]

EXPOSE 3000
VOLUME ${PROJECT_ROOT}

CMD ["bundle", "exec", "puma", "-b", "tcp://0.0.0.0:3000"]


# Production Stage -----------------------------------
FROM ruby:${IMAGE_TAG} AS production

ARG RUBY_MAJOR
ENV RUBY_MAJOR=3.2.0

ARG BUNDLE_HOME
ENV BUNDLE_HOME=${BUNDLE_HOME}

ARG PROJECT_ROOT
ENV PROJECT_ROOT=${PROJECT_ROOT}

ARG RAILS_ENV=production
ENV RAILS_ENV=${RAILS_ENV}

# Set Rails env
ENV BUNDLE_APP_CONFIG="${PROJECT_ROOT}/.bundle"
ENV GEM_HOME="${PROJECT_ROOT}/${BUNDLE_HOME}/ruby/${RUBY_MAJOR}/"
ENV GEM_PATH="${PROJECT_ROOT}/${BUNDLE_HOME}/ruby/${RUBY_MAJOR}/"
ENV NLS_LANG=$LANG
ENV PATH="${PROJECT_ROOT}/${BUNDLE_HOME}/ruby/${RUBY_MAJOR}/bin:${PATH}"
ENV RAILS_LOG_TO_STDOUT=true
ENV RAILS_SERVE_STATIC_FILES=true

WORKDIR ${PROJECT_ROOT}

RUN apt-get update && apt-get install -y \
      build-essential \
      curl \
      ffmpeg \
      git \
      gosu \
      libpq-dev \
      libvips \
      nodejs \
      clamav \
      clamav-daemon \
      clamdscan \
      postgresql \
      postgresql-contrib && \
    addgroup app && useradd -m -d ${PROJECT_ROOT} -s /bin/bash -g app app && \
    mkdir -p ${PROJECT_ROOT}/tmp/pids && \
    rm -rf /var/lib/apt/lists/*

COPY --chown=app:app --chmod=755 --from=base ${PROJECT_ROOT}/docker-entrypoint.sh /usr/local/bin/

COPY --chown=app:app --chmod=644 --from=base ${PROJECT_ROOT} ${PROJECT_ROOT}

RUN mkdir -p ${PROJECT_ROOT}/app/assets/builds/ && \
    SECRET_KEY_BASE=x bundle exec rake assets:precompile && \
    find . -type d -exec chmod 755 {} + && \
    chmod 744 -R ./bin && \
    chmod +x -R ${PROJECT_ROOT}/${BUNDLE_HOME}/ruby/${RUBY_MAJOR}/bin/

ENTRYPOINT ["docker-entrypoint.sh"]

EXPOSE 3000
VOLUME ${PROJECT_ROOT}

CMD ["bundle", "exec", "puma", "-b", "tcp://0.0.0.0:3000"]
