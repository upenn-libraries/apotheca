# frozen_string_literal: true

module PublishingService
  # Stores the configuration of the consuming application/website that receives requests to
  # display records from Apotheca. This class centralize the logic that creates links
  # to the consuming application/websites.
  #
  # In our IIIF manifests and PDF we make references to the published record, therefore
  # having clear configuration on how those links are created is helpful and could set
  # us up for the possibility of supporting other publishing endpoints.
  class Endpoint
    REQUIRED_CONFIG = %i[host token webhook_path item_path].freeze
    attr_reader :config

    delegate(*REQUIRED_CONFIG, to: :config)

    # Return Digital Collections publishing endpoint
    def self.digital_collections
      new(Settings.publish.digital_collections)
    end

    # @param [Config::Options] config
    def initialize(config)
      REQUIRED_CONFIG.each do |key|
        raise "Missing publishing configuration for #{key}" if config[key].blank?
      end

      @config = config
    end

    # URL to view the item in external application. This url should be public.
    #
    # @example https://digitalcollections.library.upenn.edu/items/44e8ed46-8694-4ea4-b651-cb253e724e56
    #
    # @param [String] id item id
    def item_url(id)
      URI.join(host, "#{item_path}/#{id}").to_s
    end

    # URL for webhook endpoint.
    def webhook_url
      URI.join(host, webhook_path).to_s
    end
  end
end
