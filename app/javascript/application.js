
import "@hotwired/turbo-rails"
import { Application } from "@hotwired/stimulus"

import RenegotiationsController     from "controllers/renegotiations_controller"
import RenegotiationShowController  from "controllers/renegotiation_show_controller"
import AiIntelligenceController      from "controllers/ai_intelligence_controller"

// 1) Start Stimulus
const application = Application.start()

// 2) Register your controllers
application.register("renegotiations",     RenegotiationsController)
application.register("renegotiation-show",  RenegotiationShowController)
application.register("ai-intelligence",     AiIntelligenceController)
