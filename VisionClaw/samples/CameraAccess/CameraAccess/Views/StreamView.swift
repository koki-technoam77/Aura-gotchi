/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

//
// StreamView.swift
//
// Main UI for video streaming from Meta wearable devices using the DAT SDK.
// This view demonstrates the complete streaming API: video streaming with real-time display, photo capture,
// and error handling. Extended with Gemini Live AI assistant integration.
//

import MWDATCore
import SwiftUI

struct StreamView: View {
  @ObservedObject var viewModel: StreamSessionViewModel
  @ObservedObject var wearablesVM: WearablesViewModel
  @ObservedObject var geminiVM: GeminiSessionViewModel
  
  var body: some View {
    ZStack {
      // Dark game background (no full-screen camera)
      LinearGradient(
        colors: [
          Color(red: 0.04, green: 0.04, blue: 0.12),
          Color(red: 0.06, green: 0.04, blue: 0.16),
          Color(red: 0.02, green: 0.02, blue: 0.08)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      )
      .edgesIgnoringSafeArea(.all)

      // Main game UI
      VStack {
        // Top bar: status + camera PiP
        HStack(alignment: .top) {
          if geminiVM.isGeminiActive {
            GeminiStatusBar(geminiVM: geminiVM)
          }
          Spacer()
          // Camera PiP thumbnail (top-right)
          cameraPiP
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)

        Spacer()

        // Familiar creature display (always visible)
        FamiliarView(
          gameState: geminiVM.gameState,
          aiTranscript: geminiVM.aiTranscript
        )

        Spacer()

        VStack(spacing: 8) {
          // Game HUD (gauges + skills)
          GameHUDView(gameState: geminiVM.gameState)

          // Transcript (user + AI text) — only when Gemini active
          if geminiVM.isGeminiActive {
            if !geminiVM.userTranscript.isEmpty || !geminiVM.aiTranscript.isEmpty {
              TranscriptView(
                userText: geminiVM.userTranscript,
                aiText: geminiVM.aiTranscript
              )
            }

            ToolCallStatusView(status: geminiVM.toolCallStatus)

            if geminiVM.isModelSpeaking {
              HStack(spacing: 8) {
                Image(systemName: "speaker.wave.2.fill")
                  .foregroundColor(.white)
                  .font(.system(size: 14))
                SpeakingIndicator()
              }
              .padding(.horizontal, 16)
              .padding(.vertical, 8)
              .background(Color.black.opacity(0.5))
              .cornerRadius(20)
            }
          }
        }
        .padding(.bottom, 80)
      }
      .padding(.horizontal, 8)

      // Bottom controls layer
      VStack {
        Spacer()
        ControlsView(viewModel: viewModel, geminiVM: geminiVM)
      }
      .padding(.all, 24)
    }
    .onDisappear {
      Task {
        if viewModel.streamingStatus != .stopped {
          await viewModel.stopSession()
        }
        if geminiVM.isGeminiActive {
          geminiVM.stopSession()
        }
      }
    }
    // Show captured photos from DAT SDK in a preview sheet
    .sheet(isPresented: $viewModel.showPhotoPreview) {
      if let photo = viewModel.capturedPhoto {
        PhotoPreviewView(
          photo: photo,
          onDismiss: {
            viewModel.dismissPhotoPreview()
          }
        )
      }
    }
    // Gemini error alert
    .alert("AI Assistant", isPresented: Binding(
      get: { geminiVM.errorMessage != nil },
      set: { if !$0 { geminiVM.errorMessage = nil } }
    )) {
      Button("OK") { geminiVM.errorMessage = nil }
    } message: {
      Text(geminiVM.errorMessage ?? "")
    }
  }

  // MARK: - Camera PiP Thumbnail
  private var cameraPiP: some View {
    Group {
      if let videoFrame = viewModel.currentVideoFrame, viewModel.hasReceivedFirstFrame {
        Image(uiImage: videoFrame)
          .resizable()
          .aspectRatio(contentMode: .fill)
          .frame(width: 120, height: 90)
          .clipped()
          .cornerRadius(10)
          .overlay(
            RoundedRectangle(cornerRadius: 10)
              .strokeBorder(Color.cyan.opacity(0.5), lineWidth: 1)
          )
          .shadow(color: .black.opacity(0.5), radius: 4, y: 2)
      } else {
        RoundedRectangle(cornerRadius: 10)
          .fill(Color.white.opacity(0.05))
          .frame(width: 120, height: 90)
          .overlay(
            Image(systemName: "video.slash")
              .foregroundColor(.white.opacity(0.3))
          )
          .overlay(
            RoundedRectangle(cornerRadius: 10)
              .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
          )
      }
    }
  }
}

// Extracted controls for clarity
struct ControlsView: View {
  @ObservedObject var viewModel: StreamSessionViewModel
  @ObservedObject var geminiVM: GeminiSessionViewModel

  var body: some View {
    // Controls row
    HStack(spacing: 8) {
      CustomButton(
        title: "Stop streaming",
        style: .destructive,
        isDisabled: false
      ) {
        Task {
          await viewModel.stopSession()
        }
      }

      // Photo button (glasses mode only — DAT SDK capture)
      if viewModel.streamingMode == .glasses {
        CircleButton(icon: "camera.fill", text: nil) {
          viewModel.capturePhoto()
        }
      }

      // Gemini AI button
      CircleButton(
        icon: geminiVM.isGeminiActive ? "waveform.circle.fill" : "waveform.circle",
        text: "AI"
      ) {
        Task {
          if geminiVM.isGeminiActive {
            geminiVM.stopSession()
          } else {
            await geminiVM.startSession()
          }
        }
      }
    }
  }
}
