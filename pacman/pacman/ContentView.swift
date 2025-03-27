import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var gameState: GameState
    @State private var showingGameView = false
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            if !showingGameView {
                // Main Menu
                VStack(spacing: 30) {
                    Text("PAC-MAN")
                        .font(.system(size: 60, weight: .bold))
                        .foregroundColor(.yellow)
                        .shadow(color: .yellow.opacity(0.8), radius: 10)
                    
                    PacmanView(direction: .right, mouthAngle: 20)
                        .frame(width: 100, height: 100)
                    
                    Button(action: {
                        gameState.startGame()
                        showingGameView = true
                    }) {
                        Text("START GAME")
                            .font(.system(size: 30, weight: .bold))
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                    
                    Button(action: {
                        gameState.soundEnabled.toggle()
                    }) {
                        Text(gameState.soundEnabled ? "SOUND: ON" : "SOUND: OFF")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                            .padding()
                    }
                    
                    Text("© 1980 NAMCO")
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                        .padding(.top, 40)
                }
            } else {
                // Game View
                GameView()
                    .transition(.opacity)
                    .animation(.easeInOut, value: showingGameView)
            }
        }
        .onChange(of: gameState.gameOver) { gameOver in
            if gameOver {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    withAnimation {
                        showingGameView = false
                    }
                }
            }
        }
    }
}

struct GameView: View {
    @EnvironmentObject private var gameState: GameState
    @StateObject private var gameEngine: GameEngine
    
    init() {
        // Initialize gameEngine with the gameState that will be injected via environmentObject
        let tempGameState = GameState() // Temporary for initialization
        _gameEngine = StateObject(wrappedValue: GameEngine(gameState: tempGameState))
    }
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            VStack {
                // Score and lives display
                HStack {
                    Text("SCORE: \(gameState.score)")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    HStack {
                        ForEach(0..<gameState.lives, id: \.self) { _ in
                            PacmanView(direction: .right, mouthAngle: 20)
                                .frame(width: 20, height: 20)
                        }
                    }
                }
                .padding()
                
                // Game board
                MazeView(gameEngine: gameEngine)
                    .aspectRatio(CGFloat(GameConstants.mazeWidth) / CGFloat(GameConstants.mazeHeight), contentMode: .fit)
                    .padding(.horizontal)
                
                // Controls
                ControlsView(gameEngine: gameEngine)
                    .padding()
            }
            
            if gameState.gameOver {
                VStack {
                    Text("GAME OVER")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(.red)
                        .padding()
                    
                    Text("SCORE: \(gameState.score)")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundColor(.yellow)
                }
                .background(Color.black.opacity(0.8))
                .cornerRadius(20)
            }
        }
        .onAppear {
            // Replace the temporary gameState with the actual one from environment
            gameEngine.gameState = gameState
            gameEngine.startGame()
        }
    }
}

struct ControlsView: View {
    @ObservedObject var gameEngine: GameEngine
    
    var body: some View {
        VStack {
            Button(action: { gameEngine.changeDirection(.up) }) {
                Image(systemName: "arrow.up.circle.fill")
                    .resizable()
                    .frame(width: 50, height: 50)
                    .foregroundColor(.white)
            }
            
            HStack {
                Button(action: { gameEngine.changeDirection(.left) }) {
                    Image(systemName: "arrow.left.circle.fill")
                        .resizable()
                        .frame(width: 50, height: 50)
                        .foregroundColor(.white)
                }
                
                Spacer().frame(width: 50)
                
                Button(action: { gameEngine.changeDirection(.right) }) {
                    Image(systemName: "arrow.right.circle.fill")
                        .resizable()
                        .frame(width: 50, height: 50)
                        .foregroundColor(.white)
                }
            }
            
            Button(action: { gameEngine.changeDirection(.down) }) {
                Image(systemName: "arrow.down.circle.fill")
                    .resizable()
                    .frame(width: 50, height: 50)
                    .foregroundColor(.white)
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(GameState())
    }
}
