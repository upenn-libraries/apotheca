# frozen_string_literal: true

# Factory for ItemResource.
#
# Use `.build` to build object and use `.persist` to persist via Valkyrie persister.
#
# For the Valkyrie factories, we took a lot of inspiration from Figgy's resource factories.
# Example: https://github.com/pulibrary/figgy/blob/main/spec/factories/scanned_resource.rb
FactoryBot.define do
  factory :item_resource do
    human_readable_name { 'New Item' }
    descriptive_metadata do
      { title: ['New Item'] }
    end
    created_by { 'admin@library.upenn.edu' }
    updated_by { 'admin@library.upenn.edu' }

    trait :with_asset do
      transient do
        asset { persist(:asset_resource) }
      end

      asset_ids { [asset.id] }
      thumbnail_asset_id { asset.id }
    end
  end
end
