# frozen_string_literal: true

module BulkExportCard
  # ViewComponent
  class Component < ViewComponent::Base
    attr_reader :bulk_export, :counter


    # @param [BulkExport] bulk_export
    # @param [User] user
    def initialize(bulk_export:, user:)
      @bulk_export = bulk_export
      @user = user
    end

    # @return [Ability]
    def ability
      @ability ||= Ability.new(@user)
    end

    # @return [Boolean]
    def in_a_modifiable_state?
      return false if @bulk_export.cancelled? || @bulk_export.processing?

      true
    end

    # @return [Boolean]
    def can_modify?
      return true if (ability.can? :update, BulkExport) && in_a_modifiable_state?

      false
    end

    # @return [Boolean]
    def can_delete?
      return true if (ability.can? :destroy, BulkExport) && in_a_modifiable_state?

      false
    end

    def csv_download_link
      link_to 'Download CSV', rails_blob_path(bulk_export.csv, disposition: 'attachment'), class: "card-link col"
    end

  end
end

