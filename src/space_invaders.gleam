import engine
import gleam/float
import gleam/int
import gleam/list
import gleam_community/colour
import lustre
import lustre/attribute
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html
import paint as p
import paint/canvas
import paint/encode

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

const size = 800

pub fn space_ship() -> p.Picture {
  let assert Ok(semi_transparent) = colour.from_rgba_hex_string("#00CCC00FF")
  let assert Ok(transparent) = colour.from_rgba(1.0, 1.0, 1.0, 0.0)

  let side = 14.0
  p.combine([
    p.rectangle(side *. 5.0, side)
      |> p.translate_x(0.0)
      |> p.translate_y(side *. 2.0),

    p.rectangle(side *. 3.0, side)
      |> p.translate_x(side)
      |> p.translate_y(side),
    p.rectangle(side, side)
      |> p.translate_x(side *. 2.0)
      |> p.translate_y(0.0),
  ])
  |> p.fill(semi_transparent)
  |> p.stroke(transparent, width: 0.0)
}

fn canvas(picture: p.Picture, attributes: List(attribute.Attribute(a))) {
  element.element(
    "paint-canvas",
    [attribute.attribute("picture", encode.to_string(picture)), ..attributes],
    [],
  )
}

// VIEW ------------------------------------------------------------------------
// 
// 
fn view(model: Model) -> Element(Msg) {
  canvas.define_web_component()
  html.div([], [
    canvas(space_ship(), [
      attribute.height(size),
      attribute.width(size),
      attribute.style("background", "black"),
      attribute.style("line-height", "0"),
    ]),
    html.div([], [render_debugger(model)]),
  ])
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
