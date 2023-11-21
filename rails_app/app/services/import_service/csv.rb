# frozen_string_literal: true

module ImportService
  # Handles structured CSV data during the import process
  class CSV
    include Enumerable

    class Error < StandardError; end

    # @param [String] csv
    def initialize(csv)
      @data = StructuredCSV.parse(csv)
    end

    # Add data from assets csv to the appropriate row. This method removes the `asset.csv_filename` field
    # as part of its processing.
    # @param [String] filename
    # @param [String] contents
    def add_assets_csv(filename, contents)
      row = find { |ele| ele.dig('assets', 'csv_filename') == filename }

      raise Error, "Missing asset CSV(s): #{filename}" if row.blank?

      row['assets'].delete('csv_filename')

      asset_data = StructuredCSV.parse(contents)
      row['assets'].merge!(ImportService::AssetsNormalizer.process(asset_data))
    end

    # Iterating through each row in the CSV.
    def each(&)
      @data.each(&)
    end

    # raise ImportService::CSV::Error if there is an error in the CSV
    def valid!
      empty_csv!
      missing_assets_csv!
    end

    private

    # raise ImportService::CSV::Error if bulk import csv is empty
    def empty_csv!
      raise Error, 'CSV has no data' if @data.blank? || all?(&:blank?)
    end

    # Raising error if `asset.csv_filename` is present. If the csv_filename is still
    # present we didn't get an Asset CSV for the Item.
    #
    # raise ImportService::CSV::Error if any asset CSVs are missing
    def missing_assets_csv!
      missing_csvs = map { |row| row.dig('assets', 'csv_filename') }.compact_blank
      raise Error, "Missing asset CSV(s): #{missing_csvs.join(', ')}" if missing_csvs.present?
    end
  end
end
