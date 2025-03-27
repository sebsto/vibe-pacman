import SwiftUI

struct MazeView: View {
    @ObservedObject var gameEngine: GameEngine
    
    var body: some View {
        GeometryReader { geometry in
            let cellWidth = geometry.size.width / CGFloat(GameConstants.mazeWidth)
            let cellHeight = geometry.size.height / CGFloat(GameConstants.mazeHeight)
            
            ZStack {
                // Background
                Color.black.edgesIgnoringSafeArea(.all)
                
                // Maze walls
                ForEach(0..<GameConstants.mazeHeight, id: \.self) { y in
                    ForEach(0..<GameConstants.mazeWidth, id: \.self) { x in
                        if gameEngine.maze[y][x] == .wall {
                            Rectangle()
                                .fill(Color.blue)
                                .frame(width: cellWidth, height: cellHeight)
                                .position(
                                    x: CGFloat(x) * cellWidth + cellWidth/2,
                                    y: CGFloat(y) * cellHeight + cellHeight/2
                                )
                        }
                    }
                }
                
                // Dots
                ForEach(gameEngine.dots, id: \.self) { position in
                    DotView()
                        .position(
                            x: CGFloat(position.x) * cellWidth + cellWidth/2,
                            y: CGFloat(position.y) * cellHeight + cellHeight/2
                        )
                }
                
                // Power pellets
                ForEach(gameEngine.powerPellets, id: \.self) { position in
                    PowerPelletView()
                        .position(
                            x: CGFloat(position.x) * cellWidth + cellWidth/2,
                            y: CGFloat(position.y) * cellHeight + cellHeight/2
                        )
                }
                
                // Pac-Man
                AnimatedPacmanView(direction: gameEngine.pacmanDirection)
                    .frame(width: cellWidth * 0.9, height: cellHeight * 0.9)
                    .position(
                        x: CGFloat(gameEngine.pacmanPosition.x) * cellWidth + cellWidth/2,
                        y: CGFloat(gameEngine.pacmanPosition.y) * cellHeight + cellHeight/2
                    )
                
                // Ghosts
                ForEach(gameEngine.ghosts.indices, id: \.self) { index in
                    let ghost = gameEngine.ghosts[index]
                    GhostView(ghostType: ghost.type, state: ghost.state)
                        .frame(width: cellWidth * 0.9, height: cellHeight * 0.9)
                        .position(
                            x: CGFloat(ghost.position.x) * cellWidth + cellWidth/2,
                            y: CGFloat(ghost.position.y) * cellHeight + cellHeight/2
                        )
                }
            }
        }
    }
}
