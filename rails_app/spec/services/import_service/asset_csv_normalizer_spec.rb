# frozen_string_literal: true

describe ImportService::AssetCSVNormalizer do
  let(:transformer) { described_class }
  let(:assets_data) do
    { 'csv' => [{ 'filename' => 'a.tif', 'sequence' => '1', 'annotation' => ['scribble'] },
                { 'filename' => 'b.tif', 'label' => 'test', 'transcription' => %w[readable text], 'sequence' => nil }] }
  end

  describe '.process' do
    let(:transformed_data) { transformer.process(assets_data) }

    it 'removes the csv field' do
      expect(transformed_data.key?('csv')).to be false
    end

    it 'adds assets with sequence to arranged assets array' do
      expect(transformed_data['arranged'].size).to eq(1)
      expect(transformed_data['arranged'].first).to eq('filename' => 'a.tif', 'annotation' => ['scribble'])
    end

    it 'adds assets with no sequence to unarranged assets array' do
      expect(transformed_data['unarranged'].size).to eq(1)
      expect(transformed_data['unarranged'].first).to eq('filename' => 'b.tif', 'label' => 'test',
                                                         'transcription' => %w[readable text])
    end
  end
end
