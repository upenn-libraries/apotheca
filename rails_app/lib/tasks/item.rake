# frozen_string_literal: true

namespace :apotheca do
  namespace :item do
    desc 'Republish items that have already been published'
    task republish: :environment do
      email = ENV.fetch('EMAIL', nil)

      if email.blank?
        puts 'Provide a User email for the user running this task'
        next
      end

      if User.find_by(email: email).nil?
        puts 'Provide email for valid user.'
        next
      end

      query_service = Valkyrie::MetadataAdapter.find(:postgres).query_service
      query_service.find_all_of_model(model: ItemResource).each do |item|
        PublishItemJob.perform_async(item.id.to_s, email) if item.published
      end
    end
  end
end
