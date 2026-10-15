# frozen_string_literal: true

module Item
  # Provides method that creates item presenter
  module Presentable
    # @return [ItemResourcePresenter]
    def presenter
      ItemResourcePresenter.new(object: self)
    end
  end
end
