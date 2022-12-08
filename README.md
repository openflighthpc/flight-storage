# Flight Storage

Command-line cloud storage interaction.

## Overview

Flight Storage is a command-line tool for interacting with cloud storage solutions. It acts as a wrapper for various cloud providers' object storage technologies, with uniform CRUD controls across each of them.

## Installation

### Manual installation

#### Prerequisites
Flight Profile is developed and tested with Ruby version 2.7.1 and bundler 2.1.4. Other versions may work but currently are not officially supported.

#### Steps

The following will install from source using Git. The `master` branch is the current development version and may not be appropriate for a production installation. Instead a tagged version should be checked out.

```bash
git clone https://github.com/openflighthpc/flight-storage.git
cd flight-storage
git checkout <tag>
bundle install --path=vendor
```

## Configuration

`storage avail` will list the available storage providers. Run `bin/storage set` (source) / `flight storage set` (package) to choose your cloud storage provider.

Flight Storage currently supports the following cloud storage providers:

- Amazon S3 ([setup](docs/aws_s3.md))
- Azure File Service ([setup](docs/azure.md))
- Dropbox ([setup](docs/dropbox.md))

Please follow the setup guide for your chosen provider.

## Operation

A brief usage guide is given here. See the `help` command for more in depth details and information specific to each command.

List the topmost directory in cloud with `storage list`. List more specific subdirectories by providing the path to the subdirectory as an argument.

Upload a file to the cloud with `storage push FILE`. Absolute paths and relative paths are both accepted when specifying a file. Upload the file to a more specific subdirectory by providing the target directory as a second (optional) argument.

Download a remote file to your system with `storage pull FILE`. An absolute path to the remote file is required. By default, the file is downloaded to your current working directory. You may specify a target directory by providing the target directory as a second (optional) argument (absolute/relative paths accepted).

Delete a file from the cloud with `storage delete FILE`.

# Contributing

Fork the project. Make your feature addition or bug fix. Send a pull
request. Bonus points for topic branches.

Read [CONTRIBUTING.md](CONTRIBUTING.md) for more details.

# Copyright and License

Eclipse Public License 2.0, see [LICENSE.txt](LICENSE.txt) for details.

Copyright (C) 2022-present Alces Flight Ltd.

This program and the accompanying materials are made available under
the terms of the Eclipse Public License 2.0 which is available at
[https://www.eclipse.org/legal/epl-2.0](https://www.eclipse.org/legal/epl-2.0),
or alternative license terms made available by Alces Flight Ltd -
please direct inquiries about licensing to
[licensing@alces-flight.com](mailto:licensing@alces-flight.com).

Flight Storage is distributed in the hope that it will be
useful, but WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, EITHER
EXPRESS OR IMPLIED INCLUDING, WITHOUT LIMITATION, ANY WARRANTIES OR
CONDITIONS OF TITLE, NON-INFRINGEMENT, MERCHANTABILITY OR FITNESS FOR
A PARTICULAR PURPOSE. See the [Eclipse Public License 2.0](https://opensource.org/licenses/EPL-2.0) for more
details.
