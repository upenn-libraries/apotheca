# frozen_string_literal: true

# Pin npm packages by running ./bin/importmap

pin 'application', preload: true

pin 'popper', to: 'popper.js', preload: true
pin 'bootstrap', to: 'bootstrap.min.js', preload: true
pin '@hotwired/stimulus', to: 'stimulus.min.js', preload: true
pin '@hotwired/stimulus-loading', to: 'stimulus-loading.js', preload: true
pin_all_from 'app/javascript/controllers', under: 'controllers'

# Iterating through the controllers in the app/components directory and pinning them.
components_path = Rails.root.join('app/components')
components_path.glob('**/*_controller.js').each do |controller|
  name = controller.relative_path_from(components_path).to_s.remove(/\.js$/)

  pin "components/#{name}", to: "#{name}.js"
end