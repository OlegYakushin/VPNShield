//
//  OnboardingView.swift
//  VPNShield
//
//  Created by Oleg Yakushin on 14/7/25.
//

import SwiftUI
import AVKit

struct OnboardingStep: Identifiable {
    let id = UUID()
    let title: String
    let subtitleMarkdown: String
    let imageName: String
    let progress: Double
}

let onboardingSteps: [OnboardingStep] = [
    .init(
        title: "Мгновенное\nподключение",
        subtitleMarkdown: "**Всего один клик — и вы в безопасности.** Никаких регистраций, сложных настроек или лишних действий. Быстро, просто и удобно.",
        imageName: "vpn1",
        progress: 1.0/3.0
    ),
    .init(
        title: "Включил один раз — и забыл",
        subtitleMarkdown: "Соединение работает **стабильно и незаметно**. Просто оставьте защиту включённой — и не беспокойтесь, что сайты или приложения не откроются.",
        imageName: "vpn2",
        progress: 2.0/3.0
    ),
    .init(
        title: "Введи промокод — получи бонус",
        subtitleMarkdown: "В начале можно активировать промокод или код друга. **Это подарит вам 7 дней защищённого интернета** без ограничений.",
        imageName: "vpn3",
        progress: 3.0/3.0
    )
]

extension String {
    func onboardingAttributed(fontSize: CGFloat) -> AttributedString {
        var attr = (try? AttributedString(
            markdown: self,
            options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        )) ?? AttributedString(self)

        // База: Regular + белый 60%
        attr.font = .custom("WixMadeforText-Regular", size: fontSize)
        attr.foregroundColor = .white.opacity(0.6)

        // **bold**: SemiBold + белый 100%
        for run in attr.runs {
            if run.inlinePresentationIntent?.contains(.stronglyEmphasized) == true {
                attr[run.range].font = .custom("WixMadeforText-SemiBold", size: fontSize)
                attr[run.range].foregroundColor = .white
            }
        }

        return attr
    }
}


struct OnboardingView: View {
    @Environment(\.colorScheme) var colorScheme
    @State private var currentStep = 0
    @State private var player = AVPlayer()
    @AppStorage("showOnboarding") var showOnboarding: Bool = true

    var body: some View {
        ZStack {
    Image(onboardingSteps[currentStep].imageName)
                .resizable()
                .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
                .ignoresSafeArea()
     
             
                                        VStack(spacing: 40 * sizeScreen()) {
                                            SegmentedProgressBar(
                                                total: onboardingSteps.count,
                                                currentIndex: currentStep,
                                                height: 4,
                                                spacing: 12,
                                                activeColor: .greenOnboard,
                                                inactiveColor: Color.white.opacity(0.18),
                                                fillDuration: 0.45
                                            )
                                                .padding(.horizontal)
                                            .foregroundColor(.green)
                                            .padding(.bottom)
                                            .padding(.top, 50 * sizeScreen())
                                            VStack(alignment: .leading, spacing: 30 * sizeScreen()) {
                                                HStack {
                                                    Text(onboardingSteps[currentStep].title)
                                                    
                                                        .font(.custom("WixMadeforText-SemiBold", size: 24 * sizeScreen()))
                                                        .multilineTextAlignment(.leading)
                                                        .foregroundColor(.white)
                                                    Spacer()
                                                }
                                                .frame(width: 321 * sizeScreen())
                                                HStack {
                                                    Text(onboardingSteps[currentStep].subtitleMarkdown.onboardingAttributed(fontSize: 14 * sizeScreen()))
                                     
                                                    .multilineTextAlignment(.leading)
                                                Spacer()
                                            }
                                                .frame(width: 321 * sizeScreen())
                                            }
                                            Spacer()
                                            VStack {
                                                Button(action: {
                                                    if currentStep < onboardingSteps.count - 1 {
                                                        currentStep += 1
                                                    } else {
                                                        showOnboarding = false
                                                    }
                                                }) {
                                                    Image("buttonCont")
                                                        .resizable()
                                                        .frame(width: 320 * sizeScreen(), height: 79 * sizeScreen())
                                                        .overlay(
                                                            Text("Продолжить")
                                                                .font(.custom("WixMadeforText-Bold", size: 16 * sizeScreen()))
                                                                .multilineTextAlignment(.center)
                                                                .foregroundColor(.white)
                                                        )
                                                }
                                                Button(action: {
                                                    showOnboarding = false
                                                }){  Text("Пропустить")
                                                        .font(.custom("WixMadeforText-Medium", size: 12 * sizeScreen()))
                                                        .multilineTextAlignment(.center)
                                                        .foregroundColor(.whiteOp)
                                                    
                                                }
                                               
                                            }
                                            .padding(.bottom, 50 * sizeScreen())
                                          
                                           
                                        }
                     
         
                
         
            
        }
        .animation(.easeInOut, value: currentStep)
    }
}

#Preview {
    OnboardingView()
}
import SwiftUI

struct SegmentedProgressBar: View {
    let total: Int
    let currentIndex: Int // 0...total-1

    var height: CGFloat = 4
    var spacing: CGFloat = 12
    var activeColor: Color = .green
    var inactiveColor: Color = Color.white.opacity(0.18)
    var fillDuration: Double = 0.35

    @State private var animatedIndex: Int = 0

    var body: some View {
        HStack(spacing: spacing) {
            ForEach(0..<total, id: \.self) { i in
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(inactiveColor)

                        Capsule()
                            .fill(activeColor)
                            .scaleEffect(x: fillAmount(for: i), y: 1, anchor: .leading)
                            .animation(.easeInOut(duration: fillDuration), value: animatedIndex)
                    }
                }
                .frame(height: height)
            }
        }
        .onAppear { animatedIndex = currentIndex }
        .onChange(of: currentIndex) { newValue in
            animatedIndex = newValue
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Прогресс")
        .accessibilityValue("\(currentIndex + 1) из \(total)")
    }

    private func fillAmount(for segment: Int) -> CGFloat {
        if segment < animatedIndex { return 1 }     // уже пройденные — полностью заполнены
        if segment == animatedIndex { return 1 }    // текущий — “заливаем” до конца (анимацией)
        return 0                                    // будущие — пустые
    }
}
