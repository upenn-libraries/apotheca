# frozen_string_literal: true

# Spec helpers when working with the JSON API
module APIHelpers
  def json_body
    JSON.parse response.body, symbolize_names: true
  end
end
