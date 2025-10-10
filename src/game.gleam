const board_width = 100

const board_height = 100

const spaceship_height = 5

pub type Position {
  Position(x: Int, y: Int)
}

pub type Spaceship {
  Spaceship(position: Int, bullets: List(Position), height: Int)
}

pub type Board {
  Board(height: Int, width: Int)
}

pub type State {
  Playing(board: Board, spaceship: Spaceship)
}

pub type Command {
  MoveLeft
  MoveRight
  Shoot
  Tick
}

pub fn create_game() -> State {
  Playing(
    spaceship: Spaceship(position: 50, bullets: [], height: spaceship_height),
    board: Board(width: board_width, height: board_height),
  )
}

pub fn apply(cmd: Command, state: State) -> State {
  let Playing(spaceship:, ..) = state
  let spaceship = case spaceship, cmd {
    Spaceship(position: 0, ..), MoveLeft -> spaceship
    Spaceship(position:, ..), MoveRight if position == board_width -> spaceship
    Spaceship(position: current, ..), MoveLeft ->
      Spaceship(..spaceship, position: current - 1)
    Spaceship(position: current, ..), MoveRight ->
      Spaceship(..spaceship, position: current + 1)
    Spaceship(position:, height:, ..), Shoot ->
      Spaceship(..spaceship, bullets: [Position(position, height)])
    Spaceship(bullets:, ..), Tick -> {
      let bullets = case bullets {
        [] -> []
        [Position(x:, y:)] -> [Position(x, y + 1)]
        _ -> bullets
      }
      Spaceship(..spaceship, bullets: bullets)
    }
  }
  Playing(..state, spaceship:)
}
