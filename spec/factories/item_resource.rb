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
    unique_identifier { 'ark:/12345/random' }
    created_by { 'admin@library.upenn.edu' }
    updated_by { 'admin@library.upenn.edu' }

    trait :with_asset do
      transient do
        asset { persist(:asset_resource) }
      end

      asset_ids { [asset.id] }
      thumbnail_asset_id { asset.id }
    end

    trait :with_assets_some_arranged do
      transient do
        asset1 { persist(:asset_resource, original_filename: 'page1') }
        asset2 { persist(:asset_resource, original_filename: 'page2') }
      end

      asset_ids { [asset1.id, asset2.id] }
      thumbnail_asset_id { asset1.id }

      structural_metadata { ItemResource::StructuralMetadata.new(arranged_asset_ids: [asset1.id]) }
    end
  end
end
