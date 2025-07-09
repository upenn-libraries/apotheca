# frozen_string_literal: true

module API
  module Resources
    # API actions for AssetResources
    class AssetsController < APIController
      include AssetLoadable

      def show; end

      def file; end
    end
  end
end
