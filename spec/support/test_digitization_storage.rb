# frozen_string_literal: true

class TestDigitizationStorage
  # Move file to digitization storage.
  def self.load_example_files
    s3.upload(File.new(Rails.root.join('spec/fixtures/files/front.tif')), 'trade_card/front.tif')
    s3.upload(File.new(Rails.root.join('spec/fixtures/files/back.tif')), 'trade_card/back.tif')
  end

  # Remove all files from digitization storage.
  def self.clean
    s3.delete_prefixed('trade_card/')
  end

  def self.s3
    Shrine::Storage::S3.new(public: true, force_path_style: true, **Settings.digitization_storage.sceti_digitized)
  end
end