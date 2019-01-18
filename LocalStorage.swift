import UIKit

/**
 *  Usage:
 *  Store up struct or object which is <Codable>
 *  Support <Application>/Library/Caches(By default) and <Application>/Documents directory
 *  Use LocalStorageFileName to specify file name
 */
final class LocalStorage {
    
    private let workQueue: OperationQueue = {
        let result = OperationQueue.init()
        result.maxConcurrentOperationCount = 1
        result.isSuspended = false
        return result
    }()
    
    enum Directory {
        case documents
        case caches
    }
    
    // custom folder
    private struct FolderName {
        static let cache = "com.news.cache"
        static let document = "com.news.document"
    }
    
    static private func sandboxFolderPath(for directory: Directory) -> String {
        var pathDirectory: FileManager.SearchPathDirectory
        switch directory {
        case .documents:
            pathDirectory = .documentDirectory
        case .caches:
            pathDirectory = .cachesDirectory
        }
        return NSSearchPathForDirectoriesInDomains(pathDirectory, .userDomainMask, true)[0]
    }
    
    // custom folder path of cachesDirectory
    static private func cacheFolderPath() -> URL {
        let basePath = sandboxFolderPath(for: Directory.caches)
        return URL(fileURLWithPath: basePath).appendingPathComponent(FolderName.cache, isDirectory: true)
    }
    
    // custom folder path of documentDirectory
    static private func documentFolderPath() -> URL {
        let basePath = sandboxFolderPath(for: Directory.documents)
        return URL(fileURLWithPath: basePath).appendingPathComponent(FolderName.document, isDirectory: true)
    }
    
    // return entire path of a specific file
    static private func filePath(ofFolder folder: Directory, fileName: LocalStorageFileName) -> URL {
        switch folder {
        case .documents:
            return self.documentFolderPath().appendingPathComponent(fileName.name, isDirectory: false)
        case .caches:
            return self.cacheFolderPath().appendingPathComponent(fileName.name, isDirectory: false)
        }
    }
    
    static func isFileExists(ofFolder folder: Directory = .caches, fileName: LocalStorageFileName) -> Bool {
        let url = filePath(ofFolder: folder, fileName: fileName)
        return FileManager.default.fileExists(atPath: url.path)
    }
}

extension LocalStorage {
    
    // NOTE: will overwrite the current file if it exists already
    func store<T: Codable>(toFolder folder: Directory = .caches, object: T, named fileName: LocalStorageFileName) {
        workQueue.addOperation {
            do {
                if folder == .caches {
                    try FileManager.default.createDirectory(at: LocalStorage.cacheFolderPath(), withIntermediateDirectories: true, attributes: nil)
                } else if folder == .documents {
                    try FileManager.default.createDirectory(at: LocalStorage.documentFolderPath(), withIntermediateDirectories: true, attributes: nil)
                }
                let url = LocalStorage.filePath(ofFolder: folder, fileName: fileName)
                let data = try JSONEncoder().encode(object)
                var success = false
                if !FileManager.default.fileExists(atPath: url.path) {
                    success = FileManager.default.createFile(atPath: url.path, contents: nil, attributes: nil)
                    newsPrint("create folder \(success)")
                }
                try data.write(to: url)
                newsPrint("write file success")
            } catch {
                newsPrint("create folder failed \(error)")
            }
        }
    }
    
    func restore<T: Codable>(ofFolder folder: Directory = .caches, fileName: LocalStorageFileName, as type: T.Type, asyn: Bool = true, result: @escaping (T?)->Void ) -> Void {
        let url = LocalStorage.filePath(ofFolder: folder, fileName: fileName)
        guard FileManager.default.fileExists(atPath: url.path) else {
            return result(nil)
        }
        if asyn {
            workQueue.addOperation {
                if let data = FileManager.default.contents(atPath: url.path),
                    let obj = try? JSONDecoder().decode(type, from: data) {
                    DispatchQueue.main.sync {
                        return result(obj)
                    }
                } else {
                    DispatchQueue.main.sync {
                        return result(nil)
                    }
                }
            }
        } else {
            if let data = FileManager.default.contents(atPath: url.path),
                let obj = try? JSONDecoder().decode(type, from: data) {
                return result(obj)
            } else {
                return result(nil)
            }
        }
    }
    
    func remove(fromFolder folder: Directory = .caches, fileName: LocalStorageFileName) {
        workQueue.addOperation {
            let url = LocalStorage.filePath(ofFolder: folder, fileName: fileName)
            if FileManager.default.fileExists(atPath: url.path) {
                do {
                    try FileManager.default.removeItem(at: url)
                } catch {
                }
            }
        }
    }
}

