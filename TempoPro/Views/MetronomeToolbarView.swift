//
//  MetronomeToolbarView.swift
//  TempoPro
//
//  Created by Meters on 26/2/2025.
//

import SwiftUI

struct CircularButtonStyle: ViewModifier {
    @Environment(\.metronomeTheme) var theme
    func body(content: Content) -> some View {
        content
            
            .foregroundStyle(theme.primaryColor)
            .frame(width: 60, height: 60)
            .background(RoundedRectangle(cornerRadius: 18).fill(theme.backgroundColor))
    }
}

extension View {
    func circularButton() -> some View {
        self.modifier(CircularButtonStyle())
    }
}

struct MetronomeToolbarView: View {
    var body: some View {
        HStack() {
            Button(action: {}) {
                Image("icon-timer")
                    .renderingMode(.template)
                    .circularButton()
            }
            Spacer()
            Button(action: {}) {
                Image("icon-play-list")
                    .renderingMode(.template)
                    .circularButton()
            }
            Spacer()
            Button(action: {}) {
                Image("icon-clap")
                    .renderingMode(.template)
                    .circularButton()
            }
            Spacer()
            Button(action: {}) {
                Image("icon-analysis")
                    .renderingMode(.template)
                    .circularButton()
            }
        }
        .font(.title2)
        .padding(.horizontal,30)
        .frame(maxWidth: .infinity)
        
    }
}

#Preview {
    MetronomeToolbarView()
} 
