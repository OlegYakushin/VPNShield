//
//  HomeView.swift
//  VPNShield
//
//  Created by Oleg Yakushin on 18/7/25.
//
//
//  HomeView.swift
//  VPNShield
//
//  Created by Oleg Yakushin on 18/7/25.
//

import SwiftUI
import AVFoundation
import NetworkExtension

enum VPNState {
    case waiting, disconnected, connected
}

struct HomeView: View {
    @State private var state: VPNState = .disconnected
    @State private var uptime: TimeInterval = 0
    @State private var timer: Timer? = nil

    @State private var showingError = false
    @State private var lastError = ""

    var expiresAt: Date = Calendar.current.date(byAdding: .day, value: 323, to: Date())!

    var body: some View {
        NavigationView {
            ZStack {
                VPNVideoBackground(state: state)
                    .ignoresSafeArea()

                VStack(spacing: 18) {

                    header
                        .padding(.horizontal, 18)
                        .padding(.top, 18)

                    uptimeBlock
                        .padding(.top, 2)

                    statsRow
                        .padding(.horizontal, 18)
                        .padding(.top, 6)

                    PowerButton(state: state, action: toggleVPN)
                        .padding(.top, 8)

                    Spacer()

                    helpCard
                        .padding(.horizontal, 18)
                        .padding(.bottom, 18)
                }
                .navigationBarHidden(true)
            }
            .alert("Ошибка", isPresented: $showingError, actions: {
                Button("OK", role: .cancel) { }
            }, message: {
                Text(lastError)
            })
        }
        .onDisappear { stopTimer() }
        .onAppear {
            // 1) сразу нейтральный экран
            if state != .connected { state = .disconnected }

            // 2) затем синхронизируемся с реальным VPN
            syncVPNStatusOnLaunch()
        }
    }

    // MARK: - UI Blocks
    private func syncVPNStatusOnLaunch() {
        print("🧭 [HOME] syncVPNStatusOnLaunch...")

        NEVPNManager.shared().loadFromPreferences { error in
            if let error {
                print("❌ [HOME] loadFromPreferences error:", error)
                DispatchQueue.main.async {
                    self.state = .disconnected  // fallback
                }
                return
            }

            let status = NEVPNManager.shared().connection.status
            print("🧭 [HOME] NEVPN status =", status.rawValue)

            DispatchQueue.main.async {
                switch status {
                case .connected:
                    self.state = .connected
                    self.startTimer() // если хочешь продолжать таймер “с нуля”
                case .connecting, .reasserting, .disconnecting:
                    self.state = .waiting
                default:
                    self.state = .disconnected
                }
            }
        }
    }
    private var header: some View {
        HStack(spacing: 12) {
            HStack(spacing: 10) {
                Image("shieldLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 44 * sizeScreen(), height: 44 * sizeScreen())
            }

            Spacer()

            Button { } label: {
                ZStack {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 44, height: 44)
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white.opacity(0.9))
                }
            }
            .buttonStyle(.plain)

            Button { } label: {
                HStack(spacing: 10) {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Премиум")
                        .font(.custom("WixMadeforText-SemiBold", size: 14 * sizeScreen()))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 18)
                .frame(height: 44)
                .background(
                    Capsule()
                        .fill(Color.green.opacity(0.75))
                        .shadow(color: Color.green.opacity(0.25), radius: 18, x: 0, y: 10)
                )
            }
            .buttonStyle(.plain)
        }
    }

    private var uptimeBlock: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(state == .connected ? .green : .white.opacity(0.55))

                Text(state == .connected ? "Соединение защищено" : "Соединение не активно")
                    .font(.custom("WixMadeforText-SemiBold", size: 16 * sizeScreen()))
                    .foregroundColor(state == .connected ? .green : .white.opacity(0.55))
            }

            Text(uptimeString)
                .font(.custom("WixMadeforText-SemiBold", size: 54 * sizeScreen()))
                .foregroundColor(.white)
                .monospacedDigit()
        }
    }

    private var statsRow: some View {
        HStack(spacing: 14) {
            StatCard(
                title: "Скачивание",
                value: downloadSpeed,
                iconSystemName: "arrow.down",
                tint: .green,
                background: .ultraThinMaterial,
                caretSystemName: "chevron.down"
            )

            StatCard(
                title: "Загрузка",
                value: uploadSpeed,
                iconSystemName: "arrow.up",
                tint: .red,
                background: .ultraThinMaterial,
                caretSystemName: "chevron.up"
            )
        }
    }

    private var helpCard: some View {
        Button(action: changeServer) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Проблема с подключением?")
                        .font(.custom("WixMadeforText-SemiBold", size: 18 * sizeScreen()))
                        .foregroundColor(.white)

                    Text("Сменить сервер")
                        .font(.custom("WixMadeforText-Regular", size: 16 * sizeScreen()))
                        .foregroundColor(.green)
                        .underline()
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white.opacity(0.6))
            }
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Computed

    private var downloadSpeed: String { state == .connected ? "147.67 KB/s" : "0 KB/s" }
    private var uploadSpeed: String   { state == .connected ? "176 KB/s" : "0 KB/s" }

    private var uptimeString: String {
        let f = DateComponentsFormatter()
        f.allowedUnits = [.hour, .minute, .second]
        f.zeroFormattingBehavior = .pad
        return f.string(from: uptime) ?? "00:00:00"
    }

    // MARK: - Actions (заглушки)

    private func connect() {
        print("🔌 [HOME] connect()")
        state = .waiting
        startTimer()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            print("✅ [HOME] simulated connected")
            self.state = .connected
        }
    }

    private func disconnect() {
        print("🛑 [HOME] disconnect()")
        state = .disconnected
        stopTimer()
    }

    private func toggleVPN() {
        print("🎛️ [HOME] toggleVPN state=\(state)")
        switch state {
        case .disconnected: connect()
        case .connected:    disconnect()
        case .waiting:      break
        }
    }

    private func changeServer() {
        print("🌍 [HOME] changeServer()")
    }

    private func startTimer() {
        print("⏱️ [HOME] startTimer()")
        uptime = 0
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            uptime += 1
        }
    }

    private func stopTimer() {
        print("⏹️ [HOME] stopTimer()")
        timer?.invalidate()
        timer = nil
    }
}

// MARK: - StatusBadge

struct StatusBadge: View {
    let state: VPNState

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
            Text(text)
                .font(.custom("WixMadeforText-Regular", size: 14 * sizeScreen()))
        }
        .foregroundColor(tint)
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
                .overlay(Capsule().stroke(Color.white.opacity(0.08), lineWidth: 1))
        )
    }

    private var text: String {
        switch state {
        case .waiting:      return "Подключаем…"
        case .disconnected: return "Сервер не подключён"
        case .connected:    return "Соединение защищено"
        }
    }

    private var icon: String {
        switch state {
        case .waiting:      return "clock.fill"
        case .disconnected: return "xmark.circle.fill"
        case .connected:    return "checkmark.circle.fill"
        }
    }

    private var tint: Color {
        switch state {
        case .waiting:      return .white.opacity(0.6)
        case .disconnected: return .red
        case .connected:    return .green
        }
    }
}

// MARK: - StatCard

struct StatCard: View {
    let title: String
    let value: String
    let iconSystemName: String
    let tint: Color
    let background: Material
    let caretSystemName: String

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.06))
                    .frame(width: 34, height: 34)
                Image(systemName: caretSystemName)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(tint)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.custom("WixMadeforText-Regular", size: 13 * sizeScreen()))
                    .foregroundColor(.white.opacity(0.55))

                Text(value)
                    .font(.custom("WixMadeforText-SemiBold", size: 16 * sizeScreen()))
                    .foregroundColor(.white)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .frame(height: 60)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(background)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
    }
}

// MARK: - PowerButton

struct PowerButton: View {
    let state: VPNState
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle().fill(Color.white.opacity(0.05)).frame(width: 280, height: 280)
                Circle().fill(Color.white.opacity(0.06)).frame(width: 220, height: 220)
                Circle().fill(Color.white.opacity(0.07)).frame(width: 170, height: 170)

                Circle()
                    .fill(coreColor.opacity(0.85))
                    .frame(width: 112, height: 112)
                    .overlay(
                        Circle().stroke(Color.white.opacity(0.25), lineWidth: 1)
                    )
                    .shadow(color: coreColor.opacity(0.25), radius: 20, x: 0, y: 12)

                Image(systemName: "power")
                    .font(.system(size: 34, weight: .semibold))
                    .foregroundColor(.white)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(state == .connected ? "Отключить VPN" : "Подключить VPN")
    }

    private var coreColor: Color {
        switch state {
        case .connected:    return .green
        case .disconnected: return .green
        case .waiting:      return .white.opacity(0.35)
        }
    }
}

// MARK: - Video Background (с логами + fallback)

struct VPNVideoBackground: View {
    let state: VPNState
    @StateObject private var controller = VPNVideoBackgroundController()
    @State private var lastState: VPNState = .disconnected

