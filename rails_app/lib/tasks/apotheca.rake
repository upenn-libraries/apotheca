# frozen_string_literal: true

require './spec/support/valkyrie_persist_strategy'

namespace :apotheca do
  desc 'Promote a SAML user to ADMIN'
  task create_admin_stub: :environment do
    if ENV.fetch('UID', nil).blank?
      puts 'Specify a Penn Key in an "UID" environment variable to create a stub user'
      return
    end

    email = "#{ENV.fetch('UID')}@upenn.edu"
    user = User.create!(provider: 'saml', uid: ENV.fetch('UID'), email: email, roles: [User::ADMIN_ROLE], active: true)
    puts "User #{user.uid} created!"
  end

  desc 'Reindex Resources'
  task reindex: :environment do
    Solr::Reindexer.reindex_all
  end

  desc 'Generate some sample items'
  task generate_samples: :environment do
    FactoryBot.register_strategy(:persist, ValkyriePersistStrategy)

    sample_records_count = 20
    0.upto(sample_records_count).each do
      FactoryBot.persist :item_resource, :with_faker_metadata, :with_asset
    end
  end

  desc 'Generate sample BulkImports'
  task generate_bulk_imports: :environment do
    sample_count = 10
    import_states = Import.aasm.states.map(&:name)
    bulk_imports = FactoryBot.create_list(:bulk_import, sample_count)

    0.upto(sample_count * 3).each do
      FactoryBot.create(:import, import_states.sample, bulk_import: bulk_imports.sample)
    end
  end

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
    system('RAILS_ENV=development rake apotheca:create_buckets')
    system('RAILS_ENV=test rake apotheca:create_buckets')
  end

  desc 'Destroys local development & test environments and any data'
  task destroy: :environment do
    system('docker-compose down --volumes') # Removes containers and volumes
  end

  desc 'Stop local development & test environments'
  task stop: :environment do
    system('docker-compose stop')
  end

  desc 'Create preservation, derivative and working storage buckets for development and test environments'
  task create_buckets: :environment do
    configs = [
      Settings.derivative_storage, Settings.iiif_derivative_storage, Settings.preservation_storage,
      Settings.preservation_copy_storage, Settings.iiif_manifest_storage, Settings.working_storage.sceti_digitized
    ]

    configs.each do |config|
      client = Aws::S3::Client.new(**config.to_h.except(:bucket))

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
