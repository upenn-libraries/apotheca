# frozen_string_literal: true

require_relative 'concerns/modification_details'

describe ItemResource do
  let(:resource_klass) { described_class }

  context 'with included behavior' do
    let(:resource) { build(:item_resource) }

    it_behaves_like 'a Valkyrie::Resource'
    it_behaves_like 'ModificationDetails', :item_resource
  end

  describe '#unarranged_asset_ids' do
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

  describe '#to_export' do
    context 'when not including assets' do
      subject(:export) { resource.to_export }

      let(:resource) { persist(:item_resource) }

      it 'returns expected data' do
        expect(export[:human_readable_name]).to eql('New Item')
      end

      it 'returns expected nested data' do
        expect(export[:metadata][:title].first).to eql('New Item')
        expect(export[:structural][:viewing_hint]).to eql('paged')
      end

      it 'does not return asset data' do
        expect(export[:assets]).to be_nil
      end
    end

    context 'when including assets' do
      subject(:export) { resource.to_export(include_assets: true) }

      let(:resource) { persist(:item_resource, :with_assets_some_arranged) }

      it 'includes an assets field' do
        expect(export).to include(:assets)
      end

      it 'returns expected data for arranged assets' do
        expect(export[:assets][:ordered]).to eq([{ filename: 'page1', label: nil, annotations: [] }])
      end

      it 'returns expected data for unarrannged assets' do
        expect(export[:assets][:unordered]).to eq([{ filename: 'page2', label: nil, annotations: [] }])
      end

      context 'when assets not present' do
        let(:resource) { persist(:item_resource) }

        it 'returns an empty arrays for nested asset fields' do
          expect(export[:assets][:ordered]).to be_empty
          expect(export[:assets][:unordered]).to be_empty
        end
      end
    end
  end

  describe '#assets_export' do
    subject(:export) { resource.assets_export(resource.asset_ids) }

    let(:resource) { persist(:item_resource, :with_assets_some_arranged) }

    it 'returns expected data' do
      expect(export).to eq([{ filename: 'page1', label: nil, annotations: [] },
                            { filename: 'page2', label: nil, annotations: [] }])
    end
  end
end
