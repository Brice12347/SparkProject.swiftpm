import SwiftUI
import PhotosUI

struct HomeworkUploadView: View {
    let student: Student
    @Environment(\.colorScheme) private var colorScheme

    @State private var selectedSubject: Subject?
    @State private var assignmentName: String = ""
    @State private var selectedImage: UIImage?
    @State private var showImagePicker = false
    @State private var showCamera = false
    @State private var showDocumentPicker = false
    @State private var showSourceMenu = false
    @State private var navigateToSession = false

    private var canStartSession: Bool {
        selectedSubject != nil && selectedImage != nil
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: SparkTheme.spacingLG) {
                Text("Upload Assignment")
                    .font(SparkTypography.heading1)
                    .foregroundStyle(SparkTheme.textPrimary(colorScheme))
                    .padding(.top, 8)

                uploadZone

                subjectSelector

                assignmentNameField

                SparkButton(
                    title: "Start Spark Session ✦",
                    style: .primary,
                    isDisabled: !canStartSession
                ) {
                    navigateToSession = true
                }
                .padding(.top, 8)

                Spacer(minLength: 40)
            }
            .padding(.horizontal, SparkTheme.spacingMD)
        }
        .background(SparkTheme.background(colorScheme).ignoresSafeArea())
        .navigationBarHidden(true)
        .confirmationDialog("Upload Assignment", isPresented: $showSourceMenu) {
            Button("Take Photo") { showCamera = true }
            Button("Choose from Photos") { showImagePicker = true }
            Button("Cancel", role: .cancel) { }
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(image: $selectedImage, sourceType: .photoLibrary)
        }
        .fullScreenCover(isPresented: $showCamera) {
            ImagePicker(image: $selectedImage, sourceType: .camera)
                .ignoresSafeArea()
        }
        .fullScreenCover(isPresented: $navigateToSession) {
            if let subject = selectedSubject {
                LiveSessionView(
                    student: student,
                    subject: subject,
                    assignmentName: assignmentName.isEmpty ? nil : assignmentName,
                    assignmentImage: selectedImage
                )
            }
        }
    }

    // MARK: - Upload Zone

    private var uploadZone: some View {
        Button {
            showSourceMenu = true
        } label: {
            Group {
                if let image = selectedImage {
                    ZStack(alignment: .topTrailing) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 260)
                            .clipShape(RoundedRectangle(cornerRadius: SparkTheme.radiusLG, style: .continuous))

                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(SparkTheme.teal)
                            .padding(12)
                    }
                    .frame(maxWidth: .infinity)
                } else {
                    VStack(spacing: 14) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(SparkTheme.teal)

                        Text("Tap to upload or photograph your assignment")
                            .font(SparkTypography.bodyLarge)
                            .foregroundStyle(SparkTheme.gray600)

                        Text("Supports photos, PDFs, and scanned images")
                            .font(SparkTypography.caption)
                            .foregroundStyle(SparkTheme.gray400)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 48)
                }
            }
            .padding(SparkTheme.spacingMD)
            .background(
                RoundedRectangle(cornerRadius: SparkTheme.radiusXL, style: .continuous)
                    .fill(SparkTheme.surface(colorScheme))
            )
            .overlay(
                RoundedRectangle(cornerRadius: SparkTheme.radiusXL, style: .continuous)
                    .strokeBorder(
                        SparkTheme.teal.opacity(selectedImage != nil ? 0.5 : 0.3),
                        style: StrokeStyle(lineWidth: 2, dash: selectedImage != nil ? [] : [8, 6])
                    )
            )
        }
    }

    // MARK: - Subject Selector

    private var subjectSelector: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("What subject is this?")
                .font(SparkTypography.heading3)
                .foregroundStyle(SparkTheme.textPrimary(colorScheme))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(student.subjectPreferences.isEmpty ? Subject.allCases.filter { $0 != .other } : student.subjectPreferences, id: \.self) { subject in
                        subjectChip(subject)
                    }
                }
            }
        }
    }

    private func subjectChip(_ subject: Subject) -> some View {
        let isSelected = selectedSubject == subject
        return Button {
            withAnimation(.spring(response: 0.3)) {
                selectedSubject = subject
            }
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
        } label: {
            HStack(spacing: 6) {
                Text(subject.icon)
                Text(subject.displayName)
                    .font(SparkTypography.bodyMedium)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(isSelected ? SparkTheme.teal : SparkTheme.surfaceSecondary(colorScheme))
            .foregroundStyle(isSelected ? .white : SparkTheme.textPrimary(colorScheme))
            .clipShape(Capsule())
        }
    }

    // MARK: - Assignment Name

    private var assignmentNameField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Assignment name (optional)")
                .font(SparkTypography.caption)
                .foregroundStyle(SparkTheme.textSecondary(colorScheme))

            TextField("e.g. Chapter 5 Worksheet", text: $assignmentName)
                .font(SparkTypography.body)
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: SparkTheme.radiusMD, style: .continuous)
                        .fill(SparkTheme.surfaceSecondary(colorScheme))
                )
        }
    }
}

// MARK: - UIKit Image Picker Bridge

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    var sourceType: UIImagePickerController.SourceType

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        init(_ parent: ImagePicker) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let uiImage = info[.originalImage] as? UIImage {
                parent.image = uiImage
            }
            picker.dismiss(animated: true)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}
