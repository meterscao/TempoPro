//
//  MetronomeToolbarView.swift
//  TempoPro
//
//  Created by Meters on 26/2/2025.
//

import SwiftUI

struct CircularButtonStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .foregroundStyle(.black)
            .frame(width: 60, height: 60)
            .overlay(Circle().stroke(Color.primary, lineWidth: 2))
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
                Image(systemName: "music.note")
                    .circularButton()
            }
            Spacer()
            Button(action: {}) {
                Image(systemName: "speaker.wave.2")
                    .circularButton()
            }
            Spacer()
            Button(action: {}) {
                Image(systemName: "stopwatch")
                    .circularButton()
            }
            Spacer()
            Button(action: {}) {
                Image(systemName: "hand.raised")
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
