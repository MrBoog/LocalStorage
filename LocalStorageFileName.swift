import Foundation

enum LocalStorageName: String {
    case categories = "categories"             
}

struct LocalStorageFileName {
    
    var name: String {
        get {
            if let appending = appendingName {
                return baseName.rawValue + appending
            }
            return baseName.rawValue
        }
    }
    
    private var baseName: LocalStorageName
    private var appendingName: String?
  
    init(name: LocalStorageName) {
        baseName = name
    }
    
    init(name: LocalStorageName, appending: String) {
        appendingName = appending
        baseName = name
    }
}

