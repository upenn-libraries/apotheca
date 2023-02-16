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
      ability.can?(:update, bulk_export) && bulk_export.may_cancel?
    end

    # @return [Boolean]
    def can_regenerate?
      ability.can?(:update, bulk_export) && (bulk_export.failed? || bulk_export.successful?)
    end

    # @return [Boolean]
    def can_delete?
      ability.can?(:destroy, bulk_export) && !bulk_export.processing?
    end

    # @return [String]
    def title
      (bulk_export.title || bulk_export.csv.filename) || '(Untitled)'
    end

    def csv_download_link
      link_to(rails_blob_path(bulk_export.csv, disposition: 'attachment'),
              title: "Download CSV generated at #{bulk_export.generated_at}", class: 'card-link col-2 text-center') do
        render Icon::Component.new(name: 'download', size: '24px')
      end
    end

    def duration_in_words
      distance_of_time(bulk_export.duration) if bulk_export.duration
    end
  end
end
