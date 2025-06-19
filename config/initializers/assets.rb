
Rails.application.config.assets.version = "1.0"

# Tell Sprockets where to find your JS/controllers
Rails.application.config.assets.paths << Rails.root.join("app/javascript")
Rails.application.config.assets.paths << Rails.root.join("app/javascript/controllers")

# Precompile *all* your Stimulus controllers
Rails.application.config.assets.precompile += %w[
  controllers/*.js
]

# Any other assets you were already precompiling
Rails.application.config.assets.precompile += %w[
  bootstrap.min.js popper.js template_upload.csv
]
