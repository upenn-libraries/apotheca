# frozen_string_literal: true

describe CSVImport::Validate do
  let(:operation) { described_class.new }

  describe '#call' do
    let(:result) { operation.call(data) }

    context 'when imported_by missing' do
      let(:data) { build(:csv_import, :create, imported_by: nil) }

      it 'returns failure' do
        byebug
        expect(result.failure?).to be true
        expect(result.failure[:details]).to include 'imported_by must be a string'
      end
    end

    context 'with a unique_identifier already in use' do
      let(:data) { build(:csv_import, :create, unique_identifier: ark) }
      let(:ark) { persist(:item_resource).unique_identifier }

      it 'return failure' do
        expect(result.failure?).to be true
        expect(result.failure[:details]).to include("unique_identifier already assigned to an item")
      end
    end
  end
end