# frozen_string_literal: true

describe ImportService::ColendaMetadata do
  describe '#valid?' do
    it 'requires that all fields are valid' do
      metadata = described_class.new({ invalid_field: ['values'] })
      expect(metadata.valid?).to be false
      expect(metadata.errors).to include 'invalid metadata fields provided'
    end

    it 'requires title is present if bibnumber is not present' do
      metadata = described_class.new({ name: ['Random Person'] })
      expect(metadata.valid?).to be false
      expect(metadata.errors).to include 'title is required if a bibnumber is not provided'
    end

    it 'does not require title if bibnumber is present' do
      metadata = described_class.new({ bibnumber: ['12345'] })
      expect(metadata.valid?).to be true
    end

    # Currently, migrating dates that are in the following format, 1944-06-24T14:00:00,
    # throw an error when trying to deserialize.
    it 'requires that dates do not include time' do
      metadata = described_class.new({ date: ['1944-06-24T14:00:00', '1944'] })
      expect(metadata.valid?).to be false
      expect(metadata.errors).to include 'date cannot include time'
    end
  end

  describe '#to_apotheca_metadata' do
    let(:new_metadata) do
      described_class.new(original_metadata).to_apotheca_metadata
    end

    context 'when blank values present' do
      let(:original_metadata) do
        { notes: ['First Note', ''], subject: [nil, ' '] }
      end

      it 'removes empty values' do
        expect(new_metadata[:note]).to contain_exactly({ value: 'First Note' })
        expect(new_metadata[:subject]).to be_nil
      end
    end

    context 'when type and item_type present' do
      let(:original_metadata) do
        { item_type: %w[Photographs Book], type: ['PhotoBook'] }
      end

      it 'combines values in type and item_type' do
        expect(new_metadata[:physical_format]).to contain_exactly(
          { value: 'Photographs' }, { value: 'Book' }, { value: 'PhotoBook' }
        )
      end
    end

    context 'when multiple titles present' do
      let(:original_metadata) do
        { title: ['First Title', 'Second Title'] }
      end

      it 'splits title into two fields' do
        expect(new_metadata[:title]).to contain_exactly({ value: 'First Title' })
        expect(new_metadata[:alt_title]).to contain_exactly({ value: 'Second Title' })
      end
    end

    context 'when language present' do
      let(:original_metadata) { { language: %w[English French] } }

      it 'adds language URIs' do
        expect(new_metadata[:language]).to contain_exactly(
          { value: 'English', uri: 'https://id.loc.gov/vocabulary/iso639-2/eng' },
          { value: 'French', uri: 'https://id.loc.gov/vocabulary/iso639-2/fre' }
        )
      end
    end

    context 'when names are present in other fields' do
      let(:original_metadata) do
        {
          corporate_name: ['Random Corporate Name'],
          personal_name: ['Random Personal Name'],
          creator: ['Random Creator'],
          contributor: ['Random Contributor']
        }
      end
      let(:names) do
        [
          { value: 'Random Corporate Name' },
          { value: 'Random Personal Name' },
          { value: 'Random Creator', role: [{ value: 'Creator', uri: 'https://id.loc.gov/vocabulary/relators/cre' }] },
          { value: 'Random Contributor', role: [{ value: 'Contributor', uri: 'https://id.loc.gov/vocabulary/relators/ctb' }] }
        ]
      end

      it 'correctly migrates all names' do
        expect(new_metadata[:name]).to match_array(names)
      end
    end

    context 'when rights statement uri present' do
      let(:original_metadata) do
        { title: ['New Work'], rights: ['https://rightsstatements.org/page/CNE/1.0/?language=en'] }
      end

      it 'normalizes uri' do
        expect(new_metadata[:rights][0][:uri]).to eql 'https://rightsstatements.org/vocab/CNE/1.0/'
      end

      it 'adds correct value' do
        expect(new_metadata[:rights][0][:value]).to eql 'Copyright Not Evaluated'
      end

      it 'does not add a rights_note' do
        expect(new_metadata[:rights_note]).to be_blank
      end
    end

    context 'when rights note is present' do
      let(:rights_note) { 'The contents of this digital collection are protected under copyright law and must not be reproduced without permission. Please contact kislak@pobox.upenn.edu for more information.' }
      let(:original_metadata) { { title: ['New Work'], rights: [rights_note] } }

      it 'moves value to rights_note' do
        expect(new_metadata[:rights]).to be_blank
        expect(new_metadata[:rights_note][0][:value]).to eql rights_note
      end
    end
  end
end
