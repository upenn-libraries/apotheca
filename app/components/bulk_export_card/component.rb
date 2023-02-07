# frozen_string_literal: true

module BulkExportCard
  # ViewComponent
  class Component < ViewComponent::Base
    attr_reader :bulk_export

    # @param [BulkExport] bulk_export
    # @param [User] user
    # @param [Hash] options
    def initialize(bulk_export:, user:, **options)
      @bulk_export = bulk_export
      @user = user
      @options = options
    end

    # @return [Ability]
    def ability
      @ability ||= Ability.new(@user)
    end

    # @return [Boolean]
    def can_cancel?
      (ability.can? :update, bulk_export) && bulk_export.may_cancel?
    end

    # @return [Boolean]
    def can_regenerate?
      (ability.can? :update, bulk_export) && !bulk_export.processing?
    end

    # @return [Boolean]
    def can_delete?
      (ability.can? :destroy, bulk_export) && !bulk_export.processing?
    end

    def csv_download_link
      link_to 'Download CSV', rails_blob_path(bulk_export.csv, disposition: 'attachment'), class: "card-link col"
    end

  end
end

