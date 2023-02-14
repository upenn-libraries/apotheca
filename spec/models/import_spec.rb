# frozen_string_literal: true

require_relative 'concerns/queueable'

describe Import do
  it_behaves_like 'queueable'

  it 'requires import data' do
    import = build :import, import_data: nil
    expect(import.valid?).to be false
    expect(import.errors['import_data']).to include "can't be blank"
  end

  it 'creates an import' do
    import = create :import
    expect(import.valid?).to be true
    expect(import.import_data).to be_a Hash
  end
end
