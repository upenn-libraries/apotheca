# frozen_string_literal: true

require_relative 'base'

describe DerivativeService::Asset::Generator::Default do
  let(:resource) { persist(:asset_resource, :with_preservation_file, :with_pdf_file) }
  let(:generator) { described_class.new(AssetChangeSet.new(resource)) }

  it_behaves_like 'a DerivativeService::Asset::Generator::Base'
end
