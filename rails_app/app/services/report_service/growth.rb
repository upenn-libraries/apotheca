# frozen_string_literal: true

module ReportService
  # Growth report
  class Growth < Base
    def build
      Jbuilder.encode do |json|
        json.items(items.to_a) do |item|
          json.unique_identifier item.unique_identifier
          json.create_date item.date_created
          # json.system_create_date all_(item).date_created - What is this value?
          json.updated_at item.date_updated
          json.published item.published
          json.first_published_at item.first_published_at
          json.first_published_at item.first_published_at
          json.descriptive_metadata do
            json.title item.descriptive_metadata.title.map(&:to_json_export)
            json.collection item.descriptive_metadata.collection.map(&:to_json_export)
            json.bibnumber item.descriptive_metadata.bibnumber.map(&:to_json_export)
            json.item_type item.descriptive_metadata.item_type.map(&:to_json_export)
            json.physical_format item.descriptive_metadata.physical_format.map(&:to_json_export)
            json.rights item.descriptive_metadata.rights.map(&:to_json_export)
          end
          json.assets(all_assets(item)) do |asset|
            json.filename asset.original_filename
            json.mime_type asset.technical_metadata[:mime_type]
            json.size asset.technical_metadata[:size]
            json.created_at asset.created_at
            json.updated_at asset.updated_at
          end
        end
      end
    end

    private

    # @param item [ItemResource]
    # @return [Array<AssetResource>]
    def all_assets(item)
      query_service.find_many_by_ids(ids: item.asset_ids)
    end
  end
end
