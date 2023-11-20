# frozen_string_literal: true

module ImportService
  # Transforms data from an asset metadata spreadsheet into our specified format based on 'sequence' attribute.
  class AssetSpreadsheetNormalizer
    class << self
      def process(data)
        asset_data = data.delete(:spreadsheet)
        return data if asset_data.blank?

        data[:arranged] = arranged_assets(asset_data)
        data[:unarranged] = unarranged_assets(asset_data)
        data
      end

      private

      # @return [Array<Hash>]
      def arranged_assets(asset_data)
        asset_data.select { |asset| asset[:sequence].present? }
                  .sort_by { |asset| asset[:sequence] }
                  .map { |asset| asset.except(:sequence) }
      end

      # @return [Array<Hash>]
      def unarranged_assets(asset_data)
        asset_data.select { |asset| asset[:sequence].blank? }
                  .map { |asset| asset.except(:sequence) }
      end
    end
  end
end
