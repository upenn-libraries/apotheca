# frozen_string_literal: true

module ReportService
  # Growth report
  class RepositoryGrowth < Base
    def build
      report = Jbuilder.encode do |json|
        json.items(items.to_a) do |item|
          # TODO: format timestamps: ISO-8601 format in UTC (2025-02-13T14:32:55Z)
          json.unique_identifier item.unique_identifier
          json.create_date item.date_created.iso8601
          json.system_create_date item.created_at.iso8601
          # first_created_at is populated if it was created outside of apotheca
          # created_at is the system create date (it's a valkyrie method, attribute)
          # date_created is a helper method
          # json.system_create_date all_(item).date_created - What is this value?
          json.updated_at item.date_updated.iso8601
          json.published item.published
          json.first_published_at item.first_published_at&.iso8601
          # json.first_published_at item.first_published_at
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
            json.created_at asset.created_at.iso8601
            json.updated_at asset.updated_at.iso8601
          end
        end
      end
      StringIO.new(report)
    end

    private

    # @param item [ItemResource]
    # @return [Array<AssetResource>]
    def all_assets(item)
      query_service.find_many_by_ids(ids: item.asset_ids)
    end
  end
end
