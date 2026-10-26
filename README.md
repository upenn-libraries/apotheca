# Apotheca

Apotheca is the administrative application that enables the ingestion and management of digital assets. This repository includes the infrastructure and application code that supports Apotheca.

Information about the Rails application can be found [here](rails_app/README.md).

1. [Development Environment](#development-environment)
   - [Installing](#installing)
   - [Starting](#starting)
   - [Interacting with Environment](#interacting-with-environment)
   - [Interacting with Application](#interacting-with-application)
   - [Services](#services)
   - [Destroying](#destroying)
2. [Deployment](#deployment)

---

## Development Environment
The development environment is based on Taskfile and Docker. `task up` creates a Docker-in-Docker container that runs within it the application container and any related services.

### Installing
1. Install [Taskfile](https://taskfile.dev/), via one of the supported package managers.

    **For Linux:** Use [installation instructions](https://taskfile.dev/docs/installation) for your preferred package manager.

    **For Mac**: Install via homebrew, `brew install go-task`.

2. Install Docker.

    **For Mac:** [Install Docker Desktop](https://docs.docker.com/desktop/install/mac-install/). While this is enough to get the application running, you should request membership to the Penn Libraries Docker Team license from [the IT Helpdesk](https://ithelp.library.upenn.edu/support/home) for full functionality.

    **For Linux:** [Install docker engine](https://docs.docker.com/engine/install/).

### Starting

1. After installing Docker and Taskfile, move into the `.dev` directory:
    ```
    cd .dev
    ```

2. Then, run a task to start up the environment:
    ```
    task up
    ```

    When you first run a task command it will pull down a series of remote taskfiles, you'll need to answer `Y` to accept the alert/s.

    While the task runs, it will ask you for your computer password to update the `/etc/hosts` file and for your LDAP credentials to pull down secrets from Hashicorp Vault.

3. Once the environment has completed building, you'll be able to confirm the application is running by going to [https://apotheca-dev.library.upenn.edu/](https://apotheca-dev.library.upenn.edu/).

4. Move to the next sections for more details on how to interact with the environment.

### Interacting with Environment
When the environment is running, you can run the following command to swap the docker context.
```
task docker:context:use:app
```

After swapping the docker context, you'll be able to interact with the containers locally as if you were within the Docker-in-Docker container. Running commands like `docker ps` will display all the containers currently running in the environment.

When you are done you can change the context back to the default by running:
```
task docker:context:use:default
```

### Interacting with Application
Once your environment is set up:
1. Swap the docker context (see [Interacting with Environment](#interacting-with-environment)):
    ```
    task docker:context:use:app
    ```
2. Start a shell in the `apotheca` app container:
    ```
    docker exec -it apotheca_apotheca.1.{whatever} bash
    ```

See application README for more information on [running the test suite](rails_app/README.md) and general application development.

#### Locally build image
Usually the image for the Rails application is pulled from our gitlab registry. In some instances you may want to force the image to be built locally. In order to do that the `apotheca_build_docker_image` variable in [ansible/inventories/development/group_vars/docker_swarm_managers/apotheca.yml](ansible/inventories/development/group_vars/docker_swarm_managers/apotheca.yml) must be set to `true`.

### Services
- Rails Application
    - URL: [https://apotheca-dev.library.upenn.edu/](https://apotheca-dev.library.upenn.edu/)
- API
    - URL: [https://digitalrepository-dev.library.upenn.edu/](https://digitalrepository-dev.library.upenn.edu/)
- Minio (S3-compatible object storage, development only; staging/production use AWS S3 and Wasabi)
    - Console URL: [http://minio-console-dev.library.upenn.edu/](http://minio-console-dev.library.upenn.edu/)
    - Username: `minioadmin`
    - Password: `minioadmin`
- Solr ([SolrCloud mode](https://solr.apache.org/guide/solr/latest/deployment-guide/cluster-types.html#solrcloud-mode), managed by Zookeeper)
    - URL: [http://apotheca-dev.library.upenn.int/solr/#/](http://apotheca-dev.library.upenn.int/solr/#/)
    - Username and password: `solr_username` and `solr_password` from the `apotheca/vagrant` Vault secret

### Destroying
To destroy the environment and any data associated with it, run:
```
task destroy
```

## Deployment
Gitlab automatically deploys to both our staging and production environment under certain conditions.

### Staging
Gitlab deploys to our staging server every time new code gets merged into `main`. The staging site is available at [https://apotheca-staging.library.upenn.edu/](https://apotheca-staging.library.upenn.edu/).

Code cannot be pushed directly onto `main`, new code must be merged via a merge request.

### Production
Deployments are triggered when a new git tag is created that matches [semantic versioning](https://semver.org/), (e.g., v1.0.0). Git tags should be created via the creation of a new Release in Gitlab.

In order to deploy to production:
1. Go to [https://gitlab.library.upenn.edu/dld/digital-repository/apotheca/-/releases/new](https://gitlab.library.upenn.edu/dld/digital-repository/apotheca/-/releases/new)
2. Create a new tag that follows semantic versioning. Please use the next tag in the sequence.
3. Relate a milestone to the release if there is one.
4. Add a release title that is the same as the tag name.
5. Submit by clicking "Create Release".

The production site is available at [https://apotheca.library.upenn.edu/](https://apotheca.library.upenn.edu/).
