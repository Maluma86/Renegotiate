Rails.application.config.assets.version = "1.0"

# Tell Sprockets where to find your Stimulus controllers
Rails.application.config.assets.paths << Rails.root.join("app/javascript")
Rails.application.config.assets.paths << Rails.root.join("app/javascript/controllers")

# Precompile your controllers so they show up under /assets/controllers/*.js
Rails.application.config.assets.precompile += %w[
  controllers/renegotiations_controller.js
  controllers/renegotiation_show_controller.js
]

# Any other assets you already precompile…
Rails.application.config.assets.precompile += %w( bootstrap.min.js popper.js template_upload.csv )
