import engine
import gleam/float
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
  Ready(previous_time: Float, fps: Float)
}

fn init(_) -> #(Model, Effect(Msg)) {
  #(Idle, schedule_next_frame())
}

// UPDATE ----------------------------------------------------------------------

type Msg {
  Tick(time: Float)
}

fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    Tick(current_time) -> {
      let frame_time = calc_frame_time(model, current_time)
      // Since division by 0 is illegal the division function
      // returns a Result type we need to pattern match on.
      let fps = case float.divide(1000.0, frame_time) {
        Ok(fps) -> fps
        _ -> 60.0
      }
      #(Ready(previous_time: current_time, fps: fps), schedule_next_frame())
    }
  }
}

fn calc_frame_time(model: Model, current_time: Float) {
  case model {
    Ready(previous_time, ..) -> float.subtract(current_time, previous_time)
    _ -> 0.0
  }
}

fn schedule_next_frame() {
  effect.from(fn(dispatch) {
    engine.request_animation_frame(fn(timestamp) { dispatch(Tick(timestamp)) })
  })
}

// VIEW ------------------------------------------------------------------------

fn view(model: Model) -> Element(Msg) {
  html.div([], [html.canvas([]), html.div([], [render_debugger(model)])])
}

fn render_debugger(model: Model) {
  case model {
    Idle -> html.p([], [html.text("Initializing")])
    Ready(previous_time, fps) -> {
      html.p([], [
        float.to_string(previous_time) |> html.text,
        html.text(" • "),
        float.to_string(fps) |> html.text,
      ])
    }
  }
}
