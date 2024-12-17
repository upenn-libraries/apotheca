# frozen_string_literal: true

describe DerivativeService::Asset::TesseractWrapper::LanguagePreparer do
  let(:languages) { [] }
  let(:viewing_direction) { nil }
  let(:language_preparer) { described_class.new(languages: languages, viewing_direction: viewing_direction) }

  describe '#prepared_languages' do
    context 'with only invalid or blank languages' do
      let(:languages) { ['invalid', '', nil] }

      it 'returns an empty array' do
        expect(language_preparer.prepared_languages).to be_empty
      end
    end

    context 'with a mix of valid and invalid languages' do
      let(:languages) { ['invalid', '', 'yid'] }

      it 'returns valid languages' do
        expect(language_preparer.prepared_languages).to contain_exactly('yid')
      end
    end

    context 'with german' do
      let(:languages) { %w[rus deu] }

      it 'includes the german fraktur language code' do
        expect(language_preparer.prepared_languages).to contain_exactly('rus', 'deu', 'frk')
      end
    end

    context 'with chinese' do
      let(:languages) { ['chi'] }

      it 'includes traditional and simplified codes' do
        expect(language_preparer.prepared_languages).to contain_exactly('chi-tra-vert', 'chi-sim-vert')
      end
    end

    context 'with left-to-right viewing direction' do
      it 'does not return any vertical(*-vert) language codes' do
        expect(language_preparer.prepared_languages).to contain_exactly(*languages)
      end
    end

    context 'with chinese, korean, japanese' do
      let(:languages) { described_class::CJK_LANGUAGES }

      it 'returns vertical language code by default' do
        vert_languages = languages.map { |lang| "#{lang}-vert" }
        expect(language_preparer.prepared_languages).to contain_exactly(*vert_languages)
      end
    end

    context 'with chinese, korean, japanese and left-to-right viewing direction' do
      let(:languages) { described_class::CJK_LANGUAGES }
      let(:viewing_direction) { 'left-to-right' }

      it 'does not return vertical language code with left-to-right viewing direction' do
        expect(language_preparer.prepared_languages).to contain_exactly(*languages)
      end
    end
  end

  describe '#argument' do
    context 'with invalid or blank language' do
      let(:languages) { ['invalid', '', nil] }

      it 'returns nil' do
        expect(language_preparer.argument).to be nil
      end
    end

    context 'with a single valid language' do
      let(:languages) { ['yid'] }

      it 'returns the expected value' do
        expect(language_preparer.argument).to eq '-l yid'
      end
    end

    context 'with multiple valid languages' do
      let(:languages) { %w[yid heb] }

      it 'returns the expected value' do
        expect(language_preparer.argument).to eq '-l yid+heb'
      end
    end
  end
end
