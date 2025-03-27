import Foundation
import SwiftUI
import AVFoundation

// Main game state that will be shared across views
class GameState: ObservableObject {
    @Published var score: Int = 0
    @Published var lives: Int = 3
    @Published var gameActive: Bool = false
    @Published var gameOver: Bool = false
    @Published var level: Int = 1
    @Published var soundEnabled: Bool = true
    
    // Audio players
    var backgroundPlayer: AVAudioPlayer?
    var chompPlayer: AVAudioPlayer?
    var deathPlayer: AVAudioPlayer?
    var ghostEatenPlayer: AVAudioPlayer?
    
    init() {
        setupAudio()
    }
    
    func setupAudio() {
        // Setup audio files
        if let backgroundURL = Bundle.main.url(forResource: "pacman_beginning", withExtension: "wav") {
            backgroundPlayer = try? AVAudioPlayer(contentsOf: backgroundURL)
            backgroundPlayer?.prepareToPlay()
        }
        
        if let chompURL = Bundle.main.url(forResource: "pacman_chomp", withExtension: "wav") {
            chompPlayer = try? AVAudioPlayer(contentsOf: chompURL)
            chompPlayer?.prepareToPlay()
        }
        
        if let deathURL = Bundle.main.url(forResource: "pacman_death", withExtension: "wav") {
            deathPlayer = try? AVAudioPlayer(contentsOf: deathURL)
            deathPlayer?.prepareToPlay()
        }
        
        if let ghostEatenURL = Bundle.main.url(forResource: "pacman_eatghost", withExtension: "wav") {
            ghostEatenPlayer = try? AVAudioPlayer(contentsOf: ghostEatenURL)
            ghostEatenPlayer?.prepareToPlay()
        }
    }
    
    func playSound(_ sound: GameSound) {
        guard soundEnabled else { return }
        
        switch sound {
        case .background:
            backgroundPlayer?.play()
        case .chomp:
            chompPlayer?.play()
        case .death:
            deathPlayer?.play()
        case .ghostEaten:
            ghostEatenPlayer?.play()
        case .powerPellet:
            // For now, reuse the chomp sound for power pellets
            chompPlayer?.play()
        }
    }
    
    func startGame() {
        score = 0
        lives = 3
        level = 1
        gameActive = true
        gameOver = false
        playSound(.background)
    }
    
    func loseLife() {
        lives -= 1
        playSound(.death)
        
        if lives <= 0 {
            gameOver = true
            gameActive = false
        }
    }
    
    func addScore(_ points: Int) {
        score += points
    }
    
    func eatDot() {
        addScore(GameConstants.dotPoints)
        playSound(.chomp)
    }
    
    func eatPowerPellet() {
        addScore(GameConstants.powerPelletPoints)
        playSound(.powerPellet)
    }
    
    func eatGhost() {
        addScore(GameConstants.ghostPoints)
        playSound(.ghostEaten)
    }
    
    func advanceLevel() {
        level += 1
        // Increase difficulty
    }
}

enum GameSound {
    case background
    case chomp
    case death
    case ghostEaten
    case powerPellet
}

// Direction enum for movement
enum Direction: CaseIterable {
    case up, down, left, right
    
    var vector: CGPoint {
        switch self {
        case .up: return CGPoint(x: 0, y: -1)
        case .down: return CGPoint(x: 0, y: 1)
        case .left: return CGPoint(x: -1, y: 0)
        case .right: return CGPoint(x: 1, y: 0)
        }
    }
}

// Cell types for the maze
enum CellType {
    case wall
    case empty
    case dot
    case powerPellet
    case ghostHouse
    case tunnel
}

// Character types
enum CharacterType {
    case pacman
    case blinky // Red ghost
    case pinky  // Pink ghost
    case inky   // Blue ghost
    case clyde  // Orange ghost
}

// Ghost states
enum GhostState {
    case chase
    case scatter
    case frightened
    case eaten
}

// Position in the maze
struct Position: Equatable, Hashable {
    var x: Int
    var y: Int
    
    func moved(direction: Direction) -> Position {
        let vector = direction.vector
        return Position(x: x + Int(vector.x), y: y + Int(vector.y))
    }
}

// Ghost character model
struct Ghost: Identifiable {
    let id = UUID()
    let type: CharacterType
    var position: Position
    var targetPosition: Position
    var direction: Direction
    var state: GhostState
    var homePosition: Position
    
    // Different movement strategies based on ghost type
    func calculateTarget(pacmanPosition: Position, pacmanDirection: Direction) -> Position {
        switch type {
        case .blinky: // Red ghost - directly targets Pac-Man
            return pacmanPosition
            
        case .pinky: // Pink ghost - targets 4 tiles ahead of Pac-Man
            var target = pacmanPosition
            for _ in 0..<4 {
                target = target.moved(direction: pacmanDirection)
            }
            return target
            
        case .inky: // Blue ghost - complex targeting based on Blinky's position
            // Simplified for this implementation
            var target = pacmanPosition
            for _ in 0..<2 {
                target = target.moved(direction: pacmanDirection)
            }
            return target
            
        case .clyde: // Orange ghost - targets Pac-Man when far, scatters when close
            let distance = abs(pacmanPosition.x - position.x) + abs(pacmanPosition.y - position.y)
            if distance > 8 {
                return pacmanPosition
            } else {
                return homePosition
            }
            
        default:
            return pacmanPosition
        }
    }
}

// Game constants
struct GameConstants {
    static let mazeWidth = 28
    static let mazeHeight = 31
    static let dotPoints = 10
    static let powerPelletPoints = 50
    static let ghostPoints = 200
}
