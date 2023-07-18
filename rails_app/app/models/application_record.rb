# frozen_string_literal: true

# Parent class for all database models.
class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class
end
