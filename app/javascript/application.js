// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails

import "@hotwired/turbo-rails"
import "popper"
import "bootstrap"
import "controllers"

// Disabling Turbo by default.
//
// Unexpected errors from form submissions are not displayed to the user. An error is logged in the
// javascript console, but the user gets no feedback. We will use Turbo in places were we can
// account for this by adding custom JS.
Turbo.session.drive = false