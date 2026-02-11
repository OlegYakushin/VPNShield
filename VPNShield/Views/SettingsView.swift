//
//  SettingsView.swift
//  VPNShield
//
//  Created by Oleg Yakushin on 14/7/25.
//
import SwiftUI

// MARK: - Theme

enum AppTheme: String, CaseIterable, Identifiable {
    case system, dark, light
    var id: String { rawValue }

    var title: String {
        switch self {
        case .system: return "Системная тема"
        case .dark:   return "Ночная тема"
        case .light:  return "Дневная тема"
        }
    }
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .dark:   return .dark
        case .light:  return .light
        }
    }
}

// MARK: - Routing

enum SettingsRoute: Hashable {
    case promo
}

// MARK: - Settings

struct SettingsView: View {
    let userID = "C13A9618-45B8-4064-90DE-2AE6A927126E"

    @State private var path: [SettingsRoute] = []
    @State private var showThemeSheet = false
    @AppStorage("appTheme") private var appThemeRaw: String = AppTheme.system.rawValue

    private var appTheme: AppTheme {
        get { AppTheme(rawValue: appThemeRaw) ?? .system }
        set { appThemeRaw = newValue.rawValue }
    }

    var body: some View {
        NavigationStack(path: $path) {
            VStack(spacing: 16) {
                Button(action: copyID) {
                    SettingsLabelView(icon: "copyIcon", text: "Скопировать ID")
                }
                Divider()

                Button {
                    path.append(.promo)
                } label: {
                    SettingsLabelView(icon: "promoIconGreen", text: "Активировать промокод")
                }
                Divider()

                Button {
                    showThemeSheet = true
                } label: {
                    SettingsLabelView(icon: "themeIcon", text: "Настройки темы")
                }
                Divider()

                Button(action: rateApp) {
                    SettingsLabelView(icon: "starIcon", text: "Оценить приложение")
                }
                Divider()

                Button(action: openTelegram) {
                    SettingsLabelView(icon: "tgIcon", text: "Канал в Telegram")
                }
                Divider()

                Button(action: deleteKey) {
                    SettingsLabelView(icon: "trashIcon", text: "Удалить ключ")
                }

                Text("ID: \(userID)")
                    .font(.footnote)
                    .foregroundColor(.gray)

                Spacer()
            }
            .padding(.top, 50)
            .padding(.horizontal, 16)
            .navigationTitle("Настройки")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: SettingsRoute.self) { route in
                switch route {
                case .promo:
                    PromoView()
                }
            }
            .sheet(isPresented: $showThemeSheet) {
                ThemePickerSheet(
                    selected: appTheme,
                    onSelect: { theme in
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }
                )
                .presentationDetents([.fraction(0.55)])
                .presentationCornerRadius(24)
                .presentationBackground(.ultraThinMaterial)
            }
        }
    }

    // MARK: - Actions
    func copyID() { UIPasteboard.general.string = userID }
    func rateApp() { /* Redirect to App Store */ }
    func openTelegram() { /* Open Telegram URL */ }
    func deleteKey() { /* Handle key deletion */ }
}

// MARK: - Promo Screen

struct PromoView: View {
    enum Status {
        case idle
        case loading
        case success
        case notFound
        case alreadyUsed
    }

    @State private var code: String = ""
    @State private var status: Status = .idle
    @FocusState private var focused: Bool

