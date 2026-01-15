# frozen_string_literal: true

namespace :apotheca do
  namespace :samples do
    desc 'Generate some sample item/assets using fake data'
    task generate_items: :environment do
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

    desc 'Import a set of sample items from production'
    task import_items: :environment do
      Settings.api.sample_records.each do |id|
        ENV['id'] = id
        Rake::Task['apotheca:samples:import_item'].reenable
        Rake::Task['apotheca:samples:import_item'].invoke
      end
    end

    desc 'Use api to import an item and its assets from a deployed environment'
    task import_item: :environment do
      include Rails.application.routes.url_helpers
      raise ArgumentError, 'item id missing' unless ENV['id']

      # Item uuid
      id = ENV['id']

      # Determine which api to use from deployed environments
      deployed_env = ENV['staging'] == 'true' ? :staging : :production

      # Establish faraday connection
      connection = Faraday.new(url: URI::HTTPS.build(host: Settings.api.host[deployed_env])) do |config|
        config.request :json # Sets the Content-Type header to application/json on each request.
        config.options.timeout = 600 # Set connection timeout
        config.response :follow_redirects # Follows api redirects to presigned S3 url
        config.response :raise_error # Raises an error on 4xx and 5xx responses.
        config.response :json # Parses JSON response bodies.
      end

      item_json = connection.get(api_item_resource_admin_path(uuid: id), { assets: true }).body['data']['item']

      asset_json = item_json['assets']

      # Maximum number of assets an imported item can have unless force flag passed
      asset_limit = 25

      if asset_json.size > asset_limit && ENV['force'] != 'true'
        abort("Item's assets exceeds limit of #{asset_limit}. Aborting import.")
      end

      thumbnail_asset_id = item_json['thumbnail_asset_id']

      item_metadata = {
        unique_identifier: item_json['ark'],
        created_by: Settings.system_user,
        human_readable_name: item_json['human_readable_name'],
        descriptive_metadata: item_json['descriptive_metadata'],
        structural_metadata: {
          viewing_direction: item_json['structural_metadata']['viewing_direction'],
          viewing_hint: item_json['structural_metadata']['viewing_hint'],
          arranged_asset_ids: []
        },
        thumbnail_asset_id: nil,
        ocr_strategy: item_json['ocr_strategy'],
        asset_ids: []
      }

      cleanup = lambda do |asset_ids, error_msg, step|
        asset_ids.each { |a| PurgeAsset.new.call(id: a.id) }
        puts 'Assets purged'
        puts "Something went wrong while #{step.to_s.humanize.downcase}: #{error_msg.to_s.humanize}."
        abort("Aborting import of item #{id} from #{deployed_env}.")
      end

      # Create all arranged assets

      asset_json.each do |asset|
        asset_metadata = { filename: asset['preservation_file']['original_filename'],
                           label: asset['label'],
                           created_by: Settings.system_user }
        asset_id = nil

        CreateAsset.new.call(**asset_metadata) do |result|
          result.failure { |data| cleanup.call(item_metadata[:asset_ids], data[:error], :creating_an_asset) }
          result.success { |item| asset_id = item.id }
        end

        # Push asset id to item asset_ids and arranged_asset_ids array
        item_metadata[:asset_ids] << asset_id
        item_metadata[:structural_metadata][:arranged_asset_ids] << asset_id

        # Set thumbnail_asset_id
        item_metadata[:thumbnail_asset_id] = asset_id if thumbnail_asset_id == asset['id']

        # Download preservation file
        tempfile = Tempfile.new('preservation_file', binmode: true)

        connection.get(URI.parse(asset['preservation_file']['url']).path) do |req|
          req.options.on_data = proc do |chunk, _overall_received_bytes_, _env|
            tempfile.write(chunk)
          end
        end

        tempfile.rewind

        # Present preservation file as a ActionDispatch::Http::UploadedFile
        uploaded_file = ActionDispatch::Http::UploadedFile.new(tempfile: tempfile, filename: asset_metadata[:filename])

        # Update asset with preservation file
        UpdateAsset.new.call(id: asset_id, updated_by: item_metadata[:created_by], file: uploaded_file) do |result|
          result.failure { |data| cleanup.call(item_metadata[:asset_ids], data[:error], :updating_an_asset) }
          result.success { |updated_asset| "Asset #{updated_asset.id} updated with preservation file." }
        end

        # Close and delete temp file
        tempfile.close(true)
      end

      # Create Item
      CreateItem.new.call(**item_metadata) do |result|
        result.failure { |data| cleanup.call(item_metadata[:asset_ids], data[:error], :creating_an_item) }
        result.success do |item|
          puts "Successfully imported #{id} from #{deployed_env}: #{item.presenter.apotheca_url}."
        end
      end
    end
  end
end
