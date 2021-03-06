//
//  xTextMatcher.swift
//  xTextHandler
//
//  Created by cyan on 16/7/4.
//  Copyright © 2016年 cyan. All rights reserved.
//

import XcodeKit
import AppKit

/// Text match result struct
struct xTextMatchResult {
    
    var text: String        // full text
    var range: NSRange      // replace range
    var clipboard: Bool     // is clipboard text or not
    
    
    /// Result from text & clipped text
    ///
    /// - parameter aText:   full text
    /// - parameter clipped: clipped text
    ///
    /// - returns: xTextMatchResult
    init(aText: String, clipped: String) {
        text = aText
        range = (aText as NSString).range(of: clipped)
        clipboard = false
    }
    
    
    /// Result from clipboard text
    ///
    /// - returns: xTextMatchResult
    static func clipboardResult() -> xTextMatchResult {
        let text = NSPasteboard.general().string(forType: NSPasteboardTypeString) ?? ""
        var result = xTextMatchResult(aText: text, clipped: text)
        result.clipboard = true
        return result
    }
}


/// Match selected lines
class xTextMatcher {
    
    typealias xTextSelectionLineHandler = (Int, String, String) -> ()
    
    static let xTextInvalidLine = -1 // stand for invalid index
    
    /// Enumerate lines in XCSourceEditorCommandInvocation
    ///
    /// - parameter invocation:  XCSourceEditorCommandInvocation
    /// - parameter selection:   XCSourceTextRange
    /// - parameter lineHandler: (index, line, clipped)
    static func enumerate(invocation: XCSourceEditorCommandInvocation, selection: XCSourceTextRange, lineHandler: xTextSelectionLineHandler) {
        
        let startLine = selection.start.line
        let startColumn = selection.start.column
        let endLine = selection.end.line
        let endColumn = selection.end.column
        
        // handle clipboard if selected nothing
        if startLine == endLine && startColumn == endColumn {
            lineHandler(xTextInvalidLine, "", "")
            return
        }
        
        // enumerate lines
        for index in startLine...endLine {
            
            let line = invocation.buffer.lines[index]
            var clipped: String
            
            if startLine == endLine { // single line
                clipped = line.substring(with: NSMakeRange(startColumn, endColumn - startColumn + 1))
            } else if index == startLine { // first line
                clipped = line.substring(from: startColumn)
            } else if index == endLine { // last line
                clipped = line.substring(to: endColumn + 1)
            } else { // common line
                clipped = line as! String
            }
            
            if clipped.characters.count > 0 {
                lineHandler(index, line as! String, clipped)
            }
        }
    }
    
    /// Match texts in XCSourceEditorCommandInvocation
    ///
    /// - parameter selection:  XCSourceTextRange
    /// - parameter invocation: XCSourceEditorCommandInvocation
    ///
    /// - returns: match result
    static func match(selection: XCSourceTextRange, invocation: XCSourceEditorCommandInvocation) -> xTextMatchResult {
        
        var lineText = ""
        var clippedText = ""
        var clipboard = false
        
        // enumerate each lines
        self.enumerate(invocation: invocation, selection: selection) { (index, line, clipped) in
            lineText.append(line)
            clippedText.append(clipped)
            clipboard = (index == xTextInvalidLine)
        }
        
        // clipboard result or selected result
        return clipboard ? xTextMatchResult.clipboardResult() : xTextMatchResult(aText: lineText, clipped: clippedText)
    }
}
