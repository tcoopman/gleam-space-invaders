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
            game.IntroduceEnemy(int.random(50), int.random(50) + 20),
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

fn schedule_next_frame() -> Effect(Msg) {
  use dispatch, _ <- effect.after_paint
  dispatch(Tick(0.0))
}

fn space_ship(grid_size) -> p.Picture {
  let assert Ok(green) = colour.from_rgba_hex_string("#00CCC00FF")
  let width = grid_size *. 5.0

  p.combine([
    p.rectangle(width, grid_size)
      |> p.translate_x(0.0)
      |> p.translate_y(grid_size *. 2.0),

    p.rectangle(grid_size *. 3.0, grid_size)
      |> p.translate_x(grid_size)
      |> p.translate_y(grid_size),
    p.rectangle(grid_size, grid_size)
      |> p.translate_x(grid_size *. 2.0)
      |> p.translate_y(0.0),
  ])
  |> p.fill(green)
  |> p.stroke(green, width: 0.0)
  |> p.translate_x(width /. -2.0)
}

fn canvas(picture: p.Picture, attributes: List(attribute.Attribute(a))) {
  element.element(
    "paint-canvas",
    [attribute.attribute("picture", encode.to_string(picture)), ..attributes],
    [],
  )
}

fn render_enemies(enemies, grid_size, size) -> p.Picture {
  p.combine({
    list.map(enemies, fn(enemy) {
      let game.Enemy(position: game.Position(x:, y:), width:) = enemy
      let enemy_x = int.to_float(x - width / 2) *. grid_size
      let enemy_y = size -. int.to_float(y) *. grid_size

      let enemy_height = 50.0
      p.rectangle(int.to_float(width) *. grid_size, enemy_height)
      |> p.translate_y(-1.0 *. enemy_height)
      |> p.fill(colour.light_orange)
      |> p.translate_xy(enemy_x, enemy_y)
    })
  })
}

fn render_bullets(bullets, grid_size, size) -> p.Picture {
  p.combine(
    list.map(bullets, fn(bullet) {
      let game.Position(x:, y:) = bullet
      let bullet_x = { int.to_float(x) -. 5.0 /. 2.0 } *. grid_size
      let bullet_y = size -. int.to_float(y) *. grid_size
      p.rectangle(grid_size, 30.0)
      |> p.fill(colour.red)
      |> p.translate_xy(bullet_x +. 2.0 *. grid_size, bullet_y)
    }),
  )
}

fn render_enemy_bullets(bullets, grid_size, size) -> p.Picture {
  p.combine(
    list.map(bullets, fn(bullet) {
      let game.Position(x:, y:) = bullet
      let bullet_x = { int.to_float(x) -. 5.0 /. 2.0 } *. grid_size
      let bullet_y = size -. int.to_float(y) *. grid_size
      let bullet_height = 30.0
      p.rectangle(grid_size, bullet_height)
      |> p.translate_y(bullet_height *. -1.0)
      |> p.fill(colour.blue)
      |> p.translate_xy(bullet_x +. 2.0 *. grid_size, bullet_y)
    }),
  )
}

// const scale = 100.0

fn render_game(game: game.State) -> p.Picture {
  let screen_pixels = int.to_float(size)
  let grid_size = screen_pixels /. max

  let ship = space_ship(grid_size)
  let game.Playing(
    spaceship: game.Spaceship(position:, bullets:, ..),
    enemies:,
    enemy_bullets:,
    ..,
  ) = game

  let spaceship_position = int.to_float(position) *. grid_size
  let enemy_bullets = list.map(enemy_bullets, fn(b) { b.position })
  p.combine([
    ship
      |> p.translate_xy(spaceship_position, screen_pixels -. 8.0 *. 3.0),
    render_bullets(bullets, 8.0, screen_pixels),
    render_enemies(enemies, 8.0, screen_pixels),
    render_enemy_bullets(enemy_bullets, 8.0, screen_pixels),
    p.rectangle(2.0, 800.0)
      |> p.translate_x(800.0 /. 2.0 -. 1.0)
      |> p.fill(colour.white),
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
