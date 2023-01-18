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
    let(:bulk_export) { create :bulk_export }

    it 'attaches a csv file' do
      bulk_export.csv.attach(io: StringIO.new('contents'), filename: 'file.csv')
      expect(bulk_export.csv).to be_attached
      expect(bulk_export.csv.download).to eq 'contents'
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

