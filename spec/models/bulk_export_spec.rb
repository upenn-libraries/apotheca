# frozen_string_literal: true

require_relative 'concerns/queueable'

describe BulkExport do
  it_behaves_like 'queueable'

  it 'requires a user' do
    bulk_export = build :bulk_export, user: nil
    expect(bulk_export.valid?).to be false
    expect(bulk_export.errors['user']).to include 'must exist'
  end

  it 'requires solr params' do
    bulk_export = build :bulk_export, solr_params: nil
    expect(bulk_export.valid?).to be false
    expect(bulk_export.errors['solr_params']).to include "can't be blank"
  end

  it 'requires state to be set' do
    bulk_export = build :bulk_export, state: nil
    expect(bulk_export.valid?).to be false
    expect(bulk_export.errors['state']).to include "can't be blank"
  end

  describe '#csv' do
    let(:csv_string_data) do
      <<~CSV
        asset.drive,asset.path,unique_identifier,metadata.creator[1],metadata.creator[2],metadata.description[1],metadata.other data,metadata.date[1],metadata.date[2],metadata.subject[1],structural.files.number,structural.sequence[1].label,structural.sequence[1].filename,structural.sequence[1].table_of_contents[1],structural.sequence[2].label,structural.sequence[2].filename,structural.sequence[2].table_of_contents[1]
        test,path/to/assets_1,ark:/9999/test,"person, random first"," person, random second", very important item,this is a test item,2020-01-01,2020-01-02,subject one,3,,,,,
        test,path/to/assets_2,ark:/9999/test2,"person, random third","person, random forth",second most important item,this is a second test item,2020-02-01,,,4,Front,front.jpeg,Illuminated Image,Back,back.jpeg,Second Illuminated Image
      CSV
    end
    it 'attaches a csv file' do
      bulk_export = create :bulk_export
      file = StringIO.new(csv_string_data)
      bulk_export.csv.attach(io: file, filename: 'file.csv')
      expect(bulk_export.csv).to be_attached
    end
  end

  context 'with associated User validation' do
    let(:user) { create :user, :admin }

    before { create_list(:bulk_export, 10, user: user) }

    it 'does not allow more than 10 bulk exports' do
      bulk_export = build(:bulk_export, user: user)
      expect(bulk_export).to be_invalid
      expect(bulk_export.errors[:user]).to include('The number of Bulk Exports for a user cannot exceed 10.')
    end
  end
end

