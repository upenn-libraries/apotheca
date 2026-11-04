# frozen_string_literal: true

module Item
  # Provides method that creates item presenter
  module Presentable
    # @return [ItemPresenter]
    def presenter
      @presenter ||= ItemPresenter.new(object: self,
                                       ils_metadata: bibnumber? ? bibdata_query : nil)
    end

    private

    # @return [Boolean]
    def bibnumber?
      descriptive_metadata&.bibnumber.try(:any?)
    end

    # @return [Hash]
    def bibdata_query
      Query.solr.custom_queries.ils_metadata_for(id: id.to_s)
    end
  end
end
