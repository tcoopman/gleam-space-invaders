import game.{MoveLeft, MoveRight, Playing, Position, Shoot, Spaceship, Tick}
import gleeunit

pub fn main() -> Nil {
  gleeunit.main()
}

pub fn when_we_start_the_game_we_have_a_spaceship_test() {
  let state = game.create_game()
  assert 50 == spaceship_position(state)
}

pub fn move_left_relocates_spaceship_test() {
  let state =
    game.create_game()
    |> game.apply(MoveLeft, _)

  assert 49 == spaceship_position(state)
}

pub fn move_left_twice_relocates_spaceship_test() {
  let state =
    game.create_game()
    |> game.apply(MoveLeft, _)
    |> game.apply(MoveLeft, _)

  assert 48 == spaceship_position(state)
}

pub fn move_left_against_boundaries_stops_spaceship_test() {
  let state = game.create_game() |> spaceship_on_position(0)
  assert 0 == spaceship_position(state)
}

pub fn move_right_against_boundaries_stops_spaceship_test() {
  let state =
    game.create_game()
    |> spaceship_on_position(99)
    |> game.apply(MoveRight, _)
    |> game.apply(MoveRight, _)
  assert 100 == spaceship_position(state)
}

pub fn when_shooting_the_bullet_has_the_spaceship_position_test() {
  let state = game.create_game() |> game.apply(Shoot, _)
  let assert Playing(Spaceship(bullets: [position], ..)) = state
  assert Position(50, 5) == position
}

pub fn bullet_moves_forward_after_tick_test() {
  let state = game.create_game() |> game.apply(Shoot, _) |> game.apply(Tick, _)
  let assert Playing(Spaceship(bullets: [position], ..)) = state
  assert Position(50, 5 + 1) == position
}

fn spaceship_position(state) {
  let Playing(Spaceship(position:, ..)) = state
  position
}

fn spaceship_on_position(state, position) {
  let Playing(spaceship) = state
  Playing(..state, spaceship: Spaceship(..spaceship, position:))
}
