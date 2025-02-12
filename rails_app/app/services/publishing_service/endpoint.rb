# frozen_string_literal: true

module PublishingService
  # Helper class that stores the configuration of an application/website that receives requests to
  # display records from Apotheca. This class also helps centralize the logic that creates links
  # that point to the published Apotheca record in an external site.
  #
  # In our IIIF manifests and PDF we make references to the published record, therefore
  # having clear configuration on how those links are created is helpful and could set
  # us up for the possibility of supporting other publishing endpoints.
  class Endpoint
    REQUIRED_CONFIG = %i[base_url token item_path asset_path public_item_path pdf_path
                         original_path manifest_path].freeze
    attr_reader :config

    delegate(*REQUIRED_CONFIG, to: :config)

    # Return Colenda publishing endpoint
    def self.colenda
      new(Settings.publish.colenda)
    end

    # @param [Config::Options] config
    def initialize(config)
      REQUIRED_CONFIG.each do |key|
        raise "Missing publishing configuration for #{key}" if config[key].blank?
      end

      @config = config
    end

    # URL to item in external application.
    #
    # This is the url that should be used for publishing and unpublishing item.
    #
    # @example https://colenda.library.upenn.edu/items/ark:/1234-23456
    #
    # @param [String] id item id
    def item_url(id)
      URI.join(base_url, "#{item_path}/#{id}").to_s
    end

    # Link to public item url in external application. The link to the public url uses a
    # normalized version of the ark.
    #
    # @todo Once we move away from using this url format, we can remove this method and use item_url.
    # @example https://colenda.library.upenn.edy/catalog/1234-23456
    #
    # @param [String] id item id
    def public_item_url(id)
      id = id.gsub('ark:/', '').tr('/', '-')
      URI.join(base_url, "#{public_item_path}/#{id}").to_s
    end

    # Link to pdf in external application
    #
    # @param [String] id item id
    def pdf_url(id)
      URI.join(base_url, "#{item_path}/#{id}/#{pdf_path}").to_s
    end

    # Link to manifest in external application
    #
    # @param [String] id item id
    def manifest_url(id)
      URI.join(base_url, "#{item_path}/#{id}/#{manifest_path}").to_s
    end

    # Link to download original/preservation asset file in external application
    #
    # @param [String] item_id item id
    # @param [String] id asset id
    def original_url(item_id, id)
      URI.join(base_url, "#{item_path}/#{item_id}/#{asset_path}/#{id}/#{original_path}").to_s
    end
  end
end
