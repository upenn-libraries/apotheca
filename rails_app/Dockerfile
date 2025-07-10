# Global Build Args ----------------------------------
# Image name
ARG IMAGE_NAME=gitlab.library.upenn.edu/dld/digital-repository/apotheca-base-image

# Image tag
ARG IMAGE_TAG=0a816cf7

# Rails env
ARG RAILS_ENV=development


# Build Stage ----------------------------------------
FROM ${IMAGE_NAME}:${IMAGE_TAG} AS base

ARG RUBY_MAJOR
ENV RUBY_MAJOR=3.4.0

ARG BUNDLE_HOME
ENV BUNDLE_HOME=${BUNDLE_HOME}

ARG PROJECT_ROOT
ENV PROJECT_ROOT=${PROJECT_ROOT}

ARG RAILS_ENV=development
ENV RAILS_ENV=${RAILS_ENV}

ENV BUNDLE_APP_CONFIG="${PROJECT_ROOT}/.bundle"

COPY --chown=app:app --chmod=755 ./docker-entrypoint.sh /usr/local/bin/

WORKDIR ${PROJECT_ROOT}

COPY ocr_languages.txt ./ocr_languages.txt
RUN apt-get update && apt-get install -y --no-install-recommends wget && \
    for language in $(cat ocr_languages.txt); do \
      wget "https://github.com/tesseract-ocr/tessdata_fast/raw/refs/heads/main/${language}.traineddata" \
        -O "/usr/local/share/tessdata/${language}.traineddata"; \
    done && \
    rm -rf /var/lib/apt/lists/*

COPY Gemfile* ./

RUN --mount=type=secret,id=sidekiq_pro_credentials \
    bundle config set --local gems.contribsys.com $(cat /run/secrets/sidekiq_pro_credentials)

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

RUN find . -type d -exec chmod 755 {} + && \
    chmod 744 -R ./bin && \
    chmod +x -R ${PROJECT_ROOT}/${BUNDLE_HOME}/ruby/${RUBY_MAJOR}/bin/

# Development Stage ----------------------------------
FROM base AS development

ARG RAILS_ENV=development
ENV RAILS_ENV=${RAILS_ENV}

RUN SECRET_KEY_BASE=x bundle exec rake assets:precompile

# Production Stage -----------------------------------
FROM base AS production

ARG RAILS_ENV=production
ENV RAILS_ENV=${RAILS_ENV}

# Set Rails env
ENV RAILS_LOG_TO_STDOUT=true
ENV RAILS_SERVE_STATIC_FILES=true

RUN SECRET_KEY_BASE=x bundle exec rake assets:precompile
