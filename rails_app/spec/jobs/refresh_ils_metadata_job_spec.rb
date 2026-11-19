# frozen_string_literal: true

describe RefreshIlsMetadataJob do
  let(:item) { persist(:item_resource) }

  it_behaves_like 'OperationJob' do
    let(:args) { [item.id.to_s, item.updated_by] }
  end
end
