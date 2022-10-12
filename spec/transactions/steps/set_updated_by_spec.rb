# frozen_string_literal: true

describe Steps::SetUpdatedBy do
  let(:set_updated_by) { described_class.new }
  let(:change_set) do
    change_set = ItemChangeSet.new(ItemResource.new)
    change_set.created_by = 'admin@example.com'
    change_set
  end

  describe '#call' do
    subject(:result) { set_updated_by.call(change_set) }

    context 'when updated_by is set' do
      before do
        change_set.updated_by = 'new@example.com'
      end

      it 'does not change the value' do
        expect(result.value!.updated_by).to eql 'new@example.com'
      end
    end

    context 'when updated_by is not set' do
      it 'updates value to be the same as created_by' do
        expect(result.value!.updated_by).to eql 'admin@example.com'
      end
    end
  end
end
