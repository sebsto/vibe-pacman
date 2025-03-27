import SwiftUI

// Pac-Man view with animated mouth
struct PacmanView: View {
    var direction: Direction
    var mouthAngle: Double
    
    var body: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height)
            
            ZStack {
                // Base circle
                Circle()
                    .fill(Color.yellow)
                    .frame(width: size, height: size)
                
                // Mouth cutout
                PacmanMouth(direction: direction, mouthAngle: mouthAngle)
                    .fill(Color.black)
                    .frame(width: size, height: size)
            }
        }
    }
}

// Separate shape for the mouth cutout
struct PacmanMouth: Shape {
    var direction: Direction
    var mouthAngle: Double
    
    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        
        var path = Path()
        
        // Start at center
        path.move(to: center)
        
        // Calculate angles based on direction
        var startAngle: Angle
        var endAngle: Angle
        
        switch direction {
        case .right:
            startAngle = .degrees(-mouthAngle/2)
            endAngle = .degrees(mouthAngle/2)
        case .left:
            startAngle = .degrees(180 - mouthAngle/2)
            endAngle = .degrees(180 + mouthAngle/2)
        case .up:
            startAngle = .degrees(270 - mouthAngle/2)
            endAngle = .degrees(270 + mouthAngle/2)
        case .down:
            startAngle = .degrees(90 - mouthAngle/2)
            endAngle = .degrees(90 + mouthAngle/2)
        }
        
        // Draw line to mouth opening
        let startPoint = CGPoint(
            x: center.x + radius * cos(CGFloat(startAngle.radians)),
            y: center.y + radius * sin(CGFloat(startAngle.radians))
        )
        path.addLine(to: startPoint)
        
        // Draw arc for mouth
        path.addArc(
            center: center,
            radius: radius,
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: false
        )
        
        // Close path back to center
        path.addLine(to: center)
        
        return path
    }
}

// Animated Pac-Man with mouth opening and closing
struct AnimatedPacmanView: View {
    var direction: Direction
    @State private var mouthAngle: Double = 20
    @State private var mouthOpening = true
    
    var body: some View {
        PacmanView(direction: direction, mouthAngle: mouthAngle)
            .onAppear {
                withAnimation(Animation.easeInOut(duration: 0.2).repeatForever(autoreverses: true)) {
                    mouthAngle = 45
                }
            }
    }
}

// Ghost view
struct GhostView: View {
    var ghostType: CharacterType
    var state: GhostState
    
    var body: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height)
            let ghostColor: Color = {
                if state == .frightened {
                    return .blue
                } else if state == .eaten {
                    return .clear // Just show eyes when eaten
                } else {
                    switch ghostType {
                    case .blinky: return .red
                    case .pinky: return .pink
                    case .inky: return Color(red: 0, green: 0.8, blue: 0.8) // Light blue
                    case .clyde: return .orange
                    default: return .white
                    }
                }
            }()
            
            ZStack {
                // Ghost body
                Path { path in
                    // Head (semi-circle)
                    path.addArc(center: CGPoint(x: size/2, y: size/2),
                               radius: size/2,
                               startAngle: .degrees(180),
                               endAngle: .degrees(0),
                               clockwise: false)
                    
                    // Bottom with waves
                    let waveWidth = size / 5
                    
                    path.addLine(to: CGPoint(x: size, y: size))
                    path.addQuadCurve(to: CGPoint(x: size - waveWidth, y: size - waveWidth/2),
                                     control: CGPoint(x: size - waveWidth/2, y: size))
                    
                    path.addQuadCurve(to: CGPoint(x: size - 2*waveWidth, y: size),
                                     control: CGPoint(x: size - 1.5*waveWidth, y: size - waveWidth/2))
                    
                    path.addQuadCurve(to: CGPoint(x: size - 3*waveWidth, y: size - waveWidth/2),
                                     control: CGPoint(x: size - 2.5*waveWidth, y: size))
                    
                    path.addQuadCurve(to: CGPoint(x: size - 4*waveWidth, y: size),
                                     control: CGPoint(x: size - 3.5*waveWidth, y: size - waveWidth/2))
                    
                    path.addQuadCurve(to: CGPoint(x: 0, y: size - waveWidth/2),
                                     control: CGPoint(x: size - 4.5*waveWidth, y: size))
                    
                    path.addLine(to: CGPoint(x: 0, y: size/2))
                }
                .fill(ghostColor)
                
                // Eyes
                HStack(spacing: size/5) {
                    // Left eye
                    ZStack {
                        Circle()
                            .fill(Color.white)
                            .frame(width: size/3, height: size/3)
                        
                        Circle()
                            .fill(Color.blue)
                            .frame(width: size/6, height: size/6)
                            .offset(x: size/12, y: 0)
                    }
                    
                    // Right eye
                    ZStack {
                        Circle()
                            .fill(Color.white)
                            .frame(width: size/3, height: size/3)
                        
                        Circle()
                            .fill(Color.blue)
                            .frame(width: size/6, height: size/6)
                            .offset(x: size/12, y: 0)
                    }
                }
                .position(x: size/2, y: size/2.5)
                
                // Frightened state
                if state == .frightened {
                    VStack(spacing: 2) {
                        // Mouth
                        Path { path in
                            path.move(to: CGPoint(x: size/4, y: size/1.8))
                            path.addLine(to: CGPoint(x: size/3, y: size/1.6))
                            path.addLine(to: CGPoint(x: size/2.5, y: size/1.8))
                            path.addLine(to: CGPoint(x: size/2, y: size/1.6))
                            path.addLine(to: CGPoint(x: size/1.7, y: size/1.8))
                            path.addLine(to: CGPoint(x: size/1.5, y: size/1.6))
                            path.addLine(to: CGPoint(x: size/1.3, y: size/1.8))
                        }
                        .stroke(Color.white, lineWidth: 2)
                    }
                    .position(x: size/2, y: size/1.5)
                }
            }
        }
    }
}

// Dot view
struct DotView: View {
    var body: some View {
        Circle()
            .fill(Color.white)
            .frame(width: 4, height: 4)
    }
}

// Power pellet view
struct PowerPelletView: View {
    @State private var isAnimating = false
    
    var body: some View {
        Circle()
            .fill(Color.white)
            .frame(width: 8, height: 8)
            .scaleEffect(isAnimating ? 1.2 : 1.0)
            .onAppear {
                withAnimation(Animation.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
                    isAnimating = true
                }
            }
    }
}
