import gleam/list

const board_width = 100

const board_height = 100

const spaceship_height = 5

pub type Position {
  Position(x: Int, y: Int)
}

pub type Spaceship {
  Spaceship(position: Int, bullets: List(Position), height: Int, width: Int)
}

pub type Board {
  Board(height: Int, width: Int)
}

pub type Enemy {
  Enemy(position: Position, width: Int)
}

pub type Bullet {
  Bullet(id: Int, position: Position, count_down: Int)
}

pub type State {
  Playing(
    last_id: Int,
    board: Board,
    spaceship: Spaceship,
    enemies: List(Enemy),
    enemy_bullets: List(Bullet),
  )
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
    last_id: 0,
    spaceship: Spaceship(
      position: 50,
      bullets: [],
      height: spaceship_height,
      width: spaceship_height,
    ),
    board: Board(width: board_width, height: board_height),
    enemies: [],
    enemy_bullets: [],
  )
}

type Event {
  IdIncreased
  BulletRemoved(Position)
  EnemyDied(Position)
  ShipMoved(Int)
  BulletShot(Position)
  BulletMoved(from: Position, to: Position)
  EnemyAdded(Enemy)
  EnemyMoved(Position)
  EnemyBulletShot(Bullet)
  EnemyBulletUpdated(Bullet)
  EnemyBulletRemoved(Int)
  WeDied
}

pub fn apply(cmd: Command, state: State) -> State {
  let Playing(spaceship:, enemies:, enemy_bullets:, ..) = state
  let events = case spaceship, cmd {
    Spaceship(position: 0, ..), MoveLeft -> []
    Spaceship(position:, ..), MoveRight if position == board_width -> []
    Spaceship(position:, ..), MoveLeft -> [ShipMoved(position - 1)]
    Spaceship(position:, ..), MoveRight -> [ShipMoved(position + 1)]
    Spaceship(position:, height:, ..), Shoot -> [
      BulletShot(Position(position, height)),
    ]
    Spaceship(bullets:, ..), Tick -> {
      list.flat_map(bullets, fn(bullet) {
        let Position(x:, y:) = bullet

        let enemies_hit =
          list.flat_map(enemies, fn(enemy) {
            let Enemy(Position(x: enemy_x, y: enemy_y), width:) = enemy
            case
              y + 1 == enemy_y
              && enemy_x - width / 2 <= x
              && enemy_x + width / 2 >= x
            {
              True -> [EnemyDied(Position(x: enemy_x, y: enemy_y))]
              False -> []
            }
          })

        let bullet_events = case enemies_hit {
          [] ->
            case y + 1 > board_height {
              True -> [BulletRemoved(bullet)]
              False -> [BulletMoved(bullet, Position(x, y + 1))]
            }
          _ -> [BulletRemoved(bullet)]
        }

        list.append(enemies_hit, bullet_events)
      })
      |> list.append({
        list.flat_map(enemy_bullets, fn(bullet) {
          let Bullet(position: Position(x:, y:), count_down:, ..) = bullet
          let updated = case count_down == 0 {
            True ->
              EnemyBulletUpdated(
                Bullet(..bullet, position: Position(x, y - 1), count_down: 5),
              )
            False ->
              EnemyBulletUpdated(Bullet(..bullet, count_down: count_down - 1))
          }

          let removed_bullet = case y < 0 {
            True -> [EnemyBulletRemoved(bullet.id)]
            False -> []
          }

          let ship_hit_events = {
            let space_x = spaceship.position
            case
              bullet.position.y == 0
              && space_x - spaceship.width / 2 <= bullet.position.x
              && space_x + spaceship.width / 2 >= bullet.position.x
            {
              True -> [WeDied]
              False -> []
            }
          }

          [updated, ..removed_bullet] |> list.append(ship_hit_events)
        })
      })
    }

    _, IntroduceEnemy(x:, y:) -> [
      EnemyAdded(Enemy(Position(x, y), width: 6)),
      EnemyBulletShot(Bullet(
        id: state.last_id,
        position: Position(x:, y:),
        count_down: 0,
      )),
      IdIncreased,
    ]
  }
  apply_state(state, events)
}

fn apply_state(state, events) {
  list.fold(events, state, fn(state, event) {
    let Playing(spaceship:, enemies:, enemy_bullets:, ..) = state
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
      EnemyBulletShot(bullet) ->
        Playing(..state, enemy_bullets: [bullet, ..enemy_bullets])
      EnemyBulletUpdated(bullet) -> {
        let enemy_bullets =
          list.map(enemy_bullets, fn(b) {
            case bullet.id == b.id {
              True -> bullet
              False -> b
            }
          })
        Playing(..state, enemy_bullets:)
      }
      EnemyMoved(_) -> todo
      IdIncreased -> Playing(..state, last_id: state.last_id + 1)
      EnemyBulletRemoved(bullet_id) -> {
        let enemy_bullets =
          list.filter(enemy_bullets, fn(b) { bullet_id != b.id })
        Playing(..state, enemy_bullets:)
      }
      WeDied -> {
        create_game()
      }
    }
  })
}
