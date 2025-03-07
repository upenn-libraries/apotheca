# frozen_string_literal: true

# Class to help extract IIIF manifests via an API provided by FromThePage
class FromThePage
  attr_reader :url, :token

  def initialize(url, token)
    @url = url
    @token = token
  end

  # Returns collection_ids for the given user. Filters out Document Sets.
  #
  # @return [Array<String>] collection_ids
  def collection_ids(user_id)
    response = connection.get("/iiif/collections/#{user_id}")

    # Extract Collection IDs.
    response.body['collections'].filter_map do |collection_or_set|
      id = collection_or_set['@id']
      next unless id.start_with?("#{url}/iiif/collection")

      id.gsub("#{url}/iiif/collection/", '')
    end
  end

  # Return IIIF manifest URLs for all the works in this collection.
  def work_manifests(collection_id)
    connection.get("iiif/collection/#{collection_id}")
              .body['manifests']
              .map { |work| work['@id'] }
  end

  # @return [Manifest]
  def manifest(manifest_url)
    json = connection.get(manifest_url).body

    Manifest.new(json, connection)
  end

  def connection
    @connection ||= Faraday.new(url: url) do |builder|
      builder.request :authorization, 'Token', token
      builder.response :json
      builder.response :raise_error
    end
  end

  # Class to extract data from the IIIF manifest.
  class Manifest
    attr_reader :json, :connection

    def initialize(json, connection)
      @json = json
      @connection = connection
    end

    # Extract unique_identifier from IIIF manifest.
    #
    # @return [String]
    def unique_identifier
      source_data = json['metadata'].find { |i| i['label'] == 'dc:source' }
      source_url = Array.wrap(source_data['value']).compact_blank.first

      match = source_url.match(%r{https://colenda.library.upenn.edu/.+/(81431)-(p3[a-zA-Z0-9]+)})

      return if match.nil?

      "ark:/#{match[1]}/#{match[2]}"
    end

    # Extract transcriptions from IIIF Manifest
    #
    # @return [Array<String>]
    def transcriptions
      json.dig('sequences', 0, 'canvases').map do |canvas|
        transcription_url = canvas['seeAlso'].find { |a| a['label'] == 'Verbatim Plaintext' }['@id']
        connection.get(transcription_url).body
      end
    end
  end
end
