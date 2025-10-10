import gleam/list

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

pub type Enemy {
  Enemy(position: Position, width: Int)
}

pub type State {
  Playing(board: Board, spaceship: Spaceship, enemies: List(Enemy))
}

pub type Command {
  MoveLeft
  MoveRight
  Shoot
  Tick
  IntroduceEnemy(x: Int, y: Int)
}

pub fn create_game() -> State {
  Playing(
    spaceship: Spaceship(position: 50, bullets: [], height: spaceship_height),
    board: Board(width: board_width, height: board_height),
    enemies: [],
  )
}

type Event {
  BulletRemoved(Position)
  EnemyDied(Position)
}

pub fn apply(cmd: Command, state: State) -> State {
  let Playing(spaceship:, enemies:, ..) = state
  case spaceship, cmd {
    Spaceship(position: 0, ..), MoveLeft -> Playing(..state, spaceship:)
    Spaceship(position:, ..), MoveRight if position == board_width ->
      Playing(..state, spaceship:)
    Spaceship(position:, ..), MoveLeft ->
      Playing(
        ..state,
        spaceship: Spaceship(..spaceship, position: position - 1),
      )
    Spaceship(position:, ..), MoveRight ->
      Playing(
        ..state,
        spaceship: Spaceship(..spaceship, position: position + 1),
      )
    Spaceship(position:, height:, bullets:), Shoot ->
      Playing(
        ..state,
        spaceship: Spaceship(..spaceship, bullets: [
          Position(position, height),
          ..bullets
        ]),
      )
    Spaceship(bullets:, ..), Tick -> {
      let bullets =
        bullets
        |> list.filter_map(fn(bullet) {
          let Position(x:, y:) = bullet
          case y + 1 > board_height {
            True -> Error("")
            False -> Ok(Position(x, y + 1))
          }
        })

      let events =
        list.flat_map(bullets, fn(bullet) {
          let Position(x:, y:) = bullet

          list.flat_map(enemies, fn(enemy) {
            let Enemy(Position(x: enemy_x, y: enemy_y), width:) = enemy
            case
              y == enemy_y && enemy_x - width / 2 < x && enemy_x + width / 2 > x
            {
              True -> [
                BulletRemoved(Position(x, y)),
                EnemyDied(Position(x: enemy_x, y: enemy_y)),
              ]
              False -> []
            }
          })
        })
      let bullets =
        list.filter(bullets, fn(bullet) {
          !list.any(events, fn(event) {
            case event {
              BulletRemoved(pos) -> pos == bullet
              _ -> False
            }
          })
        })
      let enemies =
        list.filter(enemies, fn(enemy) {
          let Enemy(enemy_position, ..) = enemy
          !list.any(events, fn(event) {
            case event {
              EnemyDied(pos) -> pos == enemy_position
              _ -> False
            }
          })
        })

      Playing(
        ..state,
        spaceship: Spaceship(..spaceship, bullets: bullets),
        enemies:,
      )
    }
    _, IntroduceEnemy(x:, y:) -> {
      let Playing(enemies:, ..) = state
      Playing(..state, enemies: [Enemy(Position(x, y), width: 6), ..enemies])
    }
  }
}
