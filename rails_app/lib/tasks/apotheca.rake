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

  desc 'Generate some sample item/assets'
  task generate_samples: :environment do
    sample_records_count = 5

    sample_records_count.times do
      fake_item = FactoryBot.build :item_resource, :with_faker_metadata

      # Load file
      uploaded_file = ActionDispatch::Http::UploadedFile.new(
        tempfile: File.new(Rails.root.join('spec/fixtures/files/trade_card/original/front.tif')),
        filename: 'front.tif'
      )

      # Create Asset
      result = CreateAsset.new.call(created_by: fake_item.created_by, label: 'Front',
                                    annotation: [{ text: 'Front of Card' }])
      asset_id = result.value!.id

      # Update Asset with preservation file
      UpdateAsset.new.call(id: asset_id, updated_by: fake_item.created_by, file: uploaded_file)

      # Prepare Item metadata
      item_metadata = {
        created_by: fake_item.created_by,
        human_readable_name: fake_item.human_readable_name,
        descriptive_metadata: fake_item.descriptive_metadata.to_json_export,
        structural_metadata: {
          viewing_hint: fake_item.structural_metadata.viewing_hint,
          arranged_asset_ids: [asset_id]
        },
        published: fake_item.published,
        asset_ids: [asset_id]
      }

      # Create Item
      CreateItem.new.call(**item_metadata)
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

  desc 'Generate sample Reports'
  task generate_reports: :environment do
    sample_count = 5
    report_states = Report.aasm.states.map(&:name)

    # Ensure that at least one is successful
    FactoryBot.create(:report, Report::STATE_SUCCESSFUL)
    1.upto(sample_count - 1).each do
      FactoryBot.create(:report, report_states.sample)
    end
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
