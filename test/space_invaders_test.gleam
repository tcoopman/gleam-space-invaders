import gleeunit

pub fn main() -> Nil {
  gleeunit.main()
}

const grid_width = 100

const grid_height = 100

const spaceship_width = 5

type State {
  Playing(spaceship_position: Int)
}

type Command {
  MoveLeft
  MoveRight
}

fn create_game() -> State {
  Playing(50)
}

pub fn when_we_start_the_game_we_have_a_spaceship_test() {
  let state = create_game()
  let Playing(spaceship_position) = state
  assert 50 == spaceship_position
}
