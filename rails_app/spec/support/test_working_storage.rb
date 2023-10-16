# frozen_string_literal: true

class TestWorkingStorage
  # Move file to working storage.
  def self.load_example_files
    base = Rails.root.join('spec/fixtures/files').to_s

    Dir.glob(File.join(base, '**/*')) do |f|
      next if File.directory?(f)

      s3.upload(File.new(f), f.delete_prefix(base))
    end
  end

  # Remove all files from working storage.
  def self.clean
    s3.clear!
  end

  def self.s3
    Shrine::Storage::S3.new(**Settings.working_storage.sceti_digitized)
  end
end
