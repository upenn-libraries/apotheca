# frozen_string_literal: true

describe ItemChangeSet do
  let(:resource) { ItemResource.new }
  let(:change_set) { described_class.new(resource) }

  # it_behaves_like "a Valkyrie::ChangeSet"

  it 'requires human readable name' do
    change_set.validate(human_readable_name: nil)

    expect(change_set.valid?).to be false
    expect(change_set.errors.key?(:human_readable_name)).to be true
    expect(change_set.errors[:human_readable_name]).to include 'can\'t be blank'
  end

  context 'when mass assigning structural metadata' do
    context 'with valid attributes' do
      before do
        change_set.validate(
          descriptive_metadata: { title: ['New Item'] },
          human_readable_name: 'New Item',
          structural_metadata: {
            viewing_direction: 'left-to-right',
            viewing_hint: 'paged',
            arranged_asset_ids: ['first-asset-id']
          }
        )
      end

      it 'is valid' do
        expect(change_set.valid?).to be true
      end

      it 'sets viewing direction' do
        expect(change_set.structural_metadata.viewing_direction).to eql 'left-to-right'
      end

      it 'sets viewing hint' do
        expect(change_set.structural_metadata.viewing_hint).to eql 'paged'
      end
    end

    context 'with invalid viewing hint' do
      before do
        change_set.validate(
          human_readable_name: 'New Item',
          structural_metadata: { viewing_hint: 'invalid' }
        )
      end

      it 'is not valid' do
        expect(change_set.valid?).to be false
        expect(change_set.errors[:'structural_metadata.viewing_hint']).to contain_exactly 'is not included in the list'
      end
    end

    context 'with invalid viewing direction' do
      before do
        change_set.validate(structural_metadata: { viewing_direction: 'invalid' })
      end

      it 'is not valid' do
        expect(change_set.valid?).to be false
        expect(change_set.errors[:'structural_metadata.viewing_direction']).to contain_exactly 'is not included in the list'
      end
    end
  end

  context 'when mass assigning descriptive metadata' do
    before do
      change_set.validate(
        human_readable_name: 'New Item',
        descriptive_metadata: { title: ['Some Great Item'], date: ['2022-02-02'] }
      )
    end

    it 'is valid' do
      expect(change_set.valid?).to be true
    end

    it 'sets title' do
      expect(change_set.descriptive_metadata.title).to match_array 'Some Great Item'
    end

    it 'sets date' do
      expect(change_set.descriptive_metadata.date).to match_array '2022-02-02'
    end
  end

end