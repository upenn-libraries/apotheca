# frozen_string_literal: true

describe ImportService::AssetsNormalizer do
  let(:transformer) { described_class }
  let(:assets_data) do
    [{ 'filename' => 'a.tif', 'sequence' => '2', 'annotation' => ['scribble'] },
     { 'filename' => 'b.tif', 'label' => 'test', 'transcription' => %w[readable text], 'sequence' => nil },
     { 'filename' => 'c.tif', 'sequence' => '10' }]
  end

  describe '.process' do
    let(:transformed_data) { transformer.process(assets_data) }

    it 'adds assets with sequence to arranged assets array' do
      expect(transformed_data['arranged'].size).to eq(2)
      expect(transformed_data['arranged']).to eq [
        { 'filename' => 'a.tif', 'annotation' => ['scribble'] },
        { 'filename' => 'c.tif' }
      ]
    end

    it 'adds assets with no sequence to unarranged assets array' do
      expect(transformed_data['unarranged'].size).to eq(1)
      expect(transformed_data['unarranged'].first).to eq('filename' => 'b.tif', 'label' => 'test',
                                                         'transcription' => %w[readable text])
    end
  end
end
