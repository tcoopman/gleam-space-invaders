import gleeunit

pub fn main() -> Nil {
  gleeunit.main()
}

// const grid_width = 100

// const grid_height = 100

// const spaceship_width = 5
const spaceship_height = 5

type Position {
  Position(x: Int, y: Int)
}

type State {
  Playing(spaceship_position: Int, bullet_position: List(Position))
}

type Command {
  MoveLeft
  MoveRight
  Shoot
  Tick
}

fn create_game() -> State {
  Playing(spaceship_position: 50, bullet_position: [])
}

fn apply(cmd: Command, state: State) -> State {
  case state, cmd {
    Playing(0, _), MoveLeft -> state
    Playing(current, _), MoveLeft ->
      Playing(..state, spaceship_position: current - 1)
    Playing(100, _), MoveRight -> state
    Playing(current, _), MoveRight ->
      Playing(..state, spaceship_position: current + 1)
    Playing(current, ..), Shoot ->
      Playing(..state, bullet_position: [Position(current, spaceship_height)])
    Playing(bullet_position:, ..), Tick -> {
      let assert [Position(x, y)] = bullet_position
      Playing(..state, bullet_position: [Position(x, y + 1)])
    }
  }
}

pub fn when_we_start_the_game_we_have_a_spaceship_test() {
  let state = create_game()
  let Playing(spaceship_position, _) = state
  assert 50 == spaceship_position
}

pub fn move_left_relocates_spaceship_test() {
  let state =
    create_game()
    |> apply(MoveLeft, _)

  let Playing(spaceship_position, _) = state
  assert 49 == spaceship_position
}

pub fn move_left_twice_relocates_spaceship_test() {
  let state =
    create_game()
    |> apply(MoveLeft, _)
    |> apply(MoveLeft, _)

  let Playing(spaceship_position, _) = state
  assert 48 == spaceship_position
}

pub fn move_left_against_boundaries_stops_spaceship_test() {
  let Playing(spaceship_position, _) = Playing(0, []) |> apply(MoveLeft, _)
  assert 0 == spaceship_position
}

pub fn move_right_against_boundaries_stops_spaceship_test() {
  let Playing(spaceship_position, _) =
    Playing(99, [])
    |> apply(MoveRight, _)
    |> apply(MoveRight, _)
  assert 100 == spaceship_position
}

pub fn when_shooting_the_bullet_has_the_spaceship_position_test() {
  let assert Playing(bullet_position: [position], ..) =
    Playing(50, [])
    |> apply(Shoot, _)
  assert Position(50, spaceship_height) == position
}

pub fn bullet_moves_forward_after_tick_test() {
  let assert Playing(bullet_position: [position], ..) =
    Playing(50, [])
    |> apply(Shoot, _)
    |> apply(Tick, _)
  assert Position(50, spaceship_height + 1) == position
}
