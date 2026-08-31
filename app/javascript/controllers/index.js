// App-wide Stimulus controllers (component controllers auto-register via
// app/components/index.js). Register new ones here explicitly.
import { application } from "./application"

import RoutineFormController from "./routine_form_controller"
application.register("routine-form", RoutineFormController)

import ConnectionFormController from "./connection_form_controller"
application.register("connection-form", ConnectionFormController)
