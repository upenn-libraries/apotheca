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

    # Create buckets
    system('RAILS_ENV=development rake colenda_admin:create_buckets')
    system('RAILS_ENV=test rake colenda_admin:create_buckets')
  end

  desc 'Destroys local development & test environments and any data'
  task destroy: :environment do
    system('docker-compose down --volumes') # Removes containers and volumes
  end

  desc 'Stop local development & test environments'
  task stop: :environment do
    system('docker-compose stop')
  end

  desc 'Create preservation and derivative buckets for development and test environments'
  task create_buckets: :environment do
    configs = [Settings.derivative_storage, Settings.iiif_derivative_storage,
               Settings.preservation_storage, Settings.preservation_copy_storage]

    configs.each do |config|
      client = Aws::S3::Client.new(
        credentials: Aws::Credentials.new(
          config[:access_key_id], config[:secret_access_key]
        ),
        endpoint: config[:endpoint],
        force_path_style: true,
        region: 'us-east-1' # Default
      )

      # Create preservation bucket if it's not already present.
      begin
        client.head_bucket(bucket: config[:bucket])
      rescue Aws::S3::Errors::NotFound
        client.create_bucket(bucket: config[:bucket])
        client.put_bucket_policy(
          bucket: config[:bucket],
          policy: {
            'Version' => '2012-10-17',
            'Statement' => [
              {
                'Effect' => 'Allow',
                'Principal' => { 'AWS' => ['*'] },
                'Action' => [
                  's3:GetBucketLocation',
                  's3:ListBucket'
                ],
                'Resource' => ["arn:aws:s3:::#{config[:bucket]}"]
              },
              {
                'Effect' => 'Allow',
                'Principal' => { 'AWS' => ['*'] },
                'Action' => ['s3:GetObject'],
                'Resource' => ["arn:aws:s3:::#{config[:bucket]}/*"]
              }
            ]
          }.to_json
        )
      end
    end
  end
end
