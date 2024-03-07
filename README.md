# Alces Concertim Visualisation App

## Overview

Concertim Visualisation App allows visualising devices and their reported metrics.

![racks with metrics](images/racks-with-metrics.png)


## Quick start

1. Clone the repository
    ```bash
    git clone https://github.com/alces-flight/concertim-ct-visualisation-app.git
    ```
2. Build the docker image
    ```bash
    docker build --network=host --tag concertim-visualisation:latest .
    ```
3. Start the docker container
    ```bash
	docker run -d --name concertim-visualisation \
		--network=host \
		concertim-visualisation
    ```

## Building the docker image

Concertim Visualisation App is intended to be deployed as a Docker container.
There is a Dockerfile in this repo for building the image.

1. Clone the repository
    ```bash
    git clone https://github.com/alces-flight/concertim-ct-visualisation-app.git
    ```
2. Build the docker image
    ```bash
    docker build --network=host --tag concertim-visualisation:latest .
    ```

## Usage

Racks and devices can be added and removed using the rack and device API.  Once
devices have been added, metrics can be reported for those devices using the
[metric reporting
daemon](https://github.com/alces-flight/concertim-metric-reporting-daemon).

This repo contains [rack and device API example scripts](docs/api/examples).
The metric reporting daemon repository has its own [metric API example
scripts](https://github.com/alces-flight/concertim-metric-reporting-daemon/tree/main/docs/examples).

Once metrics have been reported they can be visualised using the interactive
rack view which runs in a browser.

## Development

See the [development docs](docs/DEVELOPMENT.md) for details on development and
getting started with development.

## Deployment

Concertim Visualisation App is deployed as part of the Concertim appliance
using the [Concertim ansible
playbook](https://github.com/alces-flight/concertim-ansible-playbook).

## Copyright and License

Copyright (C) 2022-present Stephen F Norledge & Alces Flight Ltd.
