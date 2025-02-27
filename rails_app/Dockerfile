# Global Build Args ----------------------------------
# Image name
ARG IMAGE_NAME=gitlab.library.upenn.edu/dld/digital-repository/apotheca-base-image

# Image tag
ARG IMAGE_TAG=cf508da3

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

WORKDIR ${PROJECT_ROOT}

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
FROM base AS development

ARG RAILS_ENV=development
ENV RAILS_ENV=${RAILS_ENV}

COPY --chown=app:app --chmod=755 --from=base ${PROJECT_ROOT}/docker-entrypoint.sh /usr/local/bin/
COPY --chown=app:app --chmod=644 --from=base ${PROJECT_ROOT} ${PROJECT_ROOT}

RUN SECRET_KEY_BASE=x bundle exec rake assets:precompile && \
    find . -type d -exec chmod 755 {} + && \
    chmod 744 -R ./bin && \
    chmod +x -R ${PROJECT_ROOT}/${BUNDLE_HOME}/ruby/${RUBY_MAJOR}/bin/

# Production Stage -----------------------------------
FROM base AS production

ARG RAILS_ENV=production
ENV RAILS_ENV=${RAILS_ENV}

# Set Rails env
ENV RAILS_LOG_TO_STDOUT=true
ENV RAILS_SERVE_STATIC_FILES=true

COPY --chown=app:app --chmod=755 --from=base ${PROJECT_ROOT}/docker-entrypoint.sh /usr/local/bin/
COPY --chown=app:app --chmod=644 --from=base ${PROJECT_ROOT} ${PROJECT_ROOT}

RUN SECRET_KEY_BASE=x bundle exec rake assets:precompile && \
    find . -type d -exec chmod 755 {} + && \
    chmod 744 -R ./bin && \
    chmod +x -R ${PROJECT_ROOT}/${BUNDLE_HOME}/ruby/${RUBY_MAJOR}/bin/
