# frozen_string_literal: true

module ReportService
  # Growth report
  class RepositoryGrowth < Base
    DESCRIPTIVE_METADATA_FIELDS = %i[title collection bibnumber item_type physical_format rights].freeze

    # Build a repository growth report
    # @return [StringIO]
    def build
      report = Jbuilder.encode { |json| build_items(json, items) }
      StringIO.new(report)
    end

    # Build item JSON
    # @param json [Jbuilder]
    # @param item [ItemResource]
    # @return [Hash]
    def build_items(json, items)
      json.items(items.to_a) do |item|
        json.unique_identifier item.unique_identifier
        json.create_date item.date_created.iso8601
        json.system_create_date item.created_at.iso8601
        json.updated_at item.date_updated.iso8601
        json.published item.published
        json.first_published_at item.first_published_at&.iso8601
        json.descriptive_metadata refine_descriptive_metadata(item.presenter.descriptive_metadata.to_h)
        build_assets(json, item)
      end
    end

    # Build assets
    # @param json [Jbuilder]
    # @param item [ItemResource]
    # @return [Hash]
    def build_assets(json, item)
      json.assets(all_assets(item)) do |asset|
        json.filename asset.original_filename
        json.mime_type asset.technical_metadata[:mime_type]
        json.size asset.technical_metadata[:size]
      end
    end

    private

    # @param desciptive_metdata [Hash]
    # @return [Hash]
    def refine_descriptive_metadata(descriptive_metadata)
      descriptive_metadata.select { |k, _v| DESCRIPTIVE_METADATA_FIELDS.include?(k) }
    end

    # @param item [ItemResource]
    # @return [Array<AssetResource>]
    def all_assets(item)
      return [] if item.asset_ids.blank?

      query_service.find_many_by_ids(ids: item.asset_ids)
    end
  end
end
