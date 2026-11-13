# frozen_string_literal: true

module Item
  module Steps
    # Unpublish an Item.
    class Unpublish
      include Dry::Monads[:result]

      # Unpublish the Item using the PublishingService.
      #
      # @param change_set [ItemChangeSet]
      def call(change_set)
        return Success(change_set) if Settings.publish.skip

        change_set.published = false

        client = PublishingService::Client.new(PublishingService::Endpoint.digital_collections)
        client.unpublish(change_set)

        Success(change_set)
      rescue StandardError => e
        Failure(error: :error_unpublishing_item, exception: e, change_set: change_set)
      end
    end
  end
end
