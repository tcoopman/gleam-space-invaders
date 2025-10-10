// const grid_width = 100

// const grid_height = 100

// const spaceship_width = 5
const spaceship_height = 5

pub type Position {
  Position(x: Int, y: Int)
}

pub type Spaceship {
  Spaceship(position: Int, bullets: List(Position), height: Int)
}

pub type State {
  Playing(spaceship: Spaceship)
}

pub type Command {
  MoveLeft
  MoveRight
  Shoot
  Tick
}

pub fn create_game() -> State {
  Playing(spaceship: Spaceship(
    position: 50,
    bullets: [],
    height: spaceship_height,
  ))
}

pub fn apply(cmd: Command, state: State) -> State {
  let Playing(spaceship) = state
  let spaceship = case spaceship, cmd {
    Spaceship(position: 0, ..), MoveLeft -> spaceship
    Spaceship(position: 100, ..), MoveRight -> spaceship
    Spaceship(position: current, ..), MoveLeft ->
      Spaceship(..spaceship, position: current - 1)
    Spaceship(position: current, ..), MoveRight ->
      Spaceship(..spaceship, position: current + 1)
    Spaceship(position:, height:, ..), Shoot ->
      Spaceship(..spaceship, bullets: [Position(position, height)])
    Spaceship(bullets:, ..), Tick -> {
      let assert [Position(x:, y:)] = bullets
      Spaceship(..spaceship, bullets: [Position(x, y + 1)])
    }
  }
  Playing(..state, spaceship:)
}
