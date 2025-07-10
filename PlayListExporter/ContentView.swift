import SwiftUI
import MediaPlayer

/// アプリコンテンツ表示
struct ContentView: View {
    /// プレイリスト配列
    @State private var playlists: [MPMediaPlaylist]?
    /// エクスポートするファイル
    @State private var files: [URL]?

    /// プレイリストを読み込む
    private func load() {
        let mediaQuery = MPMediaQuery.playlists()
        guard let playlists = mediaQuery.collections as? [MPMediaPlaylist] else {
            return
        }
        self.playlists = playlists

        var files: [URL] = []
        let fileManager = FileManager.default
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        playlists.forEach { playlist in
            let file = documentsDirectory.appendingPathComponent("\(playlist.name ?? "-").txt")
            let content = export(playlist: playlist)

            do {
                try content.write(to: file, atomically: true, encoding: .utf8)
                files.append(file)
            } catch {
                print("エラー: \(error)")
            }
        }
        self.files = files
    }

    /// プレイリストをテキスト形式に変換する
    /// - Parameter playlist: プレイリスト
    private func export(playlist: MPMediaPlaylist) -> String {
        // プレイリスト内のアイテム情報を取得する
        let query = MPMediaQuery.songs()
        query.addFilterPredicate(MPMediaPropertyPredicate(value: playlist.persistentID, forProperty: MPMediaPlaylistPropertyPersistentID))
        let items = query.items

        var data: [String] = ["名前\tアーティスト\tアルバム"]
        for item in items! {
            data.append("\(item.title ?? "")\t\(item.artist ?? "")\t\(item.albumTitle ?? "")")
        }
        return data.joined(separator: "\n")
    }

    var body: some View {
        List {
            if playlists == nil {
                Button("プレイリスト読み込み") {
                    load()
                }
            }
            Section("All") {
                if let files {
                    ShareLink(items: files) {
                        Text("全件エクスポート")
                    }
                }
            }
            Section("Playlists") {
                if let playlists {
                    ForEach(playlists, id: \.persistentID) { playlist in
                        ShareLink(item: export(playlist: playlist)) {
                            Text("\(playlist.name ?? "")")
                        }
                    }
                }
            }
        }
        .onAppear(perform: load)
    }
}

#Preview {
    ContentView()
}
