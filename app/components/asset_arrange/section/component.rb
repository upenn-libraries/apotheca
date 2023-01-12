# frozen_string_literal: true

module AssetArrange
  module Section
    # Component for arrangement section, holding Asset cards
    class Component < ViewComponent::Base
      attr_reader :assets, :arranged

      renders_one :unarranged_section, Section::Component
      renders_one :arranged_section, Section::Component

      # @param [Array<AssetResource>] assets
      # @param [TrueClass, FalseClass] arranged
      def initialize(assets:, arranged:)
        @assets = assets
        @arranged = arranged
      end

      def id
        "#{type}-section"
      end

      def title
        t(:title, scope: [:assets, :arrangement, type])
      end

      def message
        t(:message, scope: [:assets, :arrangement, type])
      end

      def target
        "#{type}List"
      end

      # @param [AssetResource] asset
      # @return [String]
      def asset_description_text(asset)
        text = "#{asset.display_title} (#{number_to_human_size(asset.technical_metadata.size)} #{asset.technical_metadata.mime_type})"
        text = text.dup.prepend("#{asset.label} - ") if asset.label.present?
        text
      end

      def placeholder_message
        t(:placeholder_message, scope: [:assets, :arrangement, type])
      end

      private

      def type
        arranged ? :arranged : :unarranged
      end
    end
  end
end