    var body: some View {
        ZStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    HStack(spacing: 12) {
                        Image(systemName: "calendar.badge.plus")
                            .font(.system(size: 40, weight: .semibold))
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Получите 7 дней бесплатно")
                                .font(.title2).bold()
                            Text("Введите промокод или код друга, чтобы активировать бесплатный период пользования.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.top, 8)

                    // Поле ввода
                    HStack(spacing: 12) {
                        Image(systemName: "number.square")
                            .foregroundColor(.secondary)
                        TextField("Введите промокод", text: $code)
                            .textInputAutocapitalization(.characters)
                            .autocorrectionDisabled()
                            .keyboardType(.asciiCapable)
                            .focused($focused)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color(.secondarySystemBackground))
                    )

                    // Кнопка
                    Button(action: activate) {
                        HStack {
                            if status == .loading {
                                ProgressView().progressViewStyle(.circular)
                            }
                            Text("Активировать промокод")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 16).fill(Color.green))
                        .foregroundColor(.black)
                    }
                    .disabled(code.isEmpty || status == .loading)

                    Spacer(minLength: 40)
                }
                .padding(16)
            }

            // Toasts
            VStack {
                Spacer()
                Group {
                    switch status {
                    case .success:
                        PromoToastView(
                            systemIcon: "checkmark.seal.fill",
                            title: "Промокод активирован!",
                            subtitle: "Вам начислено 7 дней бесплатного доступа.",
                            style: .success
                        )
                    case .notFound:
                        PromoToastView(
                            systemIcon: "xmark.octagon.fill",
                            title: "Промокод не найден",
                            subtitle: "Убедитесь, что вы ввели код без ошибок.",
                            style: .error
                        )
                    case .alreadyUsed:
                        PromoToastView(
                            systemIcon: "exclamationmark.triangle.fill",
                            title: "Вы уже активировали промокод ранее",
                            subtitle: "Один промокод — один аккаунт.",
                            style: .warning
                        )
                    default:
                        EmptyView()
                    }
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
            .animation(.easeInOut, value: status)
        }
        .navigationTitle("Активировать промокод")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { focused = true }
    }

    private func activate() {
        focused = false
        guard !code.isEmpty else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        status = .loading

        // Имитируем запрос
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            let normalized = code.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()

            if normalized == "V1P2N3" {
                status = .success
            } else if normalized == "V1P2N3-USED" {
                status = .alreadyUsed
            } else {
                status = .notFound
            }

            // Автоскрытие тоста через 3 секунды
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                if status != .loading { status = .idle }
            }
        }
    }
}

// MARK: - Theme Picker Sheet (custom modal)

struct ThemePickerSheet: View {
    let selected: AppTheme
    var onSelect: (AppTheme) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 16) {
            // шапка
            VStack(spacing: 12) {
                ZStack {
                    Circle().fill(.ultraThinMaterial).frame(width: 64, height: 64)
                    Image(systemName: "cube.fill")
                        .font(.system(size: 28, weight: .bold))
                }
                Text("Настройки темы").font(.title3).bold()
                Text("Выберите тему для приложения:")
                    .font(.subheadline).foregroundColor(.secondary)
            }
            .padding(.top, 8)

            // Опции
            VStack(spacing: 0) {
                ForEach([AppTheme.system, .dark, .light]) { theme in
                    Button {
                        onSelect(theme)
                        dismiss()
                    } label: {
                        HStack {
                            Text(theme.title)
                            Spacer()
                            if theme == selected {
                                Image(systemName: "checkmark")
                            }
                        }
                        .padding(.vertical, 14)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)

                    if theme != .light {
                        Divider()
                    }
                }
            }
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(.secondarySystemBackground))
            )

            Button {
                dismiss()
            } label: {
                Text("Отменить")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .background(
                RoundedRectangle(cornerRadius: 16).fill(Color(.tertiarySystemFill))
            )
            .padding(.bottom, 8)
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }
}

// MARK: - Toast View

struct PromoToastView: View {
    enum Style { case success, error, warning }

    let systemIcon: String
    let title: String
    let subtitle: String
    let style: Style

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: systemIcon)
                .imageScale(.large)
                .padding(10)
                .background(iconBG)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(title).fontWeight(.semibold)
                Text(subtitle).font(.footnote).foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.white.opacity(0.06))
        )
        .shadow(radius: 12, y: 4)
    }

    private var iconBG: some ShapeStyle {
        switch style {
        case .success: return Color.green.opacity(0.25).gradient
        case .error:   return Color.red.opacity(0.25).gradient
        case .warning: return Color.yellow.opacity(0.25).gradient
        }
    }
}


// MARK: - Preview

#Preview {
    SettingsView()
        .preferredColorScheme(.dark) // для превью
}
