import lustre
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html

// MAIN ------------------------------------------------------------------------

pub fn main() {
  let app = lustre.application(init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", Nil)

  Nil
}

// MODEL -----------------------------------------------------------------------

type Model {
  Idle
}

fn init(_) -> #(Model, Effect(Msg)) {
  #(Idle, effect.none())
}

// UPDATE ----------------------------------------------------------------------

type Msg {
  ToDo
}

fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    _ -> #(model, effect.none())
  }
}

// VIEW ------------------------------------------------------------------------

fn view(model: Model) -> Element(Msg) {
  html.div([], [
    html.canvas([]),
  ])
}
