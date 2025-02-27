# frozen_string_literal: true

shared_examples_for 'a DerivativeService::Asset::Generator::Base' do
  before do
    raise 'generator must be set with `let(:generator)`' unless defined? generator
  end

  describe '#thumbnail' do
    it 'does not raise error' do
      expect { generator.thumbnail }.not_to raise_error
    end
  end

  describe '#access' do
    it 'does not raise error' do
      expect { generator.access }.not_to raise_error
    end
  end

  describe '#textonly_pdf' do
    it 'does not raise error' do
      expect { generator.textonly_pdf }.not_to raise_error
    end
  end

  describe '#text' do
    it 'does not raise error' do
      expect { generator.text }.not_to raise_error
    end
  end

  describe '#hocr' do
    it 'does not raise error' do
      expect { generator.hocr }.not_to raise_error
    end
  end
end
