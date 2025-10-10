import engine
import gleam/dynamic.{type Dynamic}
import gleam/dynamic/decode
import gleam/float
import gleam/int
import gleam_community/colour
import lustre
import lustre/attribute
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html

// import lustre/event
import paint as p
import paint/canvas
import paint/encode

@external(javascript, "./app.ffi.mjs", "addGlobalEventListener")
fn add_event_listener(name: String, handler: fn(Dynamic) -> any) -> Nil

// MAIN ------------------------------------------------------------------------
const max = 40.0

pub fn main() {
  canvas.define_web_component()
  let app = lustre.application(init, update, view)
  let assert Ok(runtime) = lustre.start(app, "#app", Nil)
  add_event_listener("keypress", fn(e) {
    let decoder = {
      use key <- decode.field("key", decode.string)
      key |> decode.success
    }
    let result = decode.run(e, decoder)
    let assert Ok(value) = result
    lustre.dispatch(UserPressedKey(value))
    |> lustre.send(runtime, _)
  })

  Nil
}

// MODEL -----------------------------------------------------------------------
type Model {
  Idle
  Ready(previous_time: Float, fps: Float, x: Float)
}

fn init(_) -> #(Model, Effect(Msg)) {
  #(Idle, schedule_next_frame())
}

// UPDATE ----------------------------------------------------------------------

type Msg {
  Tick(time: Float)
  UserPressedKey(key: String)
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
      #(
        Ready(previous_time: current_time, fps: fps, x: max),
        schedule_next_frame(),
      )
    }
    UserPressedKey(key) -> {
      echo key
      #(model, schedule_next_frame())
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

pub fn space_ship(side) -> p.Picture {
  let assert Ok(green) = colour.from_rgba_hex_string("#00CCC00FF")

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
  |> p.fill(green)
  |> p.stroke(green, width: 0.0)
}

fn canvas(picture: p.Picture, attributes: List(attribute.Attribute(a))) {
  element.element(
    "paint-canvas",
    [attribute.attribute("picture", encode.to_string(picture)), ..attributes],
    [],
  )
}

// const scale = 100.0

fn game(x: Float) -> p.Picture {
  let size = int.to_float(size)
  let steps = max +. 5.0
  let side_size = size /. steps

  let ship = space_ship(side_size)
  let position = x *. side_size

  ship
  |> p.translate_xy(position, size -. side_size *. 3.0)
}

// VIEW ------------------------------------------------------------------------
// 
// 
fn view(model: Model) -> Element(Msg) {
  case model {
    Idle -> html.p([], [html.text("Initializing")])
    Ready(_previous_time, _fps, x) -> {
      html.div([], [
        canvas(game(x), [
          attribute.height(size),
          attribute.width(size),
          attribute.style("background", "black"),
          attribute.style("line-height", "0"),
        ]),
        html.div([], [render_debugger(model)]),
      ])
    }
  }
}

fn render_debugger(model: Model) {
  case model {
    Idle -> html.p([], [html.text("Initializing")])
    Ready(previous_time, fps, x) -> {
      html.p([], [
        float.to_string(previous_time) |> html.text,
        html.text(" • x:"),
        float.to_string(x) |> html.text,
        html.text(" • "),
        float.to_string(fps) |> html.text,
      ])
    }
  }
}
