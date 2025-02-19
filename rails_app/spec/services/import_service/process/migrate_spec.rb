# frozen_string_literal: true

require_relative 'base'

describe ImportService::Process::Migrate do
  it_behaves_like 'a ImportService::Process::Base' do
    let(:import_action) { :migrate }
  end

  describe '#valid?' do
    it 'requires a unique_identifier' do
      process = build(:import_process, :migrate, unique_identifier: nil)
      expect(process.valid?).to be false
      expect(process.errors).to include 'unique_identifier must be provided to migrate an Item'
    end

    context 'with a unique_identifier already in use by the application' do
      include_context 'with successful requests to lookup EZID'

      let(:process) { build(:import_process, :migrate, unique_identifier: ark) }
      let(:ark) { persist(:item_resource).unique_identifier }

      it 'adds errors' do
        expect(process.valid?).to be false
        expect(process.errors).to include("\"#{ark}\" has already been migrated")
      end
    end

    context 'with an unminted ark' do
      include_context 'with unsuccessful requests to lookup EZID'

      let(:process) { build(:import_process, :migrate, unique_identifier: 'ark:/99999/fk4invalid') }

      it 'adds error' do
        expect(process.valid?).to be false
        expect(process.errors).to include('"ark:/99999/fk4invalid" is not minted')
      end
    end

    context 'when Colenda data fetched' do
      include_context 'with successful requests to lookup EZID'

      let(:unique_identifier) { 'ark:/99999/fk12345' }
      let(:process) { build(:import_process, :migrate, unique_identifier: unique_identifier) }

      before do
        stub_request(:get, "#{Settings.migration.colenda_url}/migration/#{CGI.escape(unique_identifier)}/serialized")
          .to_return(status: 200, body: '{}', headers: {})
      end

      it 'requires human_readable_name' do
        expect(process.valid?).to be false
        expect(process.errors).to include('human_readable_name must be provided to migrate an object')
      end

      it 'requires created_at' do
        expect(process.valid?).to be false
        expect(process.errors).to include('created_at must be provided to migrate an object')
      end

      it 'required created_by' do
        expect(process.valid?).to be false
        expect(process.errors).to include('created_by must be provided to migrate an object')
      end

      it 'required first_published_at' do
        expect(process.valid?).to be false
        expect(process.errors).to include('first_published_at must be provided to migrate an object')
      end

      it 'required last_published_at' do
        expect(process.valid?).to be false
        expect(process.errors).to include('last_published_at must be provided to migrate an object')
      end

      it 'required assets' do
        expect(process.valid?).to be false
        expect(process.errors).to include('assets must be provided to migrate an object')
      end

      it 'required metadata' do
        expect(process.valid?).to be false
        expect(process.errors).to include('metadata must be provided to migrate an object')
      end
    end
  end

  describe '#run' do
    include_context 'with successful requests to lookup EZID'
    include_context 'with successful requests to update EZID'

    let(:process) { build(:import_process, :migrate, unique_identifier: body[:unique_identifier]) }
    let(:result) { process.run }
    let(:item) { result.value! }
    let(:body) { JSON.parse(File.read(file_fixture('colenda_serialization/example-1.json'))).deep_symbolize_keys }

    before do
      stub_request(
        :get,
        "#{Settings.migration.colenda_url}/migration/#{CGI.escape(body[:unique_identifier])}/serialized"
      ).to_return(status: 200, body: body.to_json, headers: {})
    end

    context 'when migrating an item' do
      # rubocop:disable Layout/LineLength
      let(:metadata) do
        {
          physical_location: [{ value: 'Arc.MS.2' }],
          collection: [{ value: 'Issac Leeser Collection at the Herbert D. Katz Center for Advanced Judaic Studies (University of Pennsylvania)' }],
          date: [{ value: '1866-02-17' }],
          extent: [{ value: 'Letter' }],
          physical_format: [{ value: 'Letters' }],
          geographic_subject: [
            { value: 'United States -- Texas -- Belton' },
            { value: 'United States -- Texas' },
            { value: 'United States -- Pennsylvania -- Philadelphia' },
            { value: 'United States -- Pennsylvania' }
          ],
          identifier: [{ value: 'LSDCBx3FF1_14' }],
          language: [{ value: 'English', uri: 'https://id.loc.gov/vocabulary/iso639-2/eng' }],
          note: [
            { value: '2 pages on 1 sheet' },
            { value: 'Issac Leeser Collection at the Herbert D. Katz Center for Advanced Judaic Studies (University of Pennsylvania)' }
          ],
          name: [
            { value: 'Sampson, E.' },
            { value: 'Sampson, E.' },
            { value: 'Leeser, I., Rev.' },
            { value: 'Rev. I. Leeser' }
          ],
          provenance: [
            { value: 'Transfer of Custody from the Hebrew Education Society, 10 March 1913, to the Library of the Dropsie College for Hebrew and Cognate Learning.' }
          ],
          relation: [{ value: 'https://franklin.library.upenn.edu/catalog/FRANKLIN_9924408973503681' }],
          rights: [{ value: 'No Copyright - United States', uri: 'http://rightsstatements.org/vocab/NoC-US/1.0/' }],
          title: [{ value: 'Letter; Sampson, E.; Leeser, I., Rev.; Belton, TX; 17 February 1866' }]
        }
      end
      # rubocop:enable Layout/LineLength

      it 'is successful' do
        expect(result).to be_a Dry::Monads::Success
        expect(item).to be_a ItemResource
      end

      it 'migrates unique_identifier' do
        expect(item.unique_identifier).to eql body[:unique_identifier]
      end

      it 'migrates human_readable_name' do
        expect(
          item.human_readable_name
        ).to eql 'Leeser letter; Sampson, E.; Leeser, I., Rev.; Belton, TX; 17 February 1866'
      end

      it 'migrated created_at' do
        expect(item.first_created_at).to eql DateTime.parse('2022-04-06T08:16:42.000-04:00')
      end

      it 'migrates publishing dates' do
        expect(item.first_published_at).to eql DateTime.parse('2022-04-06T08:17:24.000-04:00')
        expect(item.last_published_at).to eql DateTime.parse('2022-04-06T08:17:24.000-04:00')
      end

      it 'migrates structure metadata' do
        expect(item.structural_metadata.viewing_direction).to eql 'left-to-right'
        expect(item.structural_metadata.viewing_hint).to be_nil
      end

      it 'migrates all metadata' do
        expect(item.to_json_export[:metadata]).to eql metadata
      end

      it 'migrates two assets' do
        expect(item.asset_ids.count).to be 2
        expect(item.structural_metadata.arranged_asset_ids.count).to be 2
      end

      it 'migrates asset label and transcriptions' do
        assets = Valkyrie::MetadataAdapter.find(:postgres).query_service.find_many_by_ids(ids: item.asset_ids)
        body[:assets][:arranged].each do |asset_metadata|
          asset = assets.find { |a| a.original_filename == asset_metadata[:filename] }
          expect(asset.label).to eql asset_metadata[:label]
          expect(asset.annotations).to be_empty
          expect(asset.transcriptions.map(&:contents)).to contain_exactly(asset_metadata[:transcription][0])
        end
      end
    end

    context 'when migrating an item and publishing' do
      include_context 'with successful publish request'

      let(:process) { build(:import_process, :migrate, :publish, unique_identifier: body[:unique_identifier]) }

      it 'is successful' do
        expect(result).to be_a Dry::Monads::Success
        expect(item).to be_a ItemResource
      end

      it 'makes publishing request' do
        result
        expect(a_request(:post, "#{Settings.publish.colenda.base_url}/items")).to have_been_made
      end

      it 'sets publishing values' do
        expect(item).to have_attributes(
          published: true, first_published_at: be_a(DateTime), last_published_at: be_a(DateTime)
        )
      end
    end

    context 'when migrating an item with invalid checksums' do
      let(:body) do
        JSON.parse(File.read(file_fixture('colenda_serialization/invalid-checksum-example.json'))).deep_symbolize_keys
      end

      it 'fails' do
        expect(result).to be_a Dry::Monads::Failure
      end

      it 'return expected failure object' do
        expect(result.failure[:error]).to be :import_failed
        expect(result.failure[:details]).to contain_exactly(
          'Error while creating front.tif: Expected checksum does not match'
        )
      end
    end

    context 'when migrating an item and skipping assets' do
      let(:process) do
        build(:import_process, :migrate, ignored_assets: ['ilcajs_b3f1_0014_1r.tif'],
                                         unique_identifier: body[:unique_identifier])
      end

      it 'is successful' do
        expect(result).to be_a Dry::Monads::Success
        expect(item).to be_a ItemResource
      end

      it 'migrates one asset' do
        expect(item.asset_ids.count).to be 1
        expect(item.structural_metadata.arranged_asset_ids.count).to be 1
      end

      it 'migrates the expected asset' do
        assets = Valkyrie::MetadataAdapter.find(:postgres).query_service.find_many_by_ids(ids: item.asset_ids)
        expect(assets.first.original_filename).to eql 'ilcajs_b3f1_0014_1v.tif'
      end
    end
  end
end
