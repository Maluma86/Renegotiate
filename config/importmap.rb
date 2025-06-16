# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"
pin "bootstrap", to: "bootstrap.min.js", preload: true
pin "@popperjs/core", to: "popper.js", preload: true

# Chartkick & Chart.js for data viz
pin "chartkick", to: "chartkick.esm.js" # uses Chart.js under the hood
pin "chart.js", to: "chart.js.js"
pin "@kurkle/color", to: "@kurkle--color.js"
