import SwiftUI
import Combine

class GameEngine: ObservableObject {
    @Published var maze: [[CellType]] = []
    @Published var pacmanPosition = Position(x: 14, y: 23)
    @Published var pacmanDirection: Direction = .right
    @Published var requestedDirection: Direction = .right
    @Published var dots: [Position] = []
    @Published var powerPellets: [Position] = []
    @Published var ghosts: [Ghost] = []
    @Published var ghostsVulnerable = false
    
    private var gameTimer: Timer?
    private var vulnerabilityTimer: Timer?
    private var gameSpeed: TimeInterval = 0.2
    
    // Reference to GameState for scoring and lives
    @ObservedObject var gameState: GameState
    
    init(gameState: GameState) {
        self.gameState = gameState
        setupGame()
    }
    
    func setupGame() {
        // Initialize maze
        maze = Array(repeating: Array(repeating: .empty, count: GameConstants.mazeWidth), count: GameConstants.mazeHeight)
        
        // Create walls around the edges
        for x in 0..<GameConstants.mazeWidth {
            maze[0][x] = .wall
            maze[GameConstants.mazeHeight-1][x] = .wall
        }
        
        for y in 0..<GameConstants.mazeHeight {
            maze[y][0] = .wall
            maze[y][GameConstants.mazeWidth-1] = .wall
        }
        
        // Add some internal walls
        for x in 5..<10 {
            maze[5][x] = .wall
            maze[15][x] = .wall
        }
        
        for x in 18..<23 {
            maze[5][x] = .wall
            maze[15][x] = .wall
        }
        
        // Add dots and power pellets
        dots = []
        powerPellets = []
        
        for y in 1..<GameConstants.mazeHeight-1 {
            for x in 1..<GameConstants.mazeWidth-1 {
                if maze[y][x] == .empty {
                    dots.append(Position(x: x, y: y))
                }
            }
        }
        
        // Add power pellets at corners
        powerPellets = [
            Position(x: 1, y: 1),
            Position(x: GameConstants.mazeWidth-2, y: 1),
            Position(x: 1, y: GameConstants.mazeHeight-2),
            Position(x: GameConstants.mazeWidth-2, y: GameConstants.mazeHeight-2)
        ]
        
        // Remove dots where power pellets are
        dots = dots.filter { dot in
            !powerPellets.contains(dot)
        }
        
        // Initialize ghosts
        ghosts = [
            Ghost(type: .blinky, position: Position(x: 14, y: 11), targetPosition: Position(x: 0, y: 0),
                  direction: .up, state: .scatter, homePosition: Position(x: GameConstants.mazeWidth-2, y: 0)),
            Ghost(type: .pinky, position: Position(x: 14, y: 12), targetPosition: Position(x: 0, y: 0),
                  direction: .up, state: .scatter, homePosition: Position(x: 1, y: 0)),
            Ghost(type: .inky, position: Position(x: 13, y: 12), targetPosition: Position(x: 0, y: 0),
                  direction: .up, state: .scatter, homePosition: Position(x: GameConstants.mazeWidth-2, y: GameConstants.mazeHeight-2)),
            Ghost(type: .clyde, position: Position(x: 15, y: 12), targetPosition: Position(x: 0, y: 0),
                  direction: .up, state: .scatter, homePosition: Position(x: 1, y: GameConstants.mazeHeight-2))
        ]
    }
    
    func startGame() {
        setupGame()
        startGameTimer()
    }
    
    private func startGameTimer() {
        gameTimer = Timer.scheduledTimer(withTimeInterval: gameSpeed, repeats: true) { [weak self] _ in
            self?.update()
        }
    }
    
    func stopGame() {
        gameTimer?.invalidate()
        gameTimer = nil
        vulnerabilityTimer?.invalidate()
        vulnerabilityTimer = nil
    }
    
    func update() {
        movePacman()
        moveGhosts()
        checkCollisions()
        
        // Check if all dots and power pellets are collected
        if dots.isEmpty && powerPellets.isEmpty {
            stopGame()
            gameState.advanceLevel()
            setupGame()
            startGameTimer()
        }
    }
    
    func movePacman() {
        // Try to move in the requested direction
        let nextPosition = pacmanPosition.moved(direction: requestedDirection)
        
        // Check if the move is valid
        if isValidMove(position: nextPosition) {
            pacmanDirection = requestedDirection
            pacmanPosition = nextPosition
            
            // Check if Pac-Man ate a dot
            if let dotIndex = dots.firstIndex(of: pacmanPosition) {
                dots.remove(at: dotIndex)
                gameState.eatDot()
            }
            
            // Check if Pac-Man ate a power pellet
            if let pelletIndex = powerPellets.firstIndex(of: pacmanPosition) {
                powerPellets.remove(at: pelletIndex)
                gameState.eatPowerPellet()
                makeGhostsVulnerable()
            }
        } else {
            // Try to continue in the current direction
            let currentNextPosition = pacmanPosition.moved(direction: pacmanDirection)
            if isValidMove(position: currentNextPosition) {
                pacmanPosition = currentNextPosition
                
                // Check if Pac-Man ate a dot
                if let dotIndex = dots.firstIndex(of: pacmanPosition) {
                    dots.remove(at: dotIndex)
                    gameState.eatDot()
                }
                
                // Check if Pac-Man ate a power pellet
                if let pelletIndex = powerPellets.firstIndex(of: pacmanPosition) {
                    powerPellets.remove(at: pelletIndex)
                    gameState.eatPowerPellet()
                    makeGhostsVulnerable()
                }
            }
        }
    }
    
