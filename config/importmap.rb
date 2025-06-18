pin "application", preload: true
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus",      to: "stimulus.min.js"

# Load all of your Stimulus controllers from app/javascript/controllers
pin_all_from "app/javascript/controllers", under: "controllers"

# Explicitly pin the two controllers you wrote
pin "controllers/renegotiations_controller",    to: "controllers/renegotiations_controller.js"
pin "controllers/renegotiation_show_controller", to: "controllers/renegotiation_show_controller.js"

# Third-party libraries
pin "bootstrap",           to: "bootstrap.min.js", preload: true
pin "@popperjs/core",      to: "popper.js",          preload: true

# Your main entrypoint
pin "application", to: "application.js"
