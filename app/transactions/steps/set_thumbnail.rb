# frozen_string_literal: true

module Steps
  # Sets thumbnail asset id if none is set and assets are present.
  class SetThumbnail
    include Dry::Monads[:result]

    def call(change_set)
      unless change_set.thumbnail_asset_id.present?
        thumbnail_id = if change_set.structural_metadata.arranged_asset_ids&.any?
                         change_set.structural_metadata.arranged_asset_ids.first
                       elsif change_set.asset_ids&.any?
                         change_set.asset_ids.first
                       else
                         nil
                       end

        change_set.thumbnail_asset_id = thumbnail_id
      end

      Success(change_set)
    end
  end
end
