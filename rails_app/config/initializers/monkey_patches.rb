# frozen_string_literal: true

# Require all Ruby files in the core_extensions directory
Dir[Rails.root.join('lib/core_extensions/*.rb')].each { |f| require f }
