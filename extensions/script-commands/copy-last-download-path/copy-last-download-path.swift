#!/usr/bin/swift

// Required parameters:
// @raycast.schemaVersion 1
// @raycast.title Copy Last Download Path
// @raycast.mode silent
// @raycast.packageName System
//
// Optional parameters:
// @raycast.icon 📋
//
// Documentation:
// @raycast.description Copies the path of the last downloaded file to the clipboard.
// @raycast.author Michael Bianco
// @raycast.authorURL https://github.com/iloveitaly

import AppKit

// MARK: - Main

guard let download = getLatestDownload() else {
  print("No recent downloads")
  exit(1)
}

copyPathToPasteboard(download)
print("Copied \(download.lastPathComponent) path")

// MARK: - Convenience

func getLatestDownload() -> URL? {
  guard let downloadsDirectory = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first else { return nil }
  let inProgressExtensions = ["crdownload", "download", "part"]

  return try? FileManager.default
    .contentsOfDirectory(at: downloadsDirectory, includingPropertiesForKeys: [.addedToDirectoryDateKey], options: .skipsHiddenFiles)
    .filter { !inProgressExtensions.contains($0.pathExtension.lowercased()) }
    .sorted { $0.addedToDirectoryDate > $1.addedToDirectoryDate }
    .first
}

func copyPathToPasteboard(_ url: URL) {
  NSPasteboard.general.clearContents()
  NSPasteboard.general.setString(url.path, forType: .string)
}

extension URL {
  var addedToDirectoryDate: Date {
    return (try? resourceValues(forKeys: [.addedToDirectoryDateKey]).addedToDirectoryDate) ?? .distantPast
  }
}
