FROM ubuntu:22.04
LABEL com.alces-flight.concertim.role=visualisation

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update \
      && apt-get install --yes --no-install-recommends \
		  ruby3.0 \
		  ruby3.0-dev \
		  autoconf \
		  bison \
		  build-essential \
		  libpq-dev \
		  libyaml-dev \
		  tzdata \
                  ed \
                  postgresql-client-14 \
      && apt-get clean \
      && rm -Rf /usr/share/doc && rm -Rf /usr/share/man \
      && rm -rf /var/lib/apt/lists/*

WORKDIR /opt/concertim/opt/ct-visualisation-app
COPY . /opt/concertim/opt/ct-visualisation-app
COPY docker/licence-limits.yml /opt/concertim/etc/licence-limits.yml

ENV RAILS_ENV=production
ENV RAILS_LOG_TO_STDOUT=true
RUN ./bin/bundle install

ENTRYPOINT ["/opt/concertim/opt/ct-visualisation-app/docker/entrypoint.sh"]
EXPOSE 7000
