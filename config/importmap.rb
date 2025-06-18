pin "application", preload: true
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus",      to: "stimulus.min.js"

# Pin your entrypoint
pin_all_from "app/javascript/controllers", under: "controllers"
pin "controllers/renegotiations_controller", to: "controllers/renegotiations_controller.js"
pin "controllers/renegotiation_show_controller", to: "controllers/renegotiation_show_controller.js"

pin "application", to: "application.js"
