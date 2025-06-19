import { application } from "./application"
import ResetFormController from "./reset_form_controller"
import RenegotiationsController from "./renegotiations_controller"
import RenegotiationShowController from "./renegotiation_show_controller"

application.register("renegotiations", RenegotiationsController)
application.register("renegotiation-show", RenegotiationShowController)
application.register("reset-form", ResetFormController)
