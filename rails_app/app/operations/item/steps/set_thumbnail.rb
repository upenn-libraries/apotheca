# frozen_string_literal: true

module Item
  module Steps
    # Set thumbnail in ItemResource.
    class SetThumbnail
      include Dry::Monads[:result]

      # Sets thumbnail asset id if it is not set and assets are present.
      #
      # @param change_set [Valkyrie::ChangeSet]
      def call(change_set)
        if change_set.thumbnail_asset_id.blank?
          thumbnail_id = if change_set.structural_metadata.arranged_asset_ids&.any?
                           change_set.structural_metadata.arranged_asset_ids.first
                         elsif change_set.asset_ids&.any?
                           change_set.asset_ids.first
                         end

          change_set.thumbnail_asset_id = thumbnail_id
        end

        Success(change_set)
      end
    end
  end
end