    var body: some View {
        ZStack {
            PlayerLayerView(player: controller.player)
                .ignoresSafeArea()

            // чуть затемнить, чтобы UI читался
            LinearGradient(
                colors: [Color.black.opacity(0.25), Color.black.opacity(0.55)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // если видео не найдено — покажем подсказку прямо на экране
            if let err = controller.debugOverlayText {
                VStack(spacing: 8) {
                    Text("VIDEO ERROR")
                        .font(.system(size: 14, weight: .bold))
                    Text(err)
                        .font(.system(size: 12))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 12)
                }
                .foregroundColor(.white)
                .padding(12)
                .background(Color.red.opacity(0.6), in: RoundedRectangle(cornerRadius: 12))
                .padding(.top, 60)
            }
        }
        .onAppear {
            print("🎬 [BG] onAppear state=\(state)")
            lastState = state
            controller.set(mode: state == .connected ? .green : .gray)
        }
        .onChange(of: state) { _, newValue in
            print("🎬 [BG] state change \(lastState) -> \(newValue)")

            if lastState == .connected && newValue == .disconnected {
                print("🎬 [BG] will play transition green_to_red then gray")
                controller.set(mode: .greenToRedThenGray)
            } else if newValue == .connected {
                print("🎬 [BG] will loop green")
                controller.set(mode: .green)
            } else {
                print("🎬 [BG] will loop gray")
                controller.set(mode: .gray)
            }

            lastState = newValue
        }
    }
}

// MARK: - PlayerLayerView (фикс: layoutSubviews)

final class PlayerContainerView: UIView {
    let playerLayer = AVPlayerLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        layer.addSublayer(playerLayer)
        playerLayer.videoGravity = .resizeAspectFill
        backgroundColor = .clear
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer.frame = bounds
    }
}

struct PlayerLayerView: UIViewRepresentable {
    let player: AVPlayer

    func makeUIView(context: Context) -> PlayerContainerView {
        let v = PlayerContainerView()
        v.playerLayer.player = player
        return v
    }

    func updateUIView(_ uiView: PlayerContainerView, context: Context) {
        uiView.playerLayer.player = player
    }
}

// MARK: - Controller (с логами)

@MainActor
final class VPNVideoBackgroundController: ObservableObject {
    let player = AVQueuePlayer()

    private var looper: AVPlayerLooper?
    private var endObserver: NSObjectProtocol?
    private var currentMode: Mode = .gray

    @Published var debugOverlayText: String? = nil

    enum Mode: Equatable {
        case gray
        case green
        case greenToRedThenGray
    }

    init() {
        print("🎬 [CTRL] init")
        player.isMuted = true
        player.actionAtItemEnd = .none
    }

    func set(mode: Mode) {
        guard mode != currentMode else {
            print("🎬 [CTRL] set(mode:) ignored (same mode) \(mode)")
            return
        }
        print("🎬 [CTRL] set(mode:) \(currentMode) -> \(mode)")
        currentMode = mode

        switch mode {
        case .gray:
            startLoop(file: "gray_loop", ext: "mp4")
        case .green:
            startLoop(file: "green_loop", ext: "mp4")
        case .greenToRedThenGray:
            playOnceThenLoop(
                onceFile: "green_to_red_loop", onceExt: "mp4",
                thenLoopFile: "gray_loop", thenLoopExt: "mp4"
            )
        }
    }

    private func urlFor(_ file: String, _ ext: String) -> URL? {
        let url = Bundle.main.url(forResource: file, withExtension: ext)
        print("🎬 [CTRL] lookup \(file).\(ext) -> \(url?.path ?? "NOT FOUND")")
        return url
    }

    private func startLoop(file: String, ext: String) {
        clearObserversAndLooper()

        guard let url = urlFor(file, ext) else {
            debugOverlayText = "NOT FOUND: \(file).\(ext)\nПроверь Target Membership + Copy Bundle Resources + имя файла (регистр!)."
            return
        }

        debugOverlayText = nil
        let item = AVPlayerItem(asset: AVAsset(url: url))

        player.removeAllItems()
        looper = AVPlayerLooper(player: player, templateItem: item)

        print("🎬 [CTRL] startLoop \(file).\(ext) | queueCount=\(player.items().count)")
        player.play()
        print("🎬 [CTRL] player.play() rate=\(player.rate)")
    }

    private func playOnceThenLoop(onceFile: String, onceExt: String,
                                  thenLoopFile: String, thenLoopExt: String) {
        clearObserversAndLooper()

        guard let url = urlFor(onceFile, onceExt) else {
            debugOverlayText = "NOT FOUND: \(onceFile).\(onceExt)\nFallback -> \(thenLoopFile).\(thenLoopExt)"
            startLoop(file: thenLoopFile, ext: thenLoopExt)
            return
        }

        debugOverlayText = nil
        let item = AVPlayerItem(asset: AVAsset(url: url))

        player.removeAllItems()
        player.insert(item, after: nil)

        print("🎬 [CTRL] playOnce \(onceFile).\(onceExt) | queueCount=\(player.items().count)")

        endObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: item,
            queue: .main
        ) { [weak self] _ in
            print("🎬 [CTRL] transition ended -> loop \(thenLoopFile).\(thenLoopExt)")
            self?.startLoop(file: thenLoopFile, ext: thenLoopExt)
        }

        player.play()
        print("🎬 [CTRL] player.play() rate=\(player.rate)")
    }

    private func clearObserversAndLooper() {
        if let endObserver {
            NotificationCenter.default.removeObserver(endObserver)
            self.endObserver = nil
            print("🎬 [CTRL] removed endObserver")
        }
        looper = nil
    }

    deinit {
        if let endObserver { NotificationCenter.default.removeObserver(endObserver) }
        print("🎬 [CTRL] deinit")
    }
}

#Preview {
    HomeView()
}