    func moveGhosts() {
        for i in 0..<ghosts.count {
            var ghost = ghosts[i]
            
            // Update target based on ghost type and state
            if ghost.state != .frightened && ghost.state != .eaten {
                ghost.targetPosition = ghost.calculateTarget(
                    pacmanPosition: pacmanPosition,
                    pacmanDirection: pacmanDirection
                )
            } else if ghost.state == .frightened {
                // When frightened, ghosts move randomly
                ghost.targetPosition = Position(
                    x: Int.random(in: 0..<GameConstants.mazeWidth),
                    y: Int.random(in: 0..<GameConstants.mazeHeight)
                )
            } else if ghost.state == .eaten {
                // When eaten, ghosts return to the ghost house
                ghost.targetPosition = Position(x: 14, y: 12)
            }
            
            // Determine best direction to move toward target
            let possibleDirections = Direction.allCases.filter { direction in
                let nextPosition = ghost.position.moved(direction: direction)
                return isValidMove(position: nextPosition, isGhost: true)
            }
            
            if !possibleDirections.isEmpty {
                // Find direction that gets closest to target
                var bestDirection = ghost.direction
                var shortestDistance = Double.infinity
                
                for direction in possibleDirections {
                    // Ghosts can't reverse direction unless they have no other choice
                    if possibleDirections.count > 1 {
                        if (direction == .up && ghost.direction == .down) ||
                           (direction == .down && ghost.direction == .up) ||
                           (direction == .left && ghost.direction == .right) ||
                           (direction == .right && ghost.direction == .left) {
                            continue
                        }
                    }
                    
                    let nextPosition = ghost.position.moved(direction: direction)
                    let distance = sqrt(
                        pow(Double(nextPosition.x - ghost.targetPosition.x), 2) +
                        pow(Double(nextPosition.y - ghost.targetPosition.y), 2)
                    )
                    
                    if distance < shortestDistance {
                        shortestDistance = distance
                        bestDirection = direction
                    }
                }
                
                ghost.direction = bestDirection
                ghost.position = ghost.position.moved(direction: ghost.direction)
            }
            
            ghosts[i] = ghost
        }
    }
    
    func checkCollisions() {
        // Check for collisions with ghosts
        for i in 0..<ghosts.count {
            // Check if ghost and Pac-Man are close enough to collide
            let distance = abs(ghosts[i].position.x - pacmanPosition.x) + abs(ghosts[i].position.y - pacmanPosition.y)
            
            if distance <= 1 { // If they're in adjacent cells or same cell
                if ghosts[i].state == .frightened {
                    // Pac-Man eats the ghost
                    ghosts[i].state = .eaten
                    ghosts[i].position = Position(x: 14, y: 12) // Return to ghost house
                    gameState.eatGhost()
                } else if ghosts[i].state != .eaten {
                    // Ghost catches Pac-Man
                    handlePacmanCaught()
                }
            }
        }
    }
    
    private func handlePacmanCaught() {
        gameState.loseLife()
        
        if !gameState.gameOver {
            // Reset positions only if game isn't over
            resetPositions()
        } else {
            stopGame()
        }
    }
    
    private func resetPositions() {
        // Reset Pac-Man to starting position
        pacmanPosition = Position(x: 14, y: 23)
        pacmanDirection = .right
        requestedDirection = .right
        
        // Reset ghosts to their starting positions
        ghosts = [
            Ghost(type: .blinky, position: Position(x: 14, y: 11), targetPosition: Position(x: 0, y: 0),
                  direction: .up, state: .scatter, homePosition: Position(x: GameConstants.mazeWidth-2, y: 0)),
            Ghost(type: .pinky, position: Position(x: 14, y: 12), targetPosition: Position(x: 0, y: 0),
                  direction: .up, state: .scatter, homePosition: Position(x: 1, y: 0)),
            Ghost(type: .inky, position: Position(x: 13, y: 12), targetPosition: Position(x: 0, y: 0),
                  direction: .up, state: .scatter, homePosition: Position(x: GameConstants.mazeWidth-2, y: GameConstants.mazeHeight-2)),
            Ghost(type: .clyde, position: Position(x: 15, y: 12), targetPosition: Position(x: 0, y: 0),
                  direction: .up, state: .scatter, homePosition: Position(x: 1, y: GameConstants.mazeHeight-2))
        ]
        
        // Brief pause before resuming
        gameTimer?.invalidate()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.startGameTimer()
        }
    }
    
    func changeDirection(_ direction: Direction) {
        requestedDirection = direction
    }
    
    func makeGhostsVulnerable() {
        ghostsVulnerable = true
        
        // Make all ghosts vulnerable
        for i in 0..<ghosts.count {
            if ghosts[i].state != .eaten {
                ghosts[i].state = .frightened
            }
        }
        
        // Set timer to end vulnerability
        vulnerabilityTimer?.invalidate()
        vulnerabilityTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: false) { [weak self] _ in
            self?.endGhostVulnerability()
        }
    }
    
    func endGhostVulnerability() {
        ghostsVulnerable = false
        
        // Return ghosts to normal state
        for i in 0..<ghosts.count {
            if ghosts[i].state == .frightened {
                ghosts[i].state = .chase
            }
        }
    }
    
    func isValidMove(position: Position, isGhost: Bool = false) -> Bool {
        // Check if position is within bounds
        if position.x < 0 || position.x >= GameConstants.mazeWidth ||
           position.y < 0 || position.y >= GameConstants.mazeHeight {
            return false
        }
        
        // Check if position is a wall
        if maze[position.y][position.x] == .wall {
            return false
        }
        
        // Ghosts can enter the ghost house, but Pac-Man cannot
        if !isGhost && maze[position.y][position.x] == .ghostHouse {
            return false
        }
        
        return true
    }
}
