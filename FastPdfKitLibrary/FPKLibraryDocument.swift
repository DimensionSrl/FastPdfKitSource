//
//  FPKLibraryDocument.swift
//  FastPdfKitLibrary
//
//  Created by Nicolo' on 01/06/15.
//
//

import UIKit

/**
    Statuses for the document.

    - Available: the file is accessible at the url.
    - Unavailable: the file is not available.
    - Processing: the file is not currently available but will be shortly.
*/
enum FPKLibraryDocumentStatus {
    case available, unavailable, processing
}

class FPKLibraryDocument: NSObject {
    
    /// Location of the PDF file.
    var url : URL?
    
    /// Title of the document.
    var title : String
    
    /// Location of the thumbnail image.
    var thumbnail : URL?
    
    /// Unique identifier for the document.
    var identifier : String
    
    init(identifier: String, url : URL?, title: String, thumbnail: URL?) {
        self.url = url
        self.title = title
        self.thumbnail = thumbnail
        self.identifier = identifier
    }
    
    /// Wether the document can be deleted or not.
    var locked : Bool = true
    
    /// Status of the document.
    var status : FPKLibraryDocumentStatus = .unavailable
}

class FPKLibraryDownloadDocument : FPKLibraryDocument {
    
}

class FPKLibraryBundledDocument : FPKLibraryDocument {
    
    
    static func bundledDocument(_ dictionary: NSDictionary) -> FPKLibraryBundledDocument? {
        
        // This is a bunch of required values in the dictionary
        
        if let identifier = dictionary["identifier"] as? String,
            let filename = dictionary["filename"] as? String,
            let title = dictionary["title"] as? String,
            let thumbFilename = dictionary["thumb_filename"] as? String {
                
                // We must ensure the document exist
                let documentURL = Bundle.main.url(forResource: filename, withExtension: nil)
                
                let thumbnailURL = Bundle.main.url(forResource: thumbFilename, withExtension: nil)
                
                return FPKLibraryBundledDocument(identifier: identifier, url: documentURL, title: title, thumbnail: thumbnailURL!)
        }
        
        return nil
    }
    
    static func bundledDocumentsLibraryWithJSONData(_ data: Data) -> FPKLibrary {
        
        let library = FPKLibrary()
        
        

//        try? let libraryJSON = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions()) as? NSDictionary {
//            
//            if let documents = libraryJSON["documents"] as? [NSDictionary] {
//                
//                var docsList = [FPKLibraryDocument]()
//                var docsHash = [String : FPKLibraryDocument]()
//                
//                for document in documents {
//                    
//                    if let doc = FPKLibraryBundledDocument.bundledDocument(document) {
//                        docsList.append(doc)
//                        docsHash[doc.identifier] = doc
//                    }                    
//                }
//                
//            } else if let documents = libraryJSON["documents"] as? [String : NSDictionary] {
//                
//                var docsHash = [String : FPKLibraryDocument]()
//                var docsList = [FPKLibraryDocument]()
//                
//                for (identifier, document) in documents {
//                    if let doc = FPKLibraryBundledDocument.bundledDocument(document) {
//                        docsList.append(doc)
//                        docsHash[doc.identifier] = doc
//                    }
//                }
//            }
//        }
        
        return library
    }
}
