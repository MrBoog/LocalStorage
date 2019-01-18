#!/usr/bin/swift

import Foundation

func backup() {
    let args = CommandLine.arguments
    guard args.count > 1 else {
        return print("Backup Failed! : \n    Detail: Missing commit message whick should be surrounded by quotation mark.")
    }
    let arg = args[1]
    shell("git", "status")
    shell("git", "pull")
    shell("git", "add", ".")
    shell("git", "commit", "-am", arg)
    shell("git", "push", "origin", "HEAD:master")
}

@discardableResult
func shell(_ args: String...) -> (String?, Int32) {
    let task = Process()
    task.launchPath = "/usr/bin/env"
    task.arguments = args
    task.launch()
    task.waitUntilExit()
    return (nil, task.terminationStatus)
    
//    let pipe = Pipe()
//    task.standardOutput = pipe
//    task.standardError = pipe
//    let data = pipe.fileHandleForReading.readDataToEndOfFile()
//    let output = String(data: data, encoding: .utf8)
//    return (output, task.terminationStatus)
}

backup()
