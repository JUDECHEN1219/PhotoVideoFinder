import Foundation
import SwiftData

@Model
class ThumbnailCache {
    var videoPath: String
    var thumbnailData: Data  // 存储缩略图原始数据

    init(videoPath: String, thumbnailData: Data) {
        self.videoPath = videoPath
        self.thumbnailData = thumbnailData
    }
}
