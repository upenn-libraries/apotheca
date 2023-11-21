# frozen_string_literal: true

module ImportService
  # Handles structured CSV data during the import process
  class CSV
    include Enumerable

    class Error < StandardError; end

    def initialize(csv)
      @data = StructuredCSV.parse(csv)
    end

    # Add assets from assets csv to the appropriate row. This method removes the `asset.spreadsheet_filename` field
    # as part of its processing.
    def add_assets_csv(filename, contents)
      row = find { |ele| ele.dig('assets', 'spreadsheet_filename') == filename }

      return if row.blank?

      row['assets'].delete('spreadsheet_filename')

      row['assets']['csv'] = StructuredCSV.parse(contents)
    end

    def normalize_assets(normalizer = ImportService::AssetCSVNormalizer)
      each do |row|
        row['assets'] = normalizer.process(row['assets']) if row['assets']
      end
    end

    # Iterating through each row in the CSV.
    def each(&)
      @data.each(&)
    end

    # @return [ImportService::CSV::Error] if there is an error in the CSV
    def valid!
      empty_csv!
      missing_assets_csv!
    end

    private

    # raise ImportService::CSV::Error if bulk import csv is empty
    def empty_csv!
      raise Error, 'CSV has no data' if @data.blank? || all?(&:blank?)
    end

    # Raising error if `asset.spreadsheet_filename` is present. If the spreadsheet_filename is still
    # present we didn't get an Asset CSV for the Item.
    #
    # raise ImportService::CSV::Error if any asset CSVs are missing
    def missing_assets_csv!
      missing_csvs = map { |row| row.dig('assets', 'spreadsheet_filename') }.compact_blank
      raise Error, "Missing asset metadata CSVs: #{missing_csvs.join(', ')}" if missing_csvs.present?
    end
  end
end
