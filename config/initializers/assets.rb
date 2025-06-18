# Be sure to restart your server when you modify this file.

Rails.application.config.assets.version = "1.0"

# Include your JS folders
Rails.application.config.assets.paths << Rails.root.join("app/javascript")
Rails.application.config.assets.paths << Rails.root.join("app/javascript/controllers")

# Precompile your Stimulus controllers
Rails.application.config.assets.precompile += %w[
  controllers/renegotiations_controller.js
  controllers/renegotiation_show_controller.js
]

# Any other assets you already compile
Rails.application.config.assets.precompile += %w[ bootstrap.min.js popper.js template_upload.csv ]
