# Colenda Admin
Administrative application that enables the ingestion and management of digital assets. 

## System Requirements
- Ruby 2.7.5
- Postgres

## Local Development and Test Environment
WIP

### Running Tests
WIP

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