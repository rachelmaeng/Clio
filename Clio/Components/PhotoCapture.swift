import SwiftUI
import PhotosUI

struct PhotoCapture: View {
    @Binding var selectedImageData: Data?
    @State private var selectedItem: PhotosPickerItem?
    @State private var showCamera = false

    var body: some View {
        VStack(spacing: 16) {
            if let imageData = selectedImageData, let uiImage = UIImage(data: imageData) {
                // Photo preview
                ZStack(alignment: .topTrailing) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 16))

                    // Delete button
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            selectedImageData = nil
                            selectedItem = nil
                        }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.white)
                            .shadow(radius: 4)
                    }
                    .padding(12)

                    // AI Analysis badge (stubbed)
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            AIAnalysisBadge()
                        }
                    }
                    .padding(12)
                }
            } else {
                // Photo capture options
                HStack(spacing: 12) {
                    PhotosPicker(selection: $selectedItem, matching: .images) {
                        PhotoCaptureButton(
                            icon: "photo.on.rectangle",
                            title: "Gallery",
                            color: ClioTheme.eatColor
                        )
                    }
                    .buttonStyle(.plain)

                    Button {
                        showCamera = true
                    } label: {
                        PhotoCaptureButton(
                            icon: "camera.fill",
                            title: "Camera",
                            color: ClioTheme.eatColor
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .onChange(of: selectedItem) { _, newValue in
            Task {
                if let data = try? await newValue?.loadTransferable(type: Data.self) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        selectedImageData = data
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraView(imageData: $selectedImageData)
        }
    }
}

struct PhotoCaptureButton: View {
    let icon: String
    let title: String
    let color: Color

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)

            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(ClioTheme.text)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(ClioTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
    }
}

struct AIAnalysisBadge: View {
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "sparkles")
                .font(.caption)
            Text("AI Coming Soon")
                .font(.caption2)
                .fontWeight(.medium)
        }
        .foregroundStyle(ClioTheme.textMuted)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
    }
}

// Simple camera view using UIImagePickerController
struct CameraView: UIViewControllerRepresentable {
    @Binding var imageData: Data?
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraView

        init(_ parent: CameraView) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.imageData = image.jpegData(compressionQuality: 0.8)
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

#Preview {
    ZStack {
        ClioTheme.background
            .ignoresSafeArea()

        PhotoCapture(selectedImageData: .constant(nil))
            .padding()
    }
}
