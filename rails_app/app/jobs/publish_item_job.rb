# frozen_string_literal: true

# Job to Publish Item
class PublishItemJob < OperationJob
  sidekiq_options queue: :high

  def operation(item_id, updated_by)
    Item::Publish.call(item_id, updated_by)
  end
end
