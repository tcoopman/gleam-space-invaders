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
  ShipMoved(Int)
  BulletShot(Position)
  BulletMoved(from: Position, to: Position)
  EnemyAdded(Enemy)
  EnemyMoved(Position)
}

pub fn apply(cmd: Command, state: State) -> State {
  let Playing(spaceship:, enemies:, ..) = state
  let events = case spaceship, cmd {
    Spaceship(position: 0, ..), MoveLeft -> []
    Spaceship(position:, ..), MoveRight if position == board_width -> []
    Spaceship(position:, ..), MoveLeft -> [ShipMoved(position - 1)]
    Spaceship(position:, ..), MoveRight -> [ShipMoved(position + 1)]
    Spaceship(position:, height:, ..), Shoot -> [
      BulletShot(Position(position, height)),
    ]
    Spaceship(bullets:, ..), Tick -> {
      let e1 =
        bullets
        |> list.map(fn(bullet) {
          let Position(x:, y:) = bullet
          case y + 1 > board_height {
            True -> BulletRemoved(bullet)
            False -> BulletMoved(Position(x, y), Position(x, y + 1))
          }
        })

      let e2 =
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
      list.append(e1, e2)
    }

    _, IntroduceEnemy(x:, y:) -> [EnemyAdded(Enemy(Position(x, y), width: 6))]
  }
  apply_state(state, events)
}

fn apply_state(state, events) {
  echo events
  list.fold(events, state, fn(state, event) {
    let Playing(spaceship:, enemies:, ..) = state
    let Spaceship(bullets:, ..) = spaceship

    case event {
      ShipMoved(pos) ->
        Playing(..state, spaceship: Spaceship(..spaceship, position: pos))
      BulletMoved(from, to) -> {
        let bullets =
          list.map(bullets, fn(bullet) {
            case bullet == from {
              True -> to
              False -> bullet
            }
          })
        Playing(..state, spaceship: Spaceship(..spaceship, bullets: bullets))
      }
      BulletRemoved(pos) -> {
        let bullets = list.filter(bullets, fn(bullet) { bullet != pos })
        Playing(..state, spaceship: Spaceship(..spaceship, bullets: bullets))
      }
      BulletShot(bullet) ->
        Playing(
          ..state,
          spaceship: Spaceship(..spaceship, bullets: [bullet, ..bullets]),
        )
      EnemyAdded(enemy) -> Playing(..state, enemies: [enemy, ..enemies])

      EnemyDied(pos) -> {
        let enemies =
          list.filter(enemies, fn(enemy) {
            let Enemy(enemy_position, ..) = enemy
            pos != enemy_position
          })
        Playing(..state, enemies:)
      }
      EnemyMoved(_) -> todo
    }
    // let bullets =
    //   list.filter(bullets, fn(bullet) {
    //     !list.any(events, fn(event) {
    //       case event {
    //         BulletRemoved(pos) -> pos == bullet
    //         _ -> False
    //       }
    //     })
    //   })
    // let enemies =
    //   list.filter(enemies, fn(enemy) {
    //     let Enemy(enemy_position, ..) = enemy
    //     !list.any(events, fn(event) {
    //       case event {
    //         EnemyDied(pos) -> pos == enemy_position
    //         _ -> False
    //       }
    //     })
    //   })
    // Playing(
    //   ..state,
    //   spaceship: Spaceship(..spaceship, bullets: bullets),
    //   enemies:,
    // )
  })
}
