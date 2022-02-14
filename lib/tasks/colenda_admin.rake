# frozen_string_literal: true

namespace :colenda_admin do
  desc 'Start local development & test environments'
  task start: :environment do
    # Start services
    system('docker-compose up -d')

    # Wait until postgres is ready before creating database.
    until system('docker-compose exec -u postgres postgres pg_isready')
      # Create databases, if they aren't present.
      system('rake db:create')

      # Migrate test and development databases
      system('RAILS_ENV=development rake db:migrate')
      system('RAILS_ENV=test rake db:migrate')
    end

    # TODO: Create buckets, check minio is available first
    # system('RAILS_ENV=development rake app:create_buckets')
    # system('RAILS_ENV=test rake app:create_buckets')
  end

  desc 'Destroys local development & test environments and any data'
  task destroy: :environment do
    system('docker-compose down --volumes') # Removes containers and volumes
  end

  desc 'Stop local development & test environments'
  task stop: :environment do
    system('docker-compose stop')
  end
end
