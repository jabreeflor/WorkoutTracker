import SwiftUI

struct ConfettiView: View {
    @State private var animate = false
    @State private var isVisible = true
    
    let colors: [Color] = [.red, .blue, .green, .yellow, .orange, .purple, .pink]
    
    var body: some View {
        ZStack {
            if isVisible {
                ForEach(0..<15, id: \.self) { index in
                    ConfettiPiece(
                        color: colors.randomElement() ?? .blue,
                        animate: $animate
                    )
                    .offset(
                        x: CGFloat.random(in: -150...150),
                        y: animate ? CGFloat.random(in: -200...(-50)) : 50
                    )
                    .rotationEffect(.degrees(animate ? Double.random(in: 0...360) : 0))
                    .animation(
                        .easeOut(duration: Double.random(in: 0.8...1.2))
                        .delay(Double.random(in: 0...0.3)),
                        value: animate
                    )
                }
            }
        }
        .onAppear {
            withAnimation {
                animate = true
            }
            
            // Hide confetti after animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                isVisible = false
            }
        }
    }
}

struct ConfettiPiece: View {
    let color: Color
    @Binding var animate: Bool
    
    var body: some View {
        Rectangle()
            .fill(color)
            .frame(width: 8, height: 6)
            .cornerRadius(2)
            .opacity(animate ? 0 : 1)
            .scaleEffect(animate ? 0.1 : 1)
    }
}

#Preview {
    ConfettiView()
        .frame(width: 300, height: 200)
        .background(Color.gray.opacity(0.1))
}
