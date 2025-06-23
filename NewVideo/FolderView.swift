
// FolderView

import SwiftUI
import AVFoundation
import AppKit
import SwiftData


let imageThumbnailQueue: OperationQueue = {
    let queue = OperationQueue()
    queue.name = "com.yourapp.imageThumbnailQueue"
    queue.maxConcurrentOperationCount = 2
    return queue
}()

let videoThumbnailQueue: OperationQueue = {
    let queue = OperationQueue()
    queue.name = "com.yourapp.videoThumbnailQueue"
    queue.maxConcurrentOperationCount = 2  // 同时最多处理两个视频缩略图
    return queue
}()

struct FolderView: View {
    let folderURL: URL
    let onFolderTapped: (URL) -> Void
    @State private var items: [FileItem] = []
    @State private var thumbnails: [URL: NSImage] = [:]
    @State private var thumbnailScale: CGFloat = 1.0
    @State private var hoveredItem: URL? = nil
    @State private var lastMagnification: CGFloat = 1.0

    @Environment(\.modelContext) private var modelContext

    var body: some View {
        VStack(spacing: 0) {
            buildFilesView()
            Divider()
            buildStatusView()
        }
    }

    private func fetchThumbnail(for path: String) -> ThumbnailCache? {
        let descriptor = FetchDescriptor<ThumbnailCache>(
            predicate: #Predicate { $0.videoPath == path }
        )
        return try? modelContext.fetch(descriptor).first
    }
    
    @ViewBuilder
    private func buildStatusView() -> some View {
        // ⬇️ 底部状态栏
        HStack {
            Label("文件：\(folderItems.count)", systemImage: "folder")
            Text("|").foregroundColor(.secondary)
            Label("影片：\(videoItems.count)", systemImage: "film")
            Text("|").foregroundColor(.secondary)
            Label("图片：\(imageItems.count)", systemImage: "photo")

            Spacer()

            Image(systemName: "minus.magnifyingglass")
            Slider(value: $thumbnailScale, in: 0.25...5.0) // 平滑滑动
                    .frame(width: 160)
            Image(systemName: "plus.magnifyingglass")
            
            Text(String(format: "%.2f×", thumbnailScale))
                    .font(.caption.monospaced() )
                    .foregroundColor(.secondary)
        }
        .padding(EdgeInsets(top: 4, leading: 12, bottom: 8, trailing: 12))
        .background(Material.bar)  // macOS 原生风格
    }
    
