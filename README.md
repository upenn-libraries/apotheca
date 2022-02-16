# Colenda Admin
Administrative application that enables the ingestion and management of digital assets. 

## System Requirements
- Ruby 2.7.5
- Postgres

## Local Development and Test Environment
WIP

### Running Tests
WIP

## Configuration/Settings
Application-wide configuration is centralized in `config/settings` and `config/settings.yml`. Access to configuration is provided via the `Settings` object instantiated by the [config](https://github.com/rubyconfig/config) gem. For example, to retrieve the preservation storage configuration run:

```ruby
Settings.preservation_storage
```

Environment specific configuration values should be placed in the appropriate file in the `config/settings` directory. For configuration that is the same for all environments it should be placed in `config/settings.yml`.

In production, configuration values that are secret should be set using docker secrets and the application should read them in from the filesystem.


## Code Linting and Formatting
### Rubocop
Rubocop is used to in force style and formatting rules in our Ruby code. This application uses a custom set of rules contained within the [upennlib-rubocop](https://gitlab.library.upenn.edu/cgalarza/upennlib-rubocop) gem.

#### To check style and formatting run:
```ruby
bundle exec rubocop
```

#### To regenerate `.rubocop_todo.yml`:
```ruby
rubocop --auto-gen-config  --auto-gen-only-exclude --exclude-limit 10000
```

## Staging/Production Deployment
WIP