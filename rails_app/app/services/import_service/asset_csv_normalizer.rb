# frozen_string_literal: true

module ImportService
  # Transforms data from an asset metadata csv into our specified format based on 'sequence' attribute.
  class AssetCSVNormalizer
    class << self
      # @param [Hash]
      # @return [Hash]
      def process(data)
        asset_csv_data = data.delete('csv')
        return data if asset_csv_data.blank?

        data['arranged'] = arranged_assets(asset_csv_data)
        data['unarranged'] = unarranged_assets(asset_csv_data)
        data
      end

      private

      # @return [Array<Hash>]
      def arranged_assets(asset_data)
        asset_data.select { |asset| asset['sequence'].present? }
                  .sort_by { |asset| asset['sequence'] }
                  .map { |asset| asset.except('sequence') }
      end

      # @return [Array<Hash>]
      def unarranged_assets(asset_data)
        asset_data.select { |asset| asset['sequence'].blank? }
                  .map { |asset| asset.except('sequence') }
      end
    end
  end
end
