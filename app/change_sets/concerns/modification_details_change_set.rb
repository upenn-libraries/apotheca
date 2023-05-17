# frozen_string_literal: true

# ChangeSet for Asset Modification Details
module ModificationDetailsChangeSet
  extend ActiveSupport::Concern

  included do
    property :date_created, multiple: false, required: false
    property :created_by, multiple: false, required: true
    property :updated_by, multiple: false, required: true

    validates :created_by, :updated_by, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP } # Validate emails
  end
end
