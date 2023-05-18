# frozen_string_literal: true

# Single point of entry for all the customizations and extensions needed for an application
class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class
end
