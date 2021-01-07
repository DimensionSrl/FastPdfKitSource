//
//  FPKLibraryDataSource.swift
//  FastPdfKitLibrary
//
//  Created by Nicolo' on 01/06/15.
//
//

import UIKit

class FPKLibraryDataSource: NSObject {
    
    var libraries = [String : FPKLibrary]()
    var librariesList = [FPKLibrary]()
    
    var documents : [FPKLibraryDocument]!
    
    var sortClosure : ((FPKLibraryDocument, FPKLibraryDocument) -> Bool)?
    
    var grouped : Bool
    
    override init() {
        self.grouped = false
    }
    
    func documentsInSection(_ section: UInt) -> [FPKLibraryDocument] {
     
        return [FPKLibraryDocument]()
    }
    
    func sortedDocuments() -> [FPKLibraryDocument] {
    
        if (sortClosure != nil) {
            documents.sorted(by: sortClosure!)
        }
        
        return documents
    }
    
    func numberOfSections() -> UInt {
        if grouped {
            return UInt(libraries.count)
        }
        return 1
    }
}
