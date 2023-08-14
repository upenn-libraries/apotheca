# Apotheca

## Overview
Apotheca is the administrative application that enables the ingestion and management of digital assets. This repository includes the infrastructure and application code that supports Apotheca.

Development occurs within a robust vagrant environment. Setup and initialization of this environment, as well as information about the deployed staging and production environments, is contained here.

Information about the Rails application can be found [here](rails_app/README.md).

## Development

> Caveat: The vagrant development environment has only been tested in the local environments our developers currently have. This currently includes Linux, Intel-based Macs and M1 Macs.

In order to use the integrated development environment you will need to install [Vagrant](https://www.vagrantup.com/docs/installation) [do *not* use the Vagrant version that may be available for your distro repository - explicitly follow instructions at the Vagrant homepage] and the appropriate virtualization software. If you are running Linux or Mac x86 then install [VirtualBox](https://www.virtualbox.org/wiki/Linux_Downloads), if you are using a Mac with ARM processors then install [Parallels](https://www.parallels.com/).

You may need to update the VirtualBox configuration for the creation of a host-only network. This can be done by creating a file `/etc/vbox/networks.conf` containing:

```
* 10.0.0.0/8
```

#### Starting

From the [vagrant](vagrant) directory run:


if running with Virtualbox:
```
vagrant up --provision
```

if running with Parallels:
```
vagrant up --provider=parallels --provision
```

This will run the [vagrant/Vagrantfile](vagrant/Vagrantfile) which will bring up an Ubuntu VM and run the Ansible script which will provision a single node Docker Swarm behind nginx with a self-signed certificate to mimic a load balancer. Your hosts file will be modified; the domain `apotheca-dev.library.upenn.edu` will be added and mapped to the Ubuntu VM. Once the Ansible script has completed and the Docker Swarm is deployed you can access the application by navigating to [https://apotheca-dev.library.upenn.edu](https://apotheca-dev.library.upenn.edu).

#### Stopping

To stop the development environment, from the `vagrant` directory run:

```
vagrant halt
```

#### Destroying

To destroy the development environment, from the `vagrant` directory run:

```
vagrant destroy -f
```

#### SSH

You may ssh into the Vagrant VM by running:

```
vagrant ssh
```

#### Traefik

When running the development environment you can access the traefik web ui by navigating to: [https://traefik-dev.library.upenn.edu:8080/#](https://traefik-dev.library.upenn.edu:8080/#).


#### Rails Application
For information about the Rails application, see the [README](/rails_app/README.md) in the Rails application root. This includes information about running the test suite, performing harvesting, development styleguide and general application information.

#### Minio
In development, Minio is used to mimic S3-compatible object storage. In staging/production, the application will use an external service like AWS S3, Wasabi, etc.

The Minio API is available at [http://minio-dev.library.upenn.edu](http://minio-dev.library.upenn.edu).

To access the Minio UI, navigate to [http://minio-console-dev.library.upenn.edu/](http://minio-console-dev.library.upenn.edu/) and log-in as the `minioadmin` user with the password `minioadmin`.

#### Solr
Solr is running in [CloudMode](https://solr.apache.org/guide/solr/latest/deployment-guide/cluster-types.html#solrcloud-mode) which uses Apache Zookeeper to provide centralized cluster management. Additionally, [ZooNavigator](https://github.com/elkozmon/zoonavigator) is used to manage the Zookeeper cluster in deployed environments.

To access the Solr Admin UI, navigate to: [http://apotheca-dev.library.upenn.int/solr1/#/](http://apotheca-dev.library.upenn.int/solr1/#/)

#### Chrome
To access browserless Chrome, go to: [http://apotheca-dev.library.upenn.int:3333/](http://apotheca-dev.library.upenn.int:3333/)

## Deployment (WIP)
Gitlab automatically deploys to both our staging and production environment under certain conditions.

### Staging (WIP)
Gitlab deploys to our staging server every time new code gets merged into `main`. The staging site is available at [https://apotheca-staging.library.upenn.edu/](https://apotheca-staging.library.upenn.edu/).

Code cannot be pushed directly onto `main`, new code must be merged via a merge request.

### Production (WIP)
Deployments are triggered when a new git tag is created that matches [semantic versioning](https://semver.org/), (e.g., v1.0.0). Git tags should be created via the creation of a new Release in Gitlab.

In order to deploy to production:
1. Go to [https://gitlab.library.upenn.edu/dld/apotheca/-/releases/new](https://gitlab.library.upenn.edu/dld/apotheca/-/releases/new)
2. Create a new tag that follows semantic versioning. Please use the next tag in the sequence.
3. Relate a milestone to the release if there is one.
4. Add a release title that is the same as the tag name.
5. Submit by clicking "Create Release".

The production site is available at [https://apotheca.library.upenn.edu/](https://apotheca.library.upenn.edu/).
