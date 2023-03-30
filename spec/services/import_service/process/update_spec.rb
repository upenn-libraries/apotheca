# frozen_string_literal: true

require_relative 'base'

describe ImportService::Process::Update do
  it_behaves_like 'a ImportService::Process::Base' do
    let(:import_action) { :update }
  end

  describe '#valid?' do
    it 'requires a unique_identifier' do
      process = build(:import_process, :update, unique_identifier: nil)
      expect(process.valid?).to be false
      expect(process.errors).to include 'unique_identifier must be provided when updating an Item'
    end

    it 'requires a valid unique_identifier' do
      process = build(:import_process, :update, unique_identifier: 'ark:/99999/fk4invalid')
      expect(process.valid?).to be false
      expect(process.errors).to include 'unique_identifier does not belong to an Item'
    end
  end

  describe '#run?' do
    include_context 'with successful requests to update EZID'

    let(:item) { persist(:item_resource, :with_faker_metadata) }

    let(:result) { process.run }
    let(:updated_item) { result.value! }

    context 'when updating descriptive metadata' do
      let(:process) do
        build(
          :import_process, :update,
          unique_identifier: item.unique_identifier, structural: { viewing_direction: 'left-to-right' },
          metadata: { collection: ['Very important new collection'], format: ['New'], language: [] }
        )
      end

      it 'is successful' do
        expect(result).to be_a Dry::Monads::Success
        expect(updated_item).to be_a ItemResource
      end

      it 'updates expected descriptive metadata' do
        expect(updated_item.descriptive_metadata.collection).to contain_exactly('Very important new collection')
        expect(updated_item.descriptive_metadata.format).to contain_exactly('New')
      end

      it 'does not update title' do
        expect(updated_item.descriptive_metadata.title).to match_array(item.descriptive_metadata.title)
      end

      it 'does not update internal notes' do
        expect(updated_item.internal_notes).to match_array(item.internal_notes)
      end

      it 'updates expected structural metadata' do
        expect(updated_item.structural_metadata.viewing_direction).to eql 'left-to-right'
        expect(updated_item.structural_metadata.viewing_hint).to eql item.structural_metadata.viewing_hint
      end

      it 'removes language' do
        expect(updated_item.descriptive_metadata.language).to be_blank
      end
    end
  end
end
