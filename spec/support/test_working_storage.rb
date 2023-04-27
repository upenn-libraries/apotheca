# frozen_string_literal: true

class TestWorkingStorage
  # Move file to working storage.
  def self.load_example_files
    s3.upload(File.new(Rails.root.join('spec/fixtures/files/front.tif')), 'trade_card/front.tif')
    s3.upload(File.new(Rails.root.join('spec/fixtures/files/back.tif')), 'trade_card/back.tif')
    s3.upload(File.new(Rails.root.join('spec/fixtures/files/bell.wav')), 'bell.wav')
    s3.upload(File.new(Rails.root.join('spec/fixtures/files/video.mov')), 'video.mov')
  end

  # Remove all files from working storage.
  def self.clean
    s3.clear!
  end

  def self.s3
    Shrine::Storage::S3.new(public: true, force_path_style: true, **Settings.working_storage.sceti_digitized)
  end
end
