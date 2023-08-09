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
      { title: [{ value: 'A Title from the ILS' }], date: [{ value: '2000' }] }
    end

    it 'defers descriptive metadata field calls to the resource even if ILS value present' do
      expect(presenter.descriptive_metadata.title).to match_array item_resource.descriptive_metadata.title
    end

    it 'defers descriptive metadata field calls to ILS metadata if resource value not present' do
      expect(presenter.descriptive_metadata.date).to contain_exactly({ value: '2000' })
    end

    it 'can be used to get values from Resource and ILS sources' do
      expect(presenter.descriptive_metadata.ils_metadata[:title]).to match_array ils_metadata[:title]
      expect(presenter.object.descriptive_metadata.title).to eq item_resource.descriptive_metadata.title
    end
  end
end
