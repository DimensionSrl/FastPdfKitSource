//
//  MultimediaTableViewCell.swift
//  FastPdfKitLibrary
//
//  Created by Nicolo' Tosi on 04/08/16.
//
//

import UIKit

class MultimediaTableViewCell: UITableViewCell {
    
    @IBOutlet var title : UILabel!
    @IBOutlet var unzip : UIButton!
    
    func bindDocument(_ document : MultimediaDocument!) {
        self.title.text = document.name;
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
