# frozen_string_literal: true

module MetadataExtractor
  class Alma
    # Simple API Client using Faraday to get Alma Bib records
    class Client
      class Error < StandardError; end

      PHYSICAL_AVAILABILITY_PARAM = 'p_avail'
      FORMAT = 'json'
      MARC_XML_FIELD = 'anies'

      # See https://developers.exlibrisgroup.com/alma/apis/docs/bibs/R0VUIC9hbG1hd3MvdjEvYmlicw for alma bibs api
      # documentation
      # @param [String] bibnumber
      # @return [Hash]
      def bib(bibnumber)
        query = { expand: PHYSICAL_AVAILABILITY_PARAM, format: FORMAT }
        begin
          JSON.parse(faraday.get("#{Settings.alma.bibs.path}/#{bibnumber}", query).body)
        rescue Faraday::Error => e
          parse_alma_error_and_raise e
        end
      end

      def marc_xml(bibnumber)
        bib(bibnumber)[MARC_XML_FIELD].first
      end

      private

      # @return [Faraday::Connection]
      def faraday
        @faraday ||= Faraday.new(url: URI::HTTPS.build(host: Settings.alma.host)) do |config|
          config.request :authorization, :apikey # TODO add api key
          config.request :json
          config.response :raise_error
          config.response :logger, Rails.logger, headers: true, bodies: false, log_level: :info do |fmt|
            fmt.filter(/^(Authorization: ).*$/i, '\1[REDACTED]')
          end
        end
      end

      # Retrieve error code and message from alma api error response
      # We configured Faraday to automatically raise exceptions on 4xx-5xx responses. Alma Api errors are passed to
      # these exceptions, and located in the body of the Faraday::Error response object.
      # See https://developers.exlibrisgroup.com/alma/apis/docs/bibs/R0VUIC9hbG1hd3MvdjEvYmlicw for alma bibs api error
      # structure
      # @param [Faraday::Error] faraday_error
      # @return [Hash]
      def parse_alma_error_and_raise(faraday_error)
        if faraday_error.response_body.blank?
          raise Error, 'Alma API error: Sadly error code and message are not available.'
        end

        body = JSON.parse(faraday_error.response_body)
        alma_error = body&.dig('errorList', 'error')&.first || {}
        alma_error_code = alma_error.fetch('errorCode', nil)
        alma_error_message = alma_error.fetch('errorMessage', nil)
        raise Error, "Alma API error: #{alma_error_code} #{alma_error_message}".strip
      end
    end
  end
end
