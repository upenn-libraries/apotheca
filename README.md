# Colenda Admin
Administrative application that enables the ingestion and management of digital assets. 

## System Requirements
- Ruby 2.7.5
- Postgres
- [libvips](https://www.libvips.org/)
- [ffmpeg](https://ffmpeg.org/) - ensure `ffmpeg` executable is on your `$PATH`

## Local Development and Test Environment
We are using docker-compose to run adjacent services required for the application to run. The application will run directly on your machine.

### 1. Installing system requirements
#### MacOS (with Homebrew)
```shell
rbenv install 2.7.5
brew install --cask docker
brew install libpq
brew install vips
brew install ffmpeg
```
Note: Homebrew installation of libtiff does not seem to support tiff jpeg compression.

#### Linux
```shell
sudo apt install libpq-dev ffmpeg libvips
rbenv install 2.7.5
```

TODO: Add installation notes for libvips TIFF support.

### 2. Install gems
```shell
bundle install
```

### 3a. Run application in development
```shell
rake colenda_admin:start
rails s
```

### 3b. Run application tests
```shell
rake colenda_admin:start
rspec
```

### 4. Stop running services
```shell
rake colenda_admin:stop
```

### 5. Destroy services (clears all data)
```shell
rake colenda_admin:destroy
```

### Interacting directly with services
#### Minio
Visit http://localhost:9001/login and log-in with credentials in `config/settings/development.yml`
#### Solr
Is available at http://localhost:8983

## Configuration/Settings
Application-wide configuration is centralized in `config/settings` and `config/settings.yml`. Access to configuration is provided via the `Settings` object instantiated by the [config](https://github.com/rubyconfig/config) gem. For example, to retrieve the preservation storage configuration run:

```ruby
Settings.preservation_storage
```

Environment specific configuration values should be placed in the appropriate file in the `config/settings` directory. For configuration that is the same for all environments it should be placed in `config/settings.yml`.

In production, configuration values that are secret should be set using docker secrets and the application should read them in from the filesystem.


## Code Linting and Formatting
### Rubocop
Rubocop is used to enforce style and formatting rules in our Ruby code. This application uses a custom set of rules contained within the [upennlib-rubocop](https://gitlab.library.upenn.edu/cgalarza/upennlib-rubocop) gem.

#### To check style and formatting run:
```ruby
bundle exec rubocop
```

#### To regenerate `.rubocop_todo.yml`:
```ruby
bundle exec rubocop --auto-gen-config  --auto-gen-only-exclude --exclude-limit 10000
```

## Staging/Production Deployment
WIP

## Basic Operations
### Creating Item and Asset with wrapper classes
```ruby
uploaded_file = ActionDispatch::Http::UploadedFile.new tempfile: File.new(Rails.root.join('spec', 'fixtures', 'files', 'front.jpg')), filename: 'front.jpg', type: 'image/jpg'
asset = Asset.create(file: uploaded_file, original_filename: 'front.jpg', created_by: 'admin@library.upenn.edu')
item = Item.create(human_readable_name: 'New Item', created_by: 'admin@library.upenn.edu', descriptive_metadata: { title: ['Best Item'] },
                   structural_metadata: { arranged_asset_ids: [asset.id]}, asset_ids: [asset.id])

```

### Create an Item and Asset with transactions

```ruby
# Create Asset and attach file
result = CreateAsset.new.call(original_filename: 'front.jpg', created_by: 'admin@library.upenn.edu')

uploaded_file = ActionDispatch::Http::UploadedFile.new tempfile: File.new(Rails.root.join('spec', 'fixtures', 'files', 'front.jpg')), filename: 'front.jpg', type: 'image/jpg'

result = UpdateAsset.new.call(id: result.value!.id, file: uploaded_file, updated_by: 'admin@library.upenn.edu')

asset = result.value!

# Attach Asset to Item
item = CreateItem.new.call(human_readable_name: 'New Item', created_by: 'admin@library.upenn.edu', descriptive_metadata: { title: ['Best Item'] }, structural_metadata: { arranged_asset_ids: [asset.id]}, asset_ids: [asset.id])
```