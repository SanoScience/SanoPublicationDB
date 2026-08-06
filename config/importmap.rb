# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"
pin "@nathanvda/cocoon", to: "https://ga.jspm.io/npm:@nathanvda/cocoon@1.2.14/cocoon.js"
pin "@rails/ujs", to: "rails-ujs.js"
pin "@floating-ui/dom", to: "https://cdn.jsdelivr.net/npm/@floating-ui/dom@1.7.3/+esm"
pin "chart.js", to: "https://cdn.jsdelivr.net/npm/chart.js@4.4.2/dist/chart.umd.js"
pin "chartjs-adapter-date-fns", to: "https://cdn.jsdelivr.net/npm/chartjs-adapter-date-fns@3.0.0/dist/chartjs-adapter-date-fns.bundle.min.js"
pin "chartkick" # @5.0.1
pin "@kurkle/color", to: "@kurkle--color.js" # @0.3.4
