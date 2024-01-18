FROM ruby:3.3-bookworm

ARG BUILD_DATE
ARG BUILD_VERSION
ARG BUILD_REVISION

LABEL org.opencontainers.image.created=$BUILD_DATE
LABEL org.opencontainers.image.version=$BUILD_VERSION
LABEL org.opencontainers.image.revision=$BUILD_REVISION
LABEL org.opencontainers.image.title="Alces Concertim Visualisation App"

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update \
      && apt-get install --yes --no-install-recommends \
		  autoconf \
		  bison \
		  build-essential \
		  libpq-dev \
		  libyaml-dev \
		  tzdata \
                  ed \
                  postgresql-client-15 \
      && apt-get clean \
      && rm -Rf /usr/share/doc && rm -Rf /usr/share/man \
      && rm -rf /var/lib/apt/lists/*

WORKDIR /opt/concertim/opt/ct-visualisation-app
COPY . /opt/concertim/opt/ct-visualisation-app
COPY docker/licence-limits.yml /opt/concertim/etc/licence-limits.yml

ENV RAILS_LOG_TO_STDOUT=true
ENV PORT=7000
EXPOSE 7000
RUN ./bin/bundle install

ENTRYPOINT ["/opt/concertim/opt/ct-visualisation-app/docker/entrypoint.sh"]
