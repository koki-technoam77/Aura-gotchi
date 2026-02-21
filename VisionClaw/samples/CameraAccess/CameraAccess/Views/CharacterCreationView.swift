import SwiftUI
import PhotosUI
import UIKit

// MARK: - CharacterCreationView

struct CharacterCreationView: View {
    @ObservedObject var gameState: GameState
    var onComplete: () -> Void

    // MARK: Input state

    @State private var selectedMode: CreationMode = .text
    @State private var textPrompt: String = ""
    @State private var selectedImage: UIImage? = nil
    @State private var drawingImage: UIImage? = nil

    // MARK: Generation state

    @State private var isGenerating: Bool = false
    @State private var generatedImageURL: URL? = nil
    @State private var errorMessage: String? = nil

    // MARK: PhotosPicker state

    @State private var selectedPhotoItem: PhotosPickerItem? = nil

    // MARK: Animation state

    @State private var characterName: String = ""
    @State private var characterPersonality: String = ""

    @State private var titlePulse: Bool = false
    @State private var resultFloating: Bool = false

    enum CreationMode: String, CaseIterable {
        case text = "Text"
        case photo = "Photo"
        case draw = "Draw"
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color(red: 0.04, green: 0.04, blue: 0.12),
                    Color(red: 0.08, green: 0.06, blue: 0.18),
                    Color(red: 0.02, green: 0.02, blue: 0.08)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Subtle particle dots
            particleBackground

            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Title
                    titleSection

                    // Mode picker
                    modePicker

                    // Input area
                    inputArea

                    // Error message
                    if let error = errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.horizontal, 24)
                            .transition(.opacity)
                    }

                    // Generated result
                    if let url = generatedImageURL {
                        resultSection(url: url)

                        // Name & personality input
                        characterProfileInput
                    }

                    // Action buttons
                    actionButtons

                    Spacer(minLength: 40)
                }
                .padding(.top, 20)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: selectedMode)
        .animation(.easeInOut(duration: 0.3), value: generatedImageURL)
        .animation(.easeInOut(duration: 0.3), value: errorMessage)
    }

    // MARK: - Title Section

    private var titleSection: some View {
        VStack(spacing: 8) {
            Text("\u{1F95A}")
                .font(.system(size: 60))
                .scaleEffect(titlePulse ? 1.08 : 1.0)
                .animation(
                    .easeInOut(duration: 2.0).repeatForever(autoreverses: true),
                    value: titlePulse
                )
                .onAppear { titlePulse = true }

            Text("Create Your Creature")
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundColor(.white)

            Text("Bring your creature to life from text, photo, or drawing")
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.5))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
    }

    // MARK: - Mode Picker

    private var modePicker: some View {
        Picker("CreationMode", selection: $selectedMode) {
            ForEach(CreationMode.allCases, id: \.self) { mode in
                Text(mode.rawValue).tag(mode)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, 24)
        .colorMultiply(.cyan)
    }

    // MARK: - Input Area

    @ViewBuilder
    private var inputArea: some View {
        Group {
            switch selectedMode {
            case .text:
                textInputArea
            case .photo:
                photoInputArea
            case .draw:
                drawInputArea
            }
        }
        .padding(.horizontal, 24)
    }

    // MARK: Text Input

    private var textInputArea: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Describe your creature")
                    .font(.subheadline.bold())
                    .foregroundColor(.white.opacity(0.8))

                TextField("e.g. fire slime, ice dragon with wings", text: $textPrompt)
                    .textFieldStyle(.plain)
                    .font(.body)
                    .foregroundColor(.white)
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white.opacity(0.08))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .strokeBorder(Color.cyan.opacity(0.3), lineWidth: 1)
                            )
                    )

                Text("Describe anything you imagine!")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.4))
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .environment(\.colorScheme, .dark)
        )
    }

    // MARK: Photo Input

    private var photoInputArea: some View {
        VStack(spacing: 16) {
            if let image = selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 240)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(Color.cyan.opacity(0.4), lineWidth: 1)
                    )
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 48))
                        .foregroundColor(.cyan.opacity(0.6))

                    Text("Choose a photo")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.6))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 200)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .strokeBorder(
                                    Color.cyan.opacity(0.2),
                                    style: StrokeStyle(lineWidth: 2, dash: [8, 6])
                                )
                        )
                )
            }

            PhotosPicker(
                selection: $selectedPhotoItem,
                matching: .images,
                photoLibrary: .shared()
            ) {
                HStack(spacing: 8) {
                    Image(systemName: "photo.badge.plus")
                    Text(selectedImage == nil ? "Choose Photo" : "Choose Another")
                }
                .font(.subheadline.bold())
                .foregroundColor(.cyan)
                .padding(.vertical, 12)
                .padding(.horizontal, 24)
                .background(
                    Capsule()
                        .fill(Color.cyan.opacity(0.15))
                        .overlay(
                            Capsule()
                                .strokeBorder(Color.cyan.opacity(0.4), lineWidth: 1)
                        )
                )
            }
            .onChange(of: selectedPhotoItem) { _, newItem in
                loadPhoto(from: newItem)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .environment(\.colorScheme, .dark)
        )
    }

    // MARK: Draw Input

    private var drawInputArea: some View {
        VStack(spacing: 12) {
            Text("Draw with your finger")
                .font(.subheadline.bold())
                .foregroundColor(.white.opacity(0.8))

            DrawingCanvasView(drawingImage: $drawingImage)
                .frame(height: 280)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Color.cyan.opacity(0.3), lineWidth: 1)
                )
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .environment(\.colorScheme, .dark)
        )
    }

    // MARK: - Result Section

    private func resultSection(url: URL) -> some View {
        VStack(spacing: 16) {
            Text("Your creature is born!")
                .font(.headline)
                .foregroundColor(.cyan)

            ZStack {
                // White background for blend mode
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
                    .frame(width: 240, height: 240)

                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFit()
                            .blendMode(.multiply)
                    case .failure:
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundColor(.orange)
                    default:
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(.cyan)
                    }
                }
                .frame(width: 240, height: 240)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .shadow(color: .cyan.opacity(0.4), radius: 20, y: 4)
            .offset(y: resultFloating ? -8 : 8)
            .animation(
                .easeInOut(duration: 2.0).repeatForever(autoreverses: true),
                value: resultFloating
            )
            .onAppear { resultFloating = true }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .environment(\.colorScheme, .dark)
        )
        .padding(.horizontal, 24)
        .transition(.scale.combined(with: .opacity))
    }

    // MARK: - Character Profile Input

    private var characterProfileInput: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Name")
                    .font(.subheadline.bold())
                    .foregroundColor(.white.opacity(0.8))

                TextField("Name your creature", text: $characterName)
                    .textFieldStyle(.plain)
                    .font(.body)
                    .foregroundColor(.white)
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.08))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .strokeBorder(Color.cyan.opacity(0.3), lineWidth: 1)
                            )
                    )
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Personality & Speaking Style")
                    .font(.subheadline.bold())
                    .foregroundColor(.white.opacity(0.8))

                TextField("e.g. Cool robot, speaks formally / Cheerful slime, uses lots of emoji", text: $characterPersonality, axis: .vertical)
                    .textFieldStyle(.plain)
                    .font(.body)
                    .foregroundColor(.white)
                    .lineLimit(3...6)
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.08))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .strokeBorder(Color.cyan.opacity(0.3), lineWidth: 1)
                            )
                    )

                Text("This affects how your creature talks!")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.4))
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .environment(\.colorScheme, .dark)
        )
        .padding(.horizontal, 24)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: 12) {
            if generatedImageURL != nil {
                // Adventure button — save and proceed
                Button {
                    saveAndComplete()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                        Text("Let's go on an adventure!")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        LinearGradient(
                            colors: [.cyan, .blue],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(28)
                    .shadow(color: .cyan.opacity(0.5), radius: 12, y: 4)
                }
                .padding(.horizontal, 24)

                // Retry button
                Button {
                    withAnimation {
                        generatedImageURL = nil
                        resultFloating = false
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.counterclockwise")
                        Text("Try Again")
                    }
                    .font(.subheadline.bold())
                    .foregroundColor(.white.opacity(0.7))
                    .padding(.vertical, 12)
                    .padding(.horizontal, 24)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.1))
                            .overlay(
                                Capsule()
                                    .strokeBorder(Color.white.opacity(0.2), lineWidth: 1)
                            )
                    )
                }

            } else {
                // Generate button
                Button {
                    Task { await generate() }
                } label: {
                    HStack(spacing: 8) {
                        if isGenerating {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .tint(.white)
                                .scaleEffect(0.85)
                        } else {
                            Image(systemName: "wand.and.stars")
                        }
                        Text(generateButtonTitle)
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        LinearGradient(
                            colors: isGenerateDisabled
                                ? [Color.gray.opacity(0.4), Color.gray.opacity(0.3)]
                                : [.cyan, .blue],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(28)
                    .shadow(
                        color: isGenerateDisabled ? .clear : .cyan.opacity(0.4),
                        radius: 12,
                        y: 4
                    )
                }
                .disabled(isGenerateDisabled)
                .padding(.horizontal, 24)
            }
        }
    }

    // MARK: - Helpers

    private var generateButtonTitle: String {
        if isGenerating { return "Generating..." }
        switch selectedMode {
        case .text: return "Generate"
        case .photo: return "Generate from Photo"
        case .draw: return "Generate from Drawing"
        }
    }

    private var isGenerateDisabled: Bool {
        if isGenerating { return true }
        switch selectedMode {
        case .text: return textPrompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .photo: return selectedImage == nil
        case .draw: return drawingImage == nil
        }
    }

    // MARK: - Photo Loading

    private func loadPhoto(from item: PhotosPickerItem?) {
        guard let item else { return }
        item.loadTransferable(type: Data.self) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let data):
                    if let data, let uiImage = UIImage(data: data) {
                        self.selectedImage = uiImage
                        self.generatedImageURL = nil
                        self.errorMessage = nil
                    }
                case .failure(let error):
                    self.errorMessage = "Failed to load photo: \(error.localizedDescription)"
                }
            }
        }
    }

    // MARK: - Generation

    private func generate() async {
        errorMessage = nil
        isGenerating = true
        generatedImageURL = nil

        NSLog("[CharacterCreation] generate() called, mode=%@", selectedMode.rawValue)

        let result: CharacterGenerationResult

        switch selectedMode {
        case .text:
            NSLog("[CharacterCreation] Generating from text: %@", textPrompt)
            result = await CharacterGenerationService.generateFromText(
                prompt: textPrompt,
                behavior: "",
                gameState: gameState
            )

        case .photo:
            guard let image = selectedImage else {
                errorMessage = "No photo selected"
                isGenerating = false
                return
            }
            NSLog("[CharacterCreation] Generating from photo: %dx%d", Int(image.size.width), Int(image.size.height))
            result = await CharacterGenerationService.generateFromImage(
                image: image,
                gameState: gameState
            )

        case .draw:
            guard let image = drawingImage else {
                NSLog("[CharacterCreation] drawingImage is nil — user has not drawn yet")
                errorMessage = "Draw something first"
                isGenerating = false
                return
            }
            NSLog("[CharacterCreation] Generating from drawing: %dx%d", Int(image.size.width), Int(image.size.height))
            result = await CharacterGenerationService.generateFromImage(
                image: image,
                gameState: gameState
            )
        }

        if let url = result.imageURL {
            NSLog("[CharacterCreation] Generation succeeded: %@", url.absoluteString)
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                generatedImageURL = url
            }
        } else {
            let detail = result.errorDetail ?? "Unknown error"
            NSLog("[CharacterCreation] Generation returned nil — error: %@", detail)
            errorMessage = "Generation failed: \(detail)"
        }

        isGenerating = false
    }

    // MARK: - Save & Complete

    private func saveAndComplete() {
        // gameState is already populated by CharacterGenerationService.generateFromText/Image
        // Ensure currentVisualURL is set (in case gameState was not passed during generation)
        if gameState.currentVisualURL == nil {
            gameState.currentVisualURL = generatedImageURL
        }

        // Set base attributes from the input if not already set
        if gameState.baseAttributes.isEmpty || gameState.baseAttributes == "cute generic creature" {
            switch selectedMode {
            case .text:
                gameState.baseAttributes = textPrompt
            case .photo:
                gameState.baseAttributes = "photo-based creature"
            case .draw:
                gameState.baseAttributes = "hand-drawn creature"
            }
        }

        // Set name and personality for system prompt injection
        let trimmedName = characterName.trimmingCharacters(in: .whitespacesAndNewlines)
        gameState.name = trimmedName.isEmpty ? "AIアバター" : trimmedName
        gameState.personalityPrompt = characterPersonality.trimmingCharacters(in: .whitespacesAndNewlines)

        gameState.save()
        onComplete()
    }

    // MARK: - Particle Background

    private var particleBackground: some View {
        GeometryReader { geo in
            ForEach(0..<20, id: \.self) { i in
                Circle()
                    .fill(Color.cyan.opacity(Double.random(in: 0.03...0.1)))
                    .frame(width: CGFloat.random(in: 2...6))
                    .position(
                        x: CGFloat.random(in: 0...geo.size.width),
                        y: CGFloat.random(in: 0...geo.size.height)
                    )
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - DrawingCanvasView

struct DrawingCanvasView: View {
    @Binding var drawingImage: UIImage?
    @State private var lines: [[CGPoint]] = []
    @State private var currentLine: [CGPoint] = []

    var body: some View {
        VStack(spacing: 8) {
            // Canvas
            ZStack {
                // White drawing background
                Color.white

                // Rendered strokes
                Canvas { context, _ in
                    for line in lines {
                        drawStroke(line, in: &context)
                    }
                    if !currentLine.isEmpty {
                        drawStroke(currentLine, in: &context)
                    }
                }
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        currentLine.append(value.location)
                    }
                    .onEnded { _ in
                        if !currentLine.isEmpty {
                            lines.append(currentLine)
                            currentLine = []
                            renderToImage()
                        }
                    }
            )

            // Clear button
            Button {
                lines = []
                currentLine = []
                drawingImage = nil
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "trash")
                    Text("Clear")
                }
                .font(.caption.bold())
                .foregroundColor(.white.opacity(0.7))
                .padding(.vertical, 6)
                .padding(.horizontal, 16)
                .background(
                    Capsule()
                        .fill(Color.white.opacity(0.1))
                )
            }
        }
    }

    private func drawStroke(_ points: [CGPoint], in context: inout GraphicsContext) {
        guard points.count > 1 else { return }
        var path = Path()
        path.move(to: points[0])
        for i in 1..<points.count {
            path.addLine(to: points[i])
        }
        context.stroke(
            path,
            with: .color(.black),
            style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round)
        )
    }

    @MainActor
    private func renderToImage() {
        // Use UIGraphicsImageRenderer (UIKit) instead of SwiftUI ImageRenderer+Canvas
        // because SwiftUI Canvas inside ImageRenderer can produce nil cgImage.
        let targetSize = CGSize(width: 512, height: 512)
        let uiRenderer = UIGraphicsImageRenderer(size: targetSize)

        let image = uiRenderer.image { ctx in
            // White background
            UIColor.white.setFill()
            ctx.fill(CGRect(origin: .zero, size: targetSize))

            // Draw strokes scaled from on-screen canvas to 512x512
            UIColor.black.setStroke()
            for line in lines {
                guard line.count > 1 else { continue }
                let bezier = UIBezierPath()
                bezier.lineWidth = 3.0
                bezier.lineCapStyle = .round
                bezier.lineJoinStyle = .round
                bezier.move(to: line[0])
                for i in 1..<line.count {
                    bezier.addLine(to: line[i])
                }
                bezier.stroke()
            }
        }

        drawingImage = image
        NSLog("[DrawingCanvas] renderToImage: produced %dx%d image", Int(image.size.width), Int(image.size.height))
    }
}

// MARK: - Preview

#Preview {
    CharacterCreationView(
        gameState: {
            let gs = GameState()
            gs.reset()
            return gs
        }(),
        onComplete: {
            print("Character creation complete!")
        }
    )
}
