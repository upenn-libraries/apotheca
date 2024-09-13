# frozen_string_literal: true

# Job to Publish Item
class PublishItemJob < TransactionJob
  sidekiq_options queue: :high

  def transaction(item_id, updated_by)
    PublishItem.new.call(id: item_id, updated_by: updated_by)
  end
end
