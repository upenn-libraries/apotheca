# frozen_string_literal: true

module ReportService
  # Report service base class
  class Base
    attr_accessor :items

    # initialize with all items
    def initialize
      @items = query_service.find_all_of_model(model: ItemResource)
    end

    def build
      raise NotImplementedError
    end

    private

    # implement default query service
    def query_service
      @query_service ||= Valkyrie::MetadataAdapter.find(:postgres).query_service
    end
  end
end