    @ViewBuilder
    private func buildVideoGrid() -> some View {
        let originalImageSize: CGFloat = 3
        LazyVGrid(
            columns: [
                GridItem(.adaptive(minimum: 120 * originalImageSize * thumbnailScale), spacing: 8)
            ],
            spacing: 16  // 垂直方向的行间距
        ) {
            ForEach(videoItems) { item in
                VStack {
                    if let image = thumbnails[item.url] {
                        Image(nsImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 120 * originalImageSize * thumbnailScale)
                            .cornerRadius(10)
                            .shadow(radius: 1)
                    } else {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(/*width: 128 * originalImageSize * thumbnailScale, */height: 72 * originalImageSize * thumbnailScale)
                            .overlay(ProgressView())
                    }
                    Text(item.name)
                        .font(.caption)
                        .lineLimit(2)
                        .truncationMode(.middle)
                }
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(hoveredItem == item.url ? Color.accentColor.opacity(0.12) : Color.clear)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(hoveredItem == item.url ? Color.accentColor.opacity(0.4) : Color.clear, lineWidth: 1)
                )
                .onHover { hovering in
                    hoveredItem = hovering ? item.url : nil
                }
                .onTapGesture {
                    NSWorkspace.shared.open(item.url)
                }
            }
        }
        
    }
    
    @ViewBuilder
    private func buildPhotoGrid() -> some View {
        let originalImageSize: CGFloat = 3

        LazyVGrid(
            columns: [
                GridItem(.adaptive(minimum: 120 * originalImageSize * thumbnailScale), spacing: 8)
            ],
            spacing: 16
        ) {
            ForEach(imageItems) { item in
                VStack {
                    if let image = thumbnails[item.url] {
                        Image(nsImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 120 * originalImageSize * thumbnailScale)
                            .cornerRadius(10)
                            .shadow(radius: 1)
                    } else {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 72 * originalImageSize * thumbnailScale)
                            .overlay(ProgressView())
                    }
                    Text(item.name)
                        .font(.caption)
                        .lineLimit(2)
                        .truncationMode(.middle)
                }
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(hoveredItem == item.url ? Color.accentColor.opacity(0.12) : Color.clear)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(hoveredItem == item.url ? Color.accentColor.opacity(0.4) : Color.clear, lineWidth: 1)
                )
                .onHover { hovering in
                    hoveredItem = hovering ? item.url : nil
                }
                .onTapGesture {
                    NSWorkspace.shared.open(item.url)
                }
            }
        }
    }

    @ViewBuilder
    private func buildFolderGrid() -> some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 110 ))], spacing: 0) {
            ForEach(folderItems) { item in
                VStack(spacing: 1) {
                    Image(nsImage: NSWorkspace.shared.icon(forFile: item.url.path))
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 80)
                        .padding(.bottom, -5)
                    Text(item.name)
                        .font(.caption)
                        .lineLimit(2)
                        .truncationMode(.middle)
                }
                .padding(4)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(hoveredItem == item.url ? Color.accentColor.opacity(0.12) : Color.clear)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(hoveredItem == item.url ? Color.accentColor.opacity(0.4) : Color.clear, lineWidth: 1)
                )
                .onHover { hovering in
                    hoveredItem = hovering ? item.url : nil
                }
                .onTapGesture {
                    onFolderTapped(item.url)
                }
            }
        }
    }
    
    @ViewBuilder
    private func buildFilesView() -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // 视频部分
                if !videoItems.isEmpty {
                    Text("🎞 影片区 (ヾ(≧▽≦*)o")
                        .font(.headline)
                        .padding(.horizontal)
                    buildVideoGrid()
                    Divider().background(Color.white)
                }
                
                // 视频部分
                if !imageItems.isEmpty {
                    Text("🖼️ 图片区 (*≧▽≦)")
                        .font(.headline)
                        .padding(.horizontal)
                    buildPhotoGrid()
                    Divider().background(Color.white)
                }

                // 文件夹部分
                if !folderItems.isEmpty {
                    Text("📁 子文件夹")
                        .font(.headline)
                        .padding(.horizontal)
                    buildFolderGrid()
                }
            }
            .padding()
        }
        .onAppear {
            loadContents()
        }
        .onChange(of: folderURL) {
            // 1. 取消所有正在生成的图片缩略图任务
            imageThumbnailQueue.cancelAllOperations()
            
            // 2. 清空缩略图缓存（防止旧图片显示）
            thumbnails.removeAll()

            // 3. 加载新目录内容
            loadContents()
        
        }
        .toolbar {
            
            ToolbarItemGroup(placement: .status) {
                Button {
                    if thumbnailScale > 0.25 {
                        thumbnailScale -= 0.25
                    }
                } label: {
                    Image(systemName: "minus.magnifyingglass")
                }
                
                Button {
                    if thumbnailScale < 5.0 {
                        thumbnailScale += 0.25
                    }
                } label: {
                    Image(systemName: "plus.magnifyingglass")
                }
            }
        }
        .simultaneousGesture(
            MagnificationGesture()
                .onChanged { scale in
                    let delta = (scale - lastMagnification) * 0.8  // 灵敏度可以调成 0.3~0.5
                    let newScale = thumbnailScale + delta

                    thumbnailScale = min(5.0, max(0.25, newScale))  // 限制缩放范围
                    lastMagnification = scale  // 记录这次手势值
                }
                .onEnded { _ in
                    lastMagnification = 1.0  // 手势结束后重置
                }
        )
    }

    private func refreshFolder() {
        imageThumbnailQueue.cancelAllOperations()
        thumbnails.removeAll()
        loadContents()
    }
    
    private var videoItems: [FileItem] {
        let videoExtensions: Set<String> = ["mp4", "mov", "mkv", "avi", "flv", "wmv", "m4v"]
        return items.filter {
            !$0.isDirectory && videoExtensions.contains($0.url.pathExtension.lowercased())
        }
    }

    private var imageItems: [FileItem] {
        let imageExtensions: Set<String> = ["jpg", "jpeg", "png", "gif", "bmp", "tiff", "webp"]
        return items.filter {
            !$0.isDirectory &&
            imageExtensions.contains($0.url.pathExtension.lowercased())
        }
    }
    
    private var folderItems: [FileItem] {
        items.filter { $0.isDirectory }
    }

    private func loadContents() {
        let fm = FileManager.default
        let videoExtensions: Set<String> = ["mp4", "mov", "mkv", "avi", "flv", "wmv", "m4v"]
        let imageExtensions: Set<String> = ["jpg", "jpeg", "png", "bmp", "gif", "tiff", "heic"]

        guard let urls = try? fm.contentsOfDirectory(
            at: folderURL,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else {
            items = []
            return
        }

        items = urls.compactMap { url in
            guard let isDir = try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory else { return nil }
            let ext = url.pathExtension.lowercased()
            return (isDir || videoExtensions.contains(ext) || imageExtensions.contains(ext)) ?
                FileItem(name: url.lastPathComponent, url: url, isDirectory: isDir) : nil
        }

        for item in items where !item.isDirectory {
            let ext = item.url.pathExtension.lowercased()
            if videoExtensions.contains(ext) {
                generateVideoThumbnail(for: item.url)
            } else if imageExtensions.contains(ext) {
                generateImageThumbnail(for: item.url)
            }
        }
    }
    
    private func generateVideoThumbnail(for url: URL) {
        let videoPath = url.standardized.path

        if let record = fetchThumbnail(for: videoPath),
           let image = NSImage(data: record.thumbnailData) {
            thumbnails[url] = image
            return
        }

        // 使用限制并发的缩略图任务队列
        videoThumbnailQueue.addOperation {
            autoreleasepool {
                let tempDir = FileManager.default.temporaryDirectory
                let outputPath = tempDir.appendingPathComponent(UUID().uuidString + ".jpg")

                guard let ffmpegPath = Bundle.main.path(forResource: "ffmpeg", ofType: nil) else {
                    print("❌ 无法找到 ffmpeg 可执行文件")
                    return
                }

                // 确保 ffmpeg 可执行权限
                let _ = try? FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: ffmpegPath)
                print("📍 使用打包 ffmpeg: \(ffmpegPath)")

                let process = Process()
                process.executableURL = URL(fileURLWithPath: ffmpegPath)
                process.arguments = [
                    "-ss", "00:00:01.000",
                    "-i", url.path,
                    "-frames:v", "1",
                    "-q:v", "2",
                    "-update", "1",
                    "-y", outputPath.path
                ]

                do {
                    try process.run()
                    process.waitUntilExit()

                    if process.terminationStatus == 0,
                       let imageData = try? Data(contentsOf: outputPath),
                       let image = NSImage(data: imageData) {

                        DispatchQueue.main.async {
                            thumbnails[url] = image

                            let record = ThumbnailCache(videoPath: videoPath, thumbnailData: imageData)
                            modelContext.insert(record)

                            do {
                                try modelContext.save()
                            } catch {
                                print("❌ 缓存写入失败：\(error)")
                            }
                        }
                    } else {
                        print("❌ ffmpeg 生成失败: \(url.lastPathComponent)")
                    }

                    try? FileManager.default.removeItem(at: outputPath)
                } catch {
                    print("❌ ffmpeg 执行错误: \(error.localizedDescription)")
                }
            }
        }
    }
    
    
    private func generateImageThumbnail(for url: URL) {
        let imagePath = url.standardized.path

        if let record = fetchThumbnail(for: imagePath), let image = NSImage(data: record.thumbnailData) {
            thumbnails[url] = image
            return
        }

        imageThumbnailQueue.addOperation {
            autoreleasepool {
                guard var image = NSImage(contentsOf: url) else { return }
                let maxWidth: CGFloat = 240
                let originalSize = image.size
                let aspectRatio = originalSize.height / originalSize.width
                let targetSize = NSSize(width: min(originalSize.width, maxWidth), height: min(originalSize.width, maxWidth) * aspectRatio)

                let thumbnail = NSImage(size: targetSize)
                thumbnail.lockFocus()
                image.draw(in: NSRect(origin: .zero, size: targetSize), from: NSRect(origin: .zero, size: originalSize), operation: .copy, fraction: 1.0)
                thumbnail.unlockFocus()
                image = NSImage()

                DispatchQueue.main.async {
                    thumbnails[url] = thumbnail
                    if let imageData = thumbnail.tiffRepresentation {
                        let record = ThumbnailCache(videoPath: imagePath, thumbnailData: imageData)
                        modelContext.insert(record)
                        try? modelContext.save()
                    }
                }
            }
        }
    }
    
}
