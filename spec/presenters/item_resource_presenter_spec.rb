# frozen_string_literal: true

RSpec.describe ItemResourcePresenter do
  subject(:presenter) do
    described_class.new object: item_resource, ils_metadata: ils_metadata
  end

  let(:item_resource) { persist(:item_resource) }

  context 'without ILS metadata' do
    let(:ils_metadata) { nil }

    it 'returns a DescriptiveMetadataPresenter' do
      expect(presenter.descriptive_metadata).to be_an ItemResourcePresenter::DescriptiveMetadataPresenter
    end

    it 'delegates descriptive metadata field calls to the Resource' do
      ItemResource::DescriptiveMetadata::Fields.all.each do |field|
        expect(
          presenter.descriptive_metadata.public_send(field)
        ).to eq item_resource.descriptive_metadata.public_send(field)
      end
    end
  end

  context 'with ILS metadata' do
    let(:ils_metadata) do
      { title: ['A Title from the ILS'] }
    end

    it 'defers descriptive metadata field calls to the ILS metadata if present' do
      expect(presenter.descriptive_metadata.title).to eq ils_metadata[:title]
    end

    it 'can be used to get values from Resource and ILS sources' do
      expect(presenter.descriptive_metadata.ils_metadata[:title]).to eq ils_metadata[:title]
      expect(presenter.object.descriptive_metadata.title).to eq item_resource.descriptive_metadata.title
    end
  end
end
