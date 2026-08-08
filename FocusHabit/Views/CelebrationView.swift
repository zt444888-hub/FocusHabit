import SwiftUI

/// 微信风格彩带：从卡片位置向上炸开，带着重力、阻力、摇摆和翻滚慢慢飘落
struct CelebrationOverlay: View {
    let startFrame: CGRect
    @Binding var trigger: Int

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if trigger > 0 {
                    let origin = startFrame == .zero
                        ? CGPoint(x: geometry.size.width / 2, y: geometry.size.height * 0.7)
                        : CGPoint(x: startFrame.midX, y: startFrame.midY)
                    ConfettiCanvas(origin: origin, onFinished: { trigger = 0 })
                        .id(trigger)
                }
            }
        }
        .allowsHitTesting(false)
        .ignoresSafeArea()
    }
}

private struct ConfettiCanvas: View {
    let origin: CGPoint
    let onFinished: () -> Void

    @State private var particles: [ConfettiParticle] = []
    @State private var hasStarted = false
    private let timer = Timer.publish(every: 1.0 / 60.0, on: .main, in: .common).autoconnect()

    private static let colors: [Color] = [
        .red, .orange, .yellow, .green, .blue, .purple, .pink, .teal, .white, .yellow
    ]

    var body: some View {
        GeometryReader { geometry in
            Canvas { context, size in
                for p in particles {
                    // 按位置淡出：上升阶段完全可见，接近屏幕底部才逐渐透明
                    let fadeStart = size.height * 0.55
                    let fadeEnd = size.height * 1.08
                    var alpha = 1.0
                    if p.y > fadeStart {
                        alpha = max(0, 1 - (p.y - fadeStart) / (fadeEnd - fadeStart))
                    }
                    alpha = min(alpha, max(0, p.life * 1.5))

                    var ctx = context
                    ctx.opacity = alpha
                    ctx.translateBy(x: p.x, y: p.y)
                    ctx.rotate(by: .degrees(p.rotation))

                    switch p.shape {
                    case .circle:
                        let rect = CGRect(x: -p.size / 2, y: -p.size / 2, width: p.size, height: p.size)
                        ctx.fill(Path(ellipseIn: rect), with: .color(p.color))
                    case .rect:
                        let rect = CGRect(x: -p.size / 2, y: -p.size / 2, width: p.size, height: p.size)
                        ctx.fill(Path(rect), with: .color(p.color))
                    case .strip:
                        let rect = CGRect(x: -p.size / 3, y: -p.height / 2, width: p.size / 1.5, height: p.height)
                        ctx.fill(Path(rect), with: .color(p.color))
                    }
                }
            }
            .onAppear {
                // 每个触发只创建一次粒子；切 Tab 回来不会重播
                guard !hasStarted else { return }
                hasStarted = true
                particles = Self.makeBurst(origin: origin)
            }
            .onReceive(timer) { _ in
                guard !particles.isEmpty else { return }
                var alive: [ConfettiParticle] = []
                for var p in particles {
                    p.vx *= p.drag
                    p.vy = p.vy * p.drag + p.gravity
                    p.x += p.vx
                    p.y += p.vy
                    p.swayPhase += p.swaySpeed
                    p.x += CGFloat(sin(p.swayPhase)) * p.swayAmount * CGFloat(max(0, p.life))
                    p.rotAccel += Double.random(in: -0.12...0.12)
                    p.rotSpeed = max(-8, min(8, p.rotSpeed + p.rotAccel))
                    p.rotation += p.rotSpeed
                    p.life -= 0.003
                if p.life > 0 && p.y <= geometry.size.height + 40 {
                    alive.append(p)
                }
            }
            if alive.isEmpty {
                onFinished()
            }
            particles = alive
            }
        }
    }

    private static func makeBurst(origin: CGPoint) -> [ConfettiParticle] {
        var result: [ConfettiParticle] = []
        let shapes: [ConfettiShape] = [.circle, .rect, .strip, .circle, .rect]

        for _ in 0..<44 {
            // 向上扇形：以正上方为中心 ±24°
            let angle = -Double.pi / 2 + Double.random(in: -0.42...0.42)
            let speed = CGFloat.random(in: 4...8)
            let size = CGFloat.random(in: 3...8.5)

            result.append(ConfettiParticle(
                x: origin.x + CGFloat.random(in: -4...4),
                y: origin.y + CGFloat.random(in: -4...4),
                vx: CGFloat(cos(angle)) * speed,
                vy: CGFloat(sin(angle)) * speed * 1.6,
                gravity: 0.055 + (size / 9) * 0.04,
                drag: 0.992,
                rotation: Double.random(in: 0...360),
                rotSpeed: Double.random(in: -11...11),
                rotAccel: 0,
                size: size,
                height: size * 2.2 + CGFloat.random(in: 0...7),
                color: colors.randomElement() ?? .red,
                shape: shapes.randomElement() ?? .circle,
                life: 1,
                swayPhase: Double.random(in: 0...(2 * .pi)),
                swaySpeed: Double.random(in: 0.05...0.14),
                swayAmount: CGFloat.random(in: 1.2...3.4)
            ))
        }
        return result
    }
}

private struct ConfettiParticle {
    var x: CGFloat
    var y: CGFloat
    var vx: CGFloat
    var vy: CGFloat
    var gravity: CGFloat
    var drag: CGFloat
    var rotation: Double
    var rotSpeed: Double
    var rotAccel: Double
    var size: CGFloat
    var height: CGFloat
    var color: Color
    var shape: ConfettiShape
    var life: Double
    var swayPhase: Double
    var swaySpeed: Double
    var swayAmount: CGFloat
}

private enum ConfettiShape {
    case circle
    case rect
    case strip
}
