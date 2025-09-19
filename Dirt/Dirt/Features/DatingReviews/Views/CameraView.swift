import SwiftUI
import AVFoundation
import UIKit

// MARK: - Camera View
struct CameraView: UIViewControllerRepresentable {
    let onImageCaptured: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .camera
        picker.allowsEditing = false
        picker.cameraDevice = .rear
        picker.cameraFlashMode = .auto
        
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {
        // No updates needed
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraView
        
        init(_ parent: CameraView) {
            self.parent = parent
        }
        
        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]
        ) {
            if let image = info[.originalImage] as? UIImage {
                parent.onImageCaptured(image)
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

// MARK: - Camera Permission Helper
class CameraPermissionHelper: ObservableObject {
    @Published var permissionStatus: AVAuthorizationStatus = .notDetermined
    
    init() {
        checkPermission()
    }
    
    func checkPermission() {
        permissionStatus = AVCaptureDevice.authorizationStatus(for: .video)
    }
    
    func requestPermission() async {
        let status = await AVCaptureDevice.requestAccess(for: .video)
        await MainActor.run {
            permissionStatus = AVCaptureDevice.authorizationStatus(for: .video)
        }
    }
    
    var isAuthorized: Bool {
        permissionStatus == .authorized
    }
    
    var isDenied: Bool {
        permissionStatus == .denied || permissionStatus == .restricted
    }
}

// MARK: - Camera Access View
struct CameraAccessView: View {
    @StateObject private var permissionHelper = CameraPermissionHelper()
    let onImageCaptured: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingCamera = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Spacer()
                
                // Camera Icon
                Image(systemName: "camera.fill")
                    .font(.system(size: 64))
                    .foregroundColor(.blue)
                
                // Title and Description
                VStack(spacing: 12) {
                    Text("Camera Access")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Take photos of dating profiles to include in your review. Personal information will be automatically blurred.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                // Permission Status
                Group {
                    switch permissionHelper.permissionStatus {
                    case .notDetermined:
                        Button("Allow Camera Access") {
                            Task {
                                await permissionHelper.requestPermission()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        
                    case .authorized:
                        Button("Open Camera") {
                            showingCamera = true
                        }
                        .buttonStyle(.borderedProminent)
                        
                    case .denied, .restricted:
                        VStack(spacing: 16) {
                            Text("Camera access is required to take photos for your review.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                            
                            Button("Open Settings") {
                                openSettings()
                            }
                            .buttonStyle(.bordered)
                        }
                        
                    @unknown default:
                        EmptyView()
                    }
                }
                
                Spacer()
                
                // Guidelines
                VStack(alignment: .leading, spacing: 8) {
                    Text("Camera Guidelines:")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        GuidelineRow(text: "Take clear, readable screenshots")
                        GuidelineRow(text: "Personal info will be automatically blurred")
                        GuidelineRow(text: "Only capture dating app profiles")
                        GuidelineRow(text: "Respect privacy and consent")
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
            .padding()
            .navigationTitle("Camera")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showingCamera) {
            CameraView(onImageCaptured: onImageCaptured)
        }
        .onAppear {
            permissionHelper.checkPermission()
        }
    }
    
    private func openSettings() {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsUrl)
        }
    }
}

// MARK: - Camera Guideline Row
private struct GuidelineRow: View {
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
                .font(.caption)
                .offset(y: 2)
            
            Text(text)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
        }
    }
}

// MARK: - Preview
struct CameraView_Previews: PreviewProvider {
    static var previews: some View {
        CameraAccessView { _ in }
    }
}