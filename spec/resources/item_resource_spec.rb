# frozen_string_literal: true

require_relative 'concerns/modification_details'

describe ItemResource do
  let(:resource_klass) { described_class }

  context 'with included behavior' do
    let(:resource) { build(:item_resource) }

    it_behaves_like 'a Valkyrie::Resource'
    it_behaves_like 'ModificationDetails', :item_resource
  end

  context 'with arranged assets' do
    let(:resource) do
      build(:item_resource, :with_assets_some_arranged)
    end

    it 'returns a list of unarranged asset ids' do
      ordered_asset_ids = resource.structural_metadata.arranged_asset_ids
      expect(resource.unarranged_asset_ids).not_to include ordered_asset_ids
      expect(resource.unarranged_asset_ids.length).to eq 1
    end
  end
end
