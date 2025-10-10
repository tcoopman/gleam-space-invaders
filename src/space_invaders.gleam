import engine
import game
import gleam/dynamic.{type Dynamic}
import gleam/dynamic/decode
import gleam/float
import gleam/int
import gleam/list
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
const max = 100.0

const size = 800

pub fn main() {
  canvas.define_web_component()
  let app = lustre.application(init, update, view)
  let assert Ok(runtime) = lustre.start(app, "#app", Nil)
  add_event_listener("keydown", fn(e) {
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
  Ready(previous_time: Float, fps: Float, game: game.State)
}

fn init(_) -> #(Model, Effect(Msg)) {
  #(Idle, schedule_next_frame())
}

// UPDATE ----------------------------------------------------------------------

type Msg {
  Tick(time: Float)
  UserPressedKey(key: String)
}

fn update_game(model: Model, cmd: game.Command) -> Model {
  let assert Ready(game:, ..) = model
  Ready(..model, game: game.apply(cmd, game))
}

fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  let model = case model {
    Idle -> Ready(0.0, 0.0, game.create_game())
    _ -> model
  }
  let assert Ready(..) = model

  case msg {
    Tick(current_time) -> {
      let frame_time = calc_frame_time(model, current_time)
      let fps = case float.divide(1000.0, frame_time) {
        Ok(fps) -> fps
        _ -> 60.0
      }
      let model = update_game(model, game.Tick)
      let assert Ready(..) = model
      #(
        Ready(..model, previous_time: current_time, fps: fps),
        schedule_next_frame(),
      )
    }
    UserPressedKey(key) -> {
      case key {
        "a" -> #(update_game(model, game.MoveLeft), effect.none())
        "d" -> #(update_game(model, game.MoveRight), effect.none())
        "s" -> #(update_game(model, game.Shoot), effect.none())
        "e" -> #(
          update_game(
            model,
            game.IntroduceEnemy(int.random(100), int.random(20) + 50),
          ),
          effect.none(),
        )
        _ -> #(model, effect.none())
      }
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

fn space_ship(side) -> p.Picture {
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

fn render_enemies(enemies, side_size, size) -> p.Picture {
  p.combine({
    list.map(enemies, fn(enemy) {
      let game.Enemy(position: game.Position(x:, y:), width:) = enemy
      let enemy_x = int.to_float(x) *. side_size
      let enemy_y = size -. int.to_float(y) *. side_size
      p.rectangle(int.to_float(width) *. side_size, 50.0)
      |> p.fill(colour.light_orange)
      |> p.translate_xy(enemy_x, enemy_y)
    })
  })
}

fn render_bullets(bullets, side_size, size) -> p.Picture {
  p.combine(
    list.map(bullets, fn(bullet) {
      let game.Position(x:, y:) = bullet
      let bullet_x = int.to_float(x) *. side_size
      let bullet_y = size -. int.to_float(y) *. side_size
      p.rectangle(side_size, 30.0)
      |> p.fill(colour.red)
      |> p.translate_xy(bullet_x +. 2.0 *. side_size, bullet_y)
    }),
  )
}

// const scale = 100.0

fn render_game(game: game.State) -> p.Picture {
  let size = int.to_float(size)
  let steps = max +. 5.0
  let side_size = size /. steps

  let ship = space_ship(side_size)
  let game.Playing(
    spaceship: game.Spaceship(position:, bullets:, ..),
    enemies:,
    ..,
  ) = game

  let spaceship_position = int.to_float(position) *. side_size
  p.combine([
    ship
      |> p.translate_xy(spaceship_position, size -. side_size *. 3.0),
    render_bullets(bullets, side_size, size),
    render_enemies(enemies, side_size, size),
  ])
}

// VIEW ------------------------------------------------------------------------
// 
// 
fn view(model: Model) -> Element(Msg) {
  case model {
    Idle -> html.p([], [html.text("Initializing")])
    Ready(_previous_time, _fps, game) -> {
      html.div([], [
        canvas(render_game(game), [
          attribute.height(size),
          attribute.width(size),
          attribute.style("background", "black"),
          attribute.style("line-height", "0"),
        ]),
        // html.div([], [render_debugger(model)]),
      ])
    }
  }
}

fn render_debugger(model: Model) {
  case model {
    Idle -> html.p([], [html.text("Initializing")])
    Ready(previous_time, fps, ..) -> {
      html.p([], [
        float.to_string(previous_time) |> html.text,
        html.text(" • "),
        float.to_string(fps) |> html.text,
      ])
    }
  }
}
