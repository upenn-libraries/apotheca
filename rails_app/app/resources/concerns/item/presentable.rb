# frozen_string_literal: true

module Item
  # Provides method that creates item presenter
  module Presentable
    # @return [ItemPresenter]
    def presenter
      ItemPresenter.new(object: self,
                        ils_metadata: bibnumber? ? Query.solr.custom_queries.ils_metadata_for(id: id.to_s) : nil)
    end

    private

    # @return [Boolean]
    def bibnumber?
      descriptive_metadata&.bibnumber.try(:any?)
    end
  end
end
