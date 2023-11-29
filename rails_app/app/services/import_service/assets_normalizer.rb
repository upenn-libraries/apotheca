# frozen_string_literal: true

module ImportService
  # Transforms data from an assets csv into our specified format based on 'sequence' attribute.
  class AssetsNormalizer
    class << self
      # @param [Array<Hash>]
      # @return [Hash]
      def process(asset_data)
        normalized_assets = {}
        normalized_assets['arranged'] = arranged_assets(asset_data)
        normalized_assets['unarranged'] = unarranged_assets(asset_data)
        normalized_assets
      end

      private

      # @return [Array<Hash>]
      def arranged_assets(asset_data)
        asset_data.select { |asset| asset['sequence'].present? }
                  .sort_by { |asset| asset['sequence'].to_i }
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
