# frozen_string_literal: true

describe CSVImport::Normalize do
  let(:operation) { described_class.new }

  describe '#call' do
    let(:result) { operation.call(data) }

    context 'when arranged filenames are provided two different ways' do
      let(:data) { { assets: { arranged_filenames: 'a.tif', arranged: [{ filename: 'a.tif' }] } } }

      it 'requires that arranged filenames are not provided two different ways' do
        expect(result.failure?).to be true
        expect(result.failure).to include(
          error: :invalid_asset_structure,
          message: 'arranged_filenames/unarranged_filenames cannot be used in conjunction with arranged/unarranged keys'
        )
      end
    end

    context 'when arranged_filenames and unarranged_filenames is provided' do
      let(:data) { { assets: { arranged_filenames: 'a.tif; b.tif;c.tif', unarranged_filenames: 'd.tif;e.tif' } } }

      it 'normalizes arranged_filenames and unarranged_filenames data' do
        expect(result.success?).to be true
        expect(result.success).to match(
          {
            assets: {
              arranged: [{ filename: 'a.tif' }, { filename: 'b.tif' }, { filename: 'c.tif' }],
              unarranged: [{ filename: 'd.tif' }, { filename: 'e.tif' }]
            }
          }
        )
      end
    end

    context 'when storage and paths are provided' do

    end


  end
end