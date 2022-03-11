# frozen_string_literal: true

# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = '1.0'

# Add additional assets to the asset load path.
# FIXME: We need to add `app` to the assets paths so that component javascript is added to the importmap.
#        While this isn't the best solution its the one that works for now.
Rails.application.config.assets.paths << Rails.root.join('app')

# Precompile additional assets.
# application.js, application.css, and all non-JS/CSS in the app/assets
# folder are already added.
Rails.application.config.assets.precompile += %w( bootstrap.min.js popper.js )

# Adding additional js assets that are outside of app/javascript
Rails.application.config.importmap.cache_sweepers << Rails.root.join('app/components')
