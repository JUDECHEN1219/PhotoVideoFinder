// ContentView

import SwiftUI
import UniformTypeIdentifiers
import SwiftData

struct ContentView: View {
    @State private var rootFolders: [URL] = []
    @State private var selectedFolder: URL?
    @State private var currentFolder: URL?
    @State private var isImporterPresented = false
    
    @Environment(\.modelContext) private var modelContext
    
    private func clearAllThumbnailCache() {
        let descriptor = FetchDescriptor<ThumbnailCache>()  // 获取所有记录
        do {
            let records = try modelContext.fetch(descriptor)
            for record in records {
                modelContext.delete(record)
            }
            try modelContext.save()
            print("🗑 所有缩略图缓存已清空")
        } catch {
            print("❌ 清空缓存失败：\(error)")
        }
    }

    var body: some View {
        NavigationSplitView {
            // 左侧边栏
            List(selection: $selectedFolder) {
                Section(header: Text("📁 导入的文件夹")) {
                    ForEach(rootFolders, id: \.self) { folder in
                        Label(folder.lastPathComponent, systemImage: "folder")
                            .tag(folder as URL?)
                    }
                }
            }
            .navigationTitle("文件夹")
            .onChange(of: selectedFolder) {
                if let selected = selectedFolder {
                    currentFolder = selected
                }
            }

        } detail: {
            VStack {
                if let folder = currentFolder {
                    FolderView(folderURL: folder) { tappedSubfolder in
                        currentFolder = tappedSubfolder
                    }
                    .id(folder)
                    .navigationTitle(folder.lastPathComponent)
                } else {
                    Text("请选择左侧文件夹")
                        .foregroundColor(.secondary)
                        .navigationTitle("NewVideo")
                }
            }
            .toolbar {
                // ⬅️ 返回按钮靠左
                ToolbarItem(placement: .navigation) {
                    if currentFolder != selectedFolder, let folder = currentFolder {
                        Button {
                            currentFolder = folder.deletingLastPathComponent()
                        } label: {
                            Label("返回", systemImage: "chevron.left")
                        }
                    }
                }
                
                // delete cache
                ToolbarItem {
                    Button(role: .destructive) {
                        clearAllThumbnailCache()
                        print("🗑 缓存清空完成")
                    } label: {
                        Label("清空缓存", systemImage: "eraser")
                    }
                }
                
                // refresh and reload folder
                ToolbarItem {
                    Button {
                        if let folder = currentFolder {
                            // 手动刷新当前页面
                            // 通过 id 刷新 FolderView
                            currentFolder = nil
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                                currentFolder = folder
                            }
                        }
                    } label: {
                        Label("刷新", systemImage: "arrow.clockwise")
                    }
                }
                
                // ➕ 添加按钮默认靠右
                ToolbarItem {
                    Button {
                        isImporterPresented = true
                    } label: {
                        Label("添加文件夹", systemImage: "folder.badge.plus")
                    }
                }
            }
        }
        .fileImporter(
            isPresented: $isImporterPresented,
            allowedContentTypes: [.folder],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let folder = urls.first {
                    if folder.startAccessingSecurityScopedResource() {
                        print("✅ 成功访问：\(folder.path)")
                        if !rootFolders.contains(folder) {
                            rootFolders.append(folder)
                        }
                    } else {
                        print("❌ 无法访问：\(folder.path)")
                    }
                }
            case .failure(let error):
                print("导入失败：\(error.localizedDescription)")
            }
        }
    }
}
