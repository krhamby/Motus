//
//  CarManualAssistantView.swift
//  Motus
//
//  AI-powered car manual assistant using Apple Intelligence
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct CarManualAssistantView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var vehicles: [Vehicle]

    @State private var selectedVehicle: Vehicle?
    @State private var messages: [ChatMessage] = []
    @State private var inputText = ""
    @State private var isProcessing = false
    @State private var showingDocumentPicker = false
    @State private var manualDocuments: [ManualDocument] = []

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Vehicle Selector
                if !vehicles.isEmpty {
                    Picker("Vehicle", selection: $selectedVehicle) {
                        Text("Select Vehicle").tag(nil as Vehicle?)
                        ForEach(vehicles) { vehicle in
                            Text(vehicle.displayName).tag(vehicle as Vehicle?)
                        }
                    }
                    .pickerStyle(.menu)
                    .padding()
                    .background(Color(.systemGray6))
                }

                // Manuals Section
                if let vehicle = selectedVehicle {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            Button {
                                showingDocumentPicker = true
                            } label: {
                                VStack {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.title)
                                    Text("Add Manual")
                                        .font(.caption)
                                }
                                .frame(width: 100, height: 100)
                                .background(Color(.systemGray6))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }

                            ForEach(manualDocuments) { doc in
                                ManualDocumentCard(document: doc)
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical, 8)
                }

                Divider()

                // Chat Messages
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            if messages.isEmpty {
                                VStack(spacing: 20) {
                                    Image(systemName: "bubble.left.and.bubble.right.fill")
                                        .font(.system(size: 50))
                                        .foregroundStyle(.accent)
                                    Text("AI Car Manual Assistant")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                    Text("Ask questions about your vehicle's manual")
                                        .foregroundStyle(.secondary)
                                        .multilineTextAlignment(.center)

                                    VStack(alignment: .leading, spacing: 12) {
                                        Text("Try asking:")
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                        SuggestedQuestionButton(question: "How do I change the oil?", action: askQuestion)
                                        SuggestedQuestionButton(question: "What's the recommended tire pressure?", action: askQuestion)
                                        SuggestedQuestionButton(question: "How often should I rotate the tires?", action: askQuestion)
                                        SuggestedQuestionButton(question: "What type of brake fluid should I use?", action: askQuestion)
                                    }
                                    .padding()
                                    .background(Color(.systemGray6))
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                                .padding()
                                .frame(maxHeight: .infinity)
                            } else {
                                ForEach(messages) { message in
                                    MessageBubble(message: message)
                                        .id(message.id)
                                }
                            }

                            if isProcessing {
                                HStack {
                                    ProgressView()
                                    Text("Thinking...")
                                        .foregroundStyle(.secondary)
                                }
                                .padding()
                            }
                        }
                        .padding()
                    }
                    .onChange(of: messages.count) { _, _ in
                        if let lastMessage = messages.last {
                            withAnimation {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                }

                Divider()

                // Input Area
                HStack(spacing: 12) {
                    TextField("Ask about your car manual...", text: $inputText, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(1...5)
                        .disabled(selectedVehicle == nil)

                    Button {
                        sendMessage()
                    } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title)
                            .foregroundStyle(inputText.isEmpty || selectedVehicle == nil ? .gray : .accent)
                    }
                    .disabled(inputText.isEmpty || selectedVehicle == nil || isProcessing)
                }
                .padding()
                .background(Color(.systemGray6))
            }
            .navigationTitle("Manual Assistant")
            .sheet(isPresented: $showingDocumentPicker) {
                DocumentPickerView(manualDocuments: $manualDocuments)
            }
        }
    }

    private func askQuestion(_ question: String) {
        inputText = question
        sendMessage()
    }

    private func sendMessage() {
        guard !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        let userMessage = ChatMessage(content: inputText, isUser: true)
        messages.append(userMessage)

        let query = inputText
        inputText = ""
        isProcessing = true

        // Simulate AI response (In production, this would use Apple Intelligence APIs)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            let response = generateResponse(for: query)
            let aiMessage = ChatMessage(content: response, isUser: false)
            messages.append(aiMessage)
            isProcessing = false
        }
    }

    private func generateResponse(for query: String) -> String {
        // This is a placeholder. In production, you would:
        // 1. Use Apple's Foundation Models to process the query
        // 2. Search through uploaded manual documents
        // 3. Use CoreML for document understanding
        // 4. Generate contextual responses

        let lowercaseQuery = query.lowercased()

        if lowercaseQuery.contains("oil change") || lowercaseQuery.contains("change the oil") {
            return """
            Based on your vehicle manual:

            **Oil Change Procedure:**
            1. Warm up the engine for 2-3 minutes
            2. Locate the oil drain plug underneath the vehicle
            3. Place drain pan under the plug
            4. Remove drain plug and let oil drain completely
            5. Replace drain plug and tighten to spec
            6. Remove old oil filter
            7. Apply fresh oil to new filter gasket
            8. Install new filter hand-tight
            9. Add recommended oil (check manual for capacity)
            10. Run engine and check for leaks

            **Recommended Interval:** Every 5,000-7,500 miles or 6 months

            Note: This is a simulated response. Upload your vehicle's manual for specific instructions.
            """
        } else if lowercaseQuery.contains("tire pressure") {
            return """
            **Recommended Tire Pressure:**

            Most vehicles recommend:
            - Front tires: 32-35 PSI
            - Rear tires: 32-35 PSI

            Check the sticker on the driver's door jamb for your specific vehicle's recommendations.

            **Important:**
            - Check pressure when tires are cold
            - Don't exceed the maximum pressure listed on the tire sidewall
            - Adjust for load if carrying heavy cargo

            Upload your vehicle manual for exact specifications.
            """
        } else if lowercaseQuery.contains("tire rotation") || lowercaseQuery.contains("rotate") {
            return """
            **Tire Rotation Schedule:**

            Recommended every 5,000-7,500 miles or every 6 months.

            **Rotation Pattern (for non-directional tires):**
            - Front-wheel drive: Front to rear, rear cross to front
            - Rear-wheel drive: Rear to front, front cross to rear
            - AWD/4WD: Cross pattern (front left to rear right, etc.)

            **Benefits:**
            - Even tire wear
            - Extended tire life
            - Better handling and traction

            Consult your vehicle manual for the specific rotation pattern.
            """
        } else if lowercaseQuery.contains("brake fluid") {
            return """
            **Brake Fluid Specifications:**

            Most modern vehicles use DOT 3 or DOT 4 brake fluid.

            **Important Notes:**
            - Never mix different types of brake fluid
            - DOT 4 has a higher boiling point than DOT 3
            - Replace brake fluid every 2-3 years
            - Check fluid level monthly

            **Warning:** Using the wrong brake fluid can damage your braking system.

            Check your vehicle's owner manual or the brake fluid reservoir cap for the exact specification.
            """
        } else {
            return """
            I'd be happy to help you with that question! However, I need access to your vehicle's specific manual to provide accurate information.

            **To get better assistance:**
            1. Upload your vehicle's owner manual (PDF)
            2. The AI will analyze the document
            3. Ask your question again for specific answers

            In the meantime, you can:
            - Check your vehicle's documentation
            - Consult with a certified mechanic
            - Visit the manufacturer's website

            Common topics I can help with:
            • Maintenance schedules
            • Fluid specifications
            • Warning light meanings
            • Technical procedures
            • Part numbers and specifications
            """
        }
    }
}

struct ChatMessage: Identifiable {
    let id = UUID()
    let content: String
    let isUser: Bool
    let timestamp = Date()
}

struct MessageBubble: View {
    let message: ChatMessage

    var body: some View {
        HStack {
            if message.isUser {
                Spacer()
            }

            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .padding(12)
                    .background(message.isUser ? Color.accentColor : Color(.systemGray5))
                    .foregroundStyle(message.isUser ? .white : .primary)
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                Text(message.timestamp.formatted(date: .omitted, time: .shortened))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: 300, alignment: message.isUser ? .trailing : .leading)

            if !message.isUser {
                Spacer()
            }
        }
    }
}

struct SuggestedQuestionButton: View {
    let question: String
    let action: (String) -> Void

    var body: some View {
        Button {
            action(question)
        } label: {
            HStack {
                Text(question)
                    .font(.subheadline)
                Spacer()
                Image(systemName: "arrow.right.circle")
            }
            .padding()
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }
}

struct ManualDocument: Identifiable {
    let id = UUID()
    let name: String
    let url: URL
    let addedDate = Date()
}

struct ManualDocumentCard: View {
    let document: ManualDocument

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "doc.fill")
                .font(.title)
                .foregroundStyle(.accent)
            Text(document.name)
                .font(.caption)
                .lineLimit(2)
                .multilineTextAlignment(.center)
        }
        .frame(width: 100, height: 100)
        .padding(8)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct DocumentPickerView: UIViewControllerRepresentable {
    @Binding var manualDocuments: [ManualDocument]
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.pdf], asCopy: true)
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: DocumentPickerView

        init(_ parent: DocumentPickerView) {
            self.parent = parent
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            let document = ManualDocument(name: url.lastPathComponent, url: url)
            parent.manualDocuments.append(document)
            parent.dismiss()
        }
    }
}

#Preview {
    CarManualAssistantView()
        .modelContainer(for: Vehicle.self, inMemory: true)
}
