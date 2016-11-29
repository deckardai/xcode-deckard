//
//  SourceEditorCommand.swift
//  Deckard Plugin
//
//  Created by deckard.ai on 15/10/16.
//  Copyright © 2016 deckard.ai. All rights reserved.
//
import Foundation
import XcodeKit
import Cocoa

func bytes2String(array:[UInt8]) -> String {
    return String(data: NSData(bytes: array, length: array.count) as Data, encoding: String.Encoding.utf8) ?? ""
}

class SourceEditorCommand: NSObject, XCSourceEditorCommand {

    func perform(with invocation: XCSourceEditorCommandInvocation, completionHandler: @escaping (Error?) -> Void ) -> Void {
        
        //let completeBuffer = invocation.buffer.completeBuffer
        //print("COMPLETE: ", completeBuffer)
        
        let titleLine = invocation.buffer.lines[1] as! String
        var title = titleLine.substring(from: titleLine.index(titleLine.startIndex, offsetBy: 4))
        title = title.replacingOccurrences(of: "\\n", with: "", options: .regularExpression)
        //print("LINE: ", title)
        
        let buffer = invocation.buffer
        var currentLine = 0
        var currentCol = 0
        if let insertionPoint = buffer.selections[0] as? XCSourceTextRange {
            currentLine = insertionPoint.start.line
            currentCol = insertionPoint.start.column
        }
        
        let fileManager = FileManager.default
        
        if #available(OSXApplicationExtension 10.12, *) {
            let path = fileManager.homeDirectoryForCurrentUser

            print("PATH", path)
        } else {
            // Fallback on earlier versions
        }
        
        let event: [String: Any] = ["path": "/Users/fenek/Documents/xcode-deckard/Deckard Plugin/" + title, "lineno": currentLine, "charno": currentCol,"text":"sometext", "editor": "xcode"]
        
        var postString = ""
        var jsonData = Data()
        
        do {
            //jsonData = try JSONSerialization.data(withJSONObject: event, options: .prettyPrinted)
            jsonData = try JSONSerialization.data(withJSONObject: event)
            postString = jsonData.base64EncodedString()
            
            let decodedData = NSData(base64Encoded: postString)
            let decodedString = NSString(data: decodedData as! Data, encoding: String.Encoding.utf8.rawValue)
            
            print("DEBUG: DATA:", decodedString)
            
        } catch {
            print(error.localizedDescription)
        }
        
        var request = URLRequest(url: URL(string: "http://127.0.0.1:3325/event")!)
        request.httpMethod = "POST"
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")  
        //request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Accept")
        
        //request.httpBody = postString.data(using: .utf8)
        request.httpBody = jsonData
        
        print("DEBUG: REQUEST BODY:", String(describing: request.httpBody))
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print("erwror=\(error)")
                return
            }

            print("Response: \(response)")
            let responseString = String(data: data, encoding: .utf8)
            print("responseString = \(responseString)")
        }
        task.resume()
        
        completionHandler(nil)
    }
}
