# Apotheca

## Overview
The administrative application that enables the ingestion and management of digital assets. This application provides a web UI and a bulk import process for staff to load content. It stores preservation copies in two cloud storage solutions, extracts technical metadata, creates derivatives and publishes the content out to our discovery interface.

## Local Development Environment

Our local development environment uses vagrant in order to set up a consistent environment with the required services. Please see the [root README for instructions](../README.md#development)  on how to set up this environment.

The **Rails application** will be available at [https://apotheca-dev.library.upenn.edu](https://apotheca-dev.library.upenn.edu).

The **Minio console** will be available at [http://minio-console-dev.library.upenn.edu](http://minio-console-dev.library.upenn.edu). Log-in with `minioadmin/minioadmin`

The **Solr admin console** for the first instance will be available at [http://apotheca-dev.library.upenn.int/solr1/#/](http://apotheca-dev.library.upenn.int/solr1/#/).

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

## Code Linting and Formatting
### Rubocop
Rubocop is used to enforce style and formatting rules in our Ruby code. This application uses a custom set of rules contained within the [upennlib-rubocop](https://gitlab.library.upenn.edu/cgalarza/upennlib-rubocop) gem.

#### To check style and formatting run:
```ruby
bundle exec rubocop
```

#### To regenerate `.rubocop_todo.yml`:
```shell
bundle exec rubocop --auto-gen-config  --auto-gen-only-exclude --exclude-limit 10000
```

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
