# Alces Concertim Visualisation App

## Overview

Concertim Visualisation App allows visualising devices and their reported metrics.

![racks with metrics](images/racks-with-metrics.png)


## Quick start

1. Clone the repository
    ```bash
    git clone https://github.com/openflighthpc/concertim-ct-visualisation-app.git
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
    git clone https://github.com/openflighthpc/concertim-ct-visualisation-app.git
    ```
2. Build the docker image
    ```bash
    docker build --network=host --tag concertim-visualisation:latest .
    ```

## Usage

Racks and devices can be added and removed using the rack and device API.  Once
devices have been added, metrics can be reported for those devices using the
[metric reporting
daemon](https://github.com/openflighthpc/concertim-metric-reporting-daemon).

This repo contains [rack and device API example scripts](docs/api/examples).
The metric reporting daemon repository has its own [metric API example
scripts](https://github.com/openflighthpc/concertim-metric-reporting-daemon/tree/main/docs/examples).

Once metrics have been reported they can be visualised using the interactive
rack view which runs in a browser.

## Development

See the [development docs](docs/DEVELOPMENT.md) for details on development and
getting started with development.

## Deployment

Concertim Visualisation App is deployed as part of the Concertim appliance
using the [Concertim ansible
playbook](https://github.com/openflighthpc/concertim-ansible-playbook).

# Contributing

Fork the project. Make your feature addition or bug fix. Send a pull
request. Bonus points for topic branches.

Read [CONTRIBUTING.md](CONTRIBUTING.md) for more details.

# Copyright and License

Eclipse Public License 2.0, see [LICENSE.txt](LICENSE.txt) for details.

Copyright (C) 2024-present Alces Flight Ltd.

This program and the accompanying materials are made available under
the terms of the Eclipse Public License 2.0 which is available at
[https://www.eclipse.org/legal/epl-2.0](https://www.eclipse.org/legal/epl-2.0),
or alternative license terms made available by Alces Flight Ltd -
please direct inquiries about licensing to
[licensing@alces-flight.com](mailto:licensing@alces-flight.com).

Concertim Visualisation App is distributed in the hope that it will be
useful, but WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, EITHER
EXPRESS OR IMPLIED INCLUDING, WITHOUT LIMITATION, ANY WARRANTIES OR
CONDITIONS OF TITLE, NON-INFRINGEMENT, MERCHANTABILITY OR FITNESS FOR
A PARTICULAR PURPOSE. See the [Eclipse Public License 2.0](https://opensource.org/licenses/EPL-2.0) for more
details.
