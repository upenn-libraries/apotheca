# frozen_string_literal: true

describe Steps::AddPreservationEvents do
  let(:resource_class) { AssetResource }
  let(:change_set_class) { AssetChangeSet }

  describe '#call' do
    let(:change_set) { described_class.new }

    context 'with preceding events' do

    end

    context 'with migration attribute on the change set' do

    end

    context 'for a newly ingested Asset' do

    end

    context 'for an Asset receiving a new file via an update' do

    end

    context 'for an Asset receiving only updated metadata' do

    end
  end
end
