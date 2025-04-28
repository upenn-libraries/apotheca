# frozen_string_literal: true

module API
  module IIIF
    # Base controller for IIIF API-compliant responses
    class BaseController < ApplicationController
      include ApiBehaviors
    end
  end
end
