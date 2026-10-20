# frozen_string_literal: true

# Helper class for generating IIIF Image API URLs.
class IIIFImageAPI
  attr_reader :identifier, :version, :server

  # Create object used to generation IIIF Image API URLs.
  #
  # @example
  #   image_api = IIIFImageAPI.new('1234')
  #   image_api.image_url
  #
  # @param identifier [String] identifier to use when looking up resources in image server
  # @param version [Integer] version of image API to use
  # @param server [Hash] image server settings
  def initialize(identifier, version: 3, server: Settings.image_server)
    @identifier = identifier
    @version = version
    @server = server
  end

  def base_url
    URI.join(server.url, "iiif/#{version}/#{identifier}").to_s
  end

  def info_url
    "#{base_url}/info.json"
  end

  # Returns url for image in IIIF image service. Defaults to a JPEG image.
  #
  # @param region [String] See https://iiif.io/api/image/3.0/#41-region for valid regions
  # @param size [String] See https://iiif.io/api/image/3.0/#42-size for valid sizes
  # @param rotation [String] See https://iiif.io/api/image/3.0/#43-rotation for valid rotations
  # @param format [String] See https://iiif.io/api/image/3.0/#45-format for valid formats
  # @return [String|nil] url to image in IIIF Image service.
  def image_url(region: 'full', size: 'max', rotation: '0', format: 'jpg')
    "#{base_url}/#{region}/#{size}/#{rotation}/default.#{format}"
  end
end
