//
//  WebDAVFile.swift
//  WebDAV-Swift
//
//  Created by Isaac Lyons on 11/16/20.
//

import Foundation
import SWXMLHash

public struct WebDAVFile: Identifiable, Codable, Equatable, Hashable {
    
    //MARK: Properties
    
    /// The path of the file.
    public private(set) var path: String
    public private(set) var id: String
    public private(set) var isDirectory: Bool
    public private(set) var lastModified: Date
    public private(set) var size: Int
    public private(set) var etag: String
    
    public init(path: String, id: String, isDirectory: Bool, lastModified: Date, size: Int, etag: String) {
        self.path = path
        self.id = id
        self.isDirectory = isDirectory
        self.lastModified = lastModified
        self.size = size
        self.etag = etag
    }
    
    init?(xml: XMLIndexer, baseURL: String?) {
        let properties = xml["propstat"][0]["prop"]
        guard var path = xml["href"].element?.text,
              let dateString = properties["getlastmodified"].element?.text,
              let date = WebDAVFile.rfc1123Formatter.date(from: dateString) else { return nil }
        
            // 通过 resourcetype 判断是否为目录
        let isDirectory = properties["resourcetype"]["collection"].element != nil
        
            // 目录可能没有 getcontentlength，默认为 0
        let sizeString = properties["getcontentlength"].element?.text
        let size = isDirectory ? 0 : (Int(sizeString ?? "") ?? 0)
        
            // fileid 和 etag 可选
        let id = properties["fileid"].element?.text
        let etag = properties["getetag"].element?.text
        
        if let decodedPath = path.removingPercentEncoding {
            path = decodedPath
        }
        
        if let baseURL = baseURL {
            path = WebDAVFile.removing(endOf: baseURL, from: path)
        }
        
        if path.first == "/" {
            path.removeFirst()
        }
        
        self.init(path: path, id: id ?? "", isDirectory: isDirectory, lastModified: date, size: size, etag: etag ?? "")
    }
    
    //MARK: Static
    
    static let rfc1123Formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss z"
        return formatter
    }()
    
    private static func removing(endOf string1: String, from string2: String) -> String {
        guard let first = string2.first else { return string2 }
        
        for (i, c) in string1.enumerated() {
            guard c == first else { continue }
            let end = string1.dropFirst(i)
            if string2.hasPrefix(end) {
                return String(string2.dropFirst(end.count))
            }
        }
        
        return string2
    }
    
    //MARK: Public
    
    public var description: String {
        "WebDAVFile(path: \(path), id: \(id), isDirectory: \(isDirectory), lastModified: \(WebDAVFile.rfc1123Formatter.string(from: lastModified)), size: \(size), etag: \(etag))"
    }
    
    public var fileURL: URL {
        URL(fileURLWithPath: path)
    }
    
    /// The file name including extension.
    public var fileName: String {
        return fileURL.lastPathComponent
    }
    
    /// The file extension.
    public var `extension`: String {
        fileURL.pathExtension
    }
    
    /// The name of the file without its extension.
    public var name: String {
        isDirectory ? fileName : fileURL.deletingPathExtension().lastPathComponent
    }
    
}
