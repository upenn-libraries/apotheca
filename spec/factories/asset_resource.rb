# frozen_string_literal: true

# Factory for AssetResource.
#
# Use `.build` to build object and use `.persist` to persist via Valkyrie persister.
FactoryBot.define do
  factory :asset_resource do
    original_filename { 'front.jpg' }
    created_by { 'admin@library.upenn.edu' }
    updated_by { 'admin@library.upenn.edu' }
  end
end
