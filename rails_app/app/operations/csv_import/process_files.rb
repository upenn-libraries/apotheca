# frozen_string_literal: true

module CSVImport
  # Processing Bulk Import CSV files.
  class ProcessFiles < Operation
    # Processes CSV files provided as part of a bulk import. Normalizes CSV data and if data is
    # provided in multiple CSV, combines the data into one so we can process it in subsequent tasks.
    #
    # @param csv_file [ActionDispatch::Http::UploadedFile] main bulk import csv
    # @param asset_csv_files [Array<ActionDispatch::Http::UploadedFile>] csv representing one item's assets
    # @return [Hash]
    def call(csv_file, asset_csv_files)
      csv = step parse_csv(csv_file)
      csv = step merge_asset_csv_files(csv, asset_csv_files)
      step validate(csv)

      csv
    end

    # Parse CSV file into a Hash.
    #
    # @param file [ActionDispatch::Http::UploadedFile]
    # @return [Dry::Monads::Success] if parsing successful, includes csv data
    # @return [Dry::Mondas::Failure] if parsing raises error
    def parse_csv(file)
      csv = StructuredCSV.parse(file.read)

      Success(csv)
    rescue CSV::MalformedCSVError => e
      Failure(error: :malformed_csv, file: file.original_filename, exception: e)
    end

    # Adds asset CSV data to csv data hash.
    #
    # @param csv [Array<Hash>] csv data
    # @param asset_csv_files [Array<ActionDispatch::Http::UploadedFile>] csv representing one item's assets
    def merge_asset_csv_files(csv, asset_csv_files)
      asset_csv_files.each do |file|
        filename = file.original_filename

        row = csv.find { |ele| ele.dig('assets', 'csv_filename') == filename }

        return Failure(error: :asset_csv_not_referenced, file: filename) if row.nil?

        row['assets'].delete('csv_filename')

        result = parse_csv(file)
        return result if result.failure?

        row['assets'].merge!(normalize_asset_data(result.value!))
      end

      Success(csv)
    rescue StandardError => e
      Failure(error: :unable_to_process_asset_csv, exception: e)
    end

    # Validate data extracted before returning.
    #
    # @param csv [Array<Hash>] csv data
    # @return [Dry::Monads::Success] if no validation error found
    # @return [Dry::Mondas::Failure] if validation error found
    def validate(csv)
      return Failure(error: :empty_csv) if csv.blank? || csv.all?(&:blank?)

      missing_csvs = csv.map { |row| row.dig('assets', 'csv_filename') }.compact_blank
      return Failure(error: :missing_asset_csv, missing: missing_csvs.join(', ')) if missing_csvs.present?

      Success(csv)
    end

    # Transforms data from an assets csv into our specified format based on 'sequence' attribute.
    #
    # @param asset_data [Array<Hash>]
    # @return [Hash]
    def normalize_asset_data(asset_data)
      {
        'arranged' => asset_data.select { |asset| asset['sequence'].present? }
                                .sort_by { |asset| asset['sequence'].to_i }
                                .map { |asset| asset.except('sequence') },
        'unarranged' => asset_data.select { |asset| asset['sequence'].blank? }
                                  .map { |asset| asset.except('sequence') }
      }
    end
  end
end
