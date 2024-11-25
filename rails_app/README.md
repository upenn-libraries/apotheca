# Apotheca
Apotheca is the administrative application that enables the ingestion and management of digital assets. It is a 
Ruby-on-Rails application that uses [Valkyrie](https://github.com/samvera/valkyrie) to manage the files and metadata associated with each digital object. It provides a web UI and a bulk import process for staff to load content. It stores preservation copies in two cloud storage solutions, extracts technical metadata, creates derivatives and publishes the content out to our discovery interface.

To view end-user documentation, visit our [Confluence documentation](https://upennlibrary.atlassian.net/wiki/spaces/COL/pages/498794612/Apotheca).

## Local Development Environment

Our local development environment uses vagrant in order to set up a consistent environment with the required services. Please see the [root README for instructions](../README.md#development)  on how to set up this environment.

The **Rails application** will be available at [https://apotheca-dev.library.upenn.edu](https://apotheca-dev.library.upenn.edu).

The **Sidekiq Web UI** will be available at [http://apotheca-dev.library.upenn.edu/sidekiq](http://apotheca-dev.library.upenn.edu/sidekiq).

The **Minio console** will be available at [http://minio-console-dev.library.upenn.edu](http://minio-console-dev.library.upenn.edu). Log-in with `minioadmin/minioadmin`.

The **Solr admin console** for the first instance will be available at [http://apotheca-dev.library.upenn.int/solr/#/](http://apotheca-dev.library.upenn.int/solr/#/). Log-in with `admin/test`.

### Interacting with the Application

Once your local development environment is set up you can ssh into the vagrant box to interact with the application:

1. Enter the Vagrant VM by running `vagrant ssh` in the `/vagrant` directory
2. Start a shell in the `apotheca` container:
```
  docker exec -it apotheca_apotheca.1.{whatever} sh
```

### Generate Example Items

To generate some example items in a local development environment:

1. Start a shell in the apotheca app, see [interacting-with-the-application](#interacting-with-the-application)
2. Run rake tasks:
```bash
bundle exec rake apotheca:generate_samples
```

### Running Test Suite

In order to run the test suite (currently):

1. Start a shell in the apotheca app, see [interacting-with-the-application](#interacting-with-the-application)
2. Run `rspec` command: `RAILS_ENV=test bundle exec rspec`

## Valkyrie
Apotheca uses [Valkyrie](https://github.com/samvera/valkyrie)'s interface to store the metadata and files associated for each digital object. The metadata is stored in Solr and Postgres. The Solr index is used for searching and Postgres is used as the canonical metadata source. We use the extension [valkyrie-shrine](https://github.com/samvera-labs/valkyrie-shrine) to store all of our files to cloud storage. Our Valkyrie resources and change sets are located in [app/resources](app/resources/) and [app/change_sets](app/change_sets/), respectively.

More information about why we choose Valkyrie can be found in the [relevant ADR](docs/architecture_decisions/0002_choose_valkyrie.md).

[Dive into Valkyrie](https://github.com/samvera/valkyrie/wiki/Dive-into-Valkyrie) is a good tutorial to get some familiarity with Valkyrie.

## dry-transaction
To orchestrate the various actions that need to happen when we create/update/delete Valkyrie resources we use [dry-transaction](https://dry-rb.org/gems/dry-transaction/0.15/). Where possible, we try to extract `steps` that can be shared across transactions. Essentially, any action that involves changing a Resource should go through a transaction. The only place transactions are not used is during testing.

More information about transactions can be found in the [relevant ADR](docs/architecture_decisions/0003_use_transactions.md).

## ViewComponent
We use the [ViewComponent](https://viewcomponent.org/) library to create shareable/reuseable UI elements. In some cases we use it to make our view templates more manageable. 

## Sidekiq and ActiveJob
We use [Sidekiq](https://github.com/sidekiq/sidekiq) to run all of our jobs in `development`, `staging` and `production`. In `test`, we use test appropriate adapters. All of our custom jobs are written with `Sidekiq::Job` to provide better performance. We don't use `ActiveJob::Base` when writing custom jobs. While we don't directly use `ActiveJob`, it is configured to use Sidekiq in case we decide to use built-in jobs like sending emails.

The Sidekiq Web UI is available at `/sidekiq`.

## Authentication

In development, two authentication providers are available:
1. Developer Authentication - enter a fake PennKey and you're in. This looks for an existing developer-provider user and logs that user in. Upon creation, these users have the `ADMIN_ROLE`.
2. PennKey Authentication - selecting this will authenticate via Penn's IdP. Another admin user will have to create a user stub via the UI. In deployed environments, the rake task `apotheca:create_admin_stub UID=your_pennkey` can be used to initialize a stub admin user.
This makes it possible to use your PennKey in development but also to create additional users to test out authorization functionality.

In staging and production, only PennKey authentication is available.

## Configuration/Settings
Application-wide configuration is centralized in `config/settings` and `config/settings.yml`. Access to configuration is provided via the `Settings` object instantiated by the [config](https://github.com/rubyconfig/config) gem. For example, to retrieve the preservation storage configuration run:

```ruby
Settings.preservation_storage
```

Environment specific configuration values should be placed in the appropriate file in the `config/settings` directory. For configuration that is the same for all environments it should be placed in `config/settings.yml`.

In production, configuration values that are secret should be set using docker secrets and the application should read them in from the filesystem.

## Javascript and CSS Asset management
We will be following Rails 7 convention and using `importmap-rails` to manage and load javascript assets. We can make use of JS NPM packages by following [these instructions](https://github.com/rails/importmap-rails#using-npm-packages-via-javascript-cdns) from the `importmap-rails` docs.

For CSS vendored assets, CDN or Gemified versions should be used when available. Otherwise, CSS can be copied into `app/assets/stylesheets` and imported in `application.scss`.

Node, NPM nor Yarn are required to develop, run or deploy this application.

## Rubocop
This application uses Rubocop to enforce Ruby and Rails style guidelines. We centralize our UPenn specific configuration in
[upennlib-rubocop](https://gitlab.library.upenn.edu/dld/upennlib-rubocop).


To check style and formatting run:
```ruby
bundle exec rubocop
```

If there are rubocop offenses that you are not able to fix please do not edit the rubocop configuration instead regenerate the `rubocop_todo.yml` using the following command:

```bash
rubocop --auto-gen-config  --auto-gen-only-exclude --exclude-limit 10000
```

To change our default Rubocop config please open an MR in the `upennlib-rubocop` project.


## Basic Operations
### Create an Item and Asset with transactions

```ruby
# Create Asset and attach file
result = CreateAsset.new.call(original_filename: 'front.tif', created_by: 'admin@library.upenn.edu')

uploaded_file = ActionDispatch::Http::UploadedFile.new tempfile: File.new(Rails.root.join('spec', 'fixtures', 'files', 'trade_card', 'original', 'front.tif')), filename: 'front.tif', type: 'image/tiff'

result = UpdateAsset.new.call(id: result.value!.id, file: uploaded_file, updated_by: 'admin@library.upenn.edu')

asset = result.value!

# Attach Asset to Item
item = CreateItem.new.call(human_readable_name: 'New Item', created_by: 'admin@library.upenn.edu', descriptive_metadata: { title: ['Best Item'] }, structural_metadata: { arranged_asset_ids: [asset.id]}, asset_ids: [asset.id])
```

## Contributing

In order to contribute productively while fostering the project values, familiarize yourself with the established
[Gitlab Collaboration Workflow](https://upennlibrary.atlassian.net/wiki/spaces/DLD/pages/498073672/GitLab+Collaboration+Workflow)
as well as the [Ruby on Rails Development Guidelines](https://upennlibrary.atlassian.net/wiki/spaces/DLD/pages/495616001/Ruby-on-Rails+Development+Guidelines).