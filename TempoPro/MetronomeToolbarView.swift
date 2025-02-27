//
//  MetronomeToolbarView.swift
//  TempoPro
//
//  Created by Meters on 26/2/2025.
//

import SwiftUI

struct MetronomeToolbarView: View {
    var body: some View {
        HStack(spacing: 40) {
            Button(action: {}) {
                Image(systemName: "music.note")
            }
            Button(action: {}) {
                Image(systemName: "speaker.wave.2")
            }
            Button(action: {}) {
                Image(systemName: "stopwatch")
            }
            Button(action: {}) {
                Image(systemName: "hand.raised")
            }
        }
        .font(.title2)
        .padding()
    }
}

#Preview {
    MetronomeToolbarView()
} 