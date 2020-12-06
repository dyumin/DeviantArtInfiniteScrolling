//
//  DeviationPreviewCell.swift
//  DeviantArtInfiniteScrolling
//
//  Created by El D on 05.12.2020.
//

import UIKit

class DeviationPreviewCell: UITableViewCell
{
    static let identifier: String = "DeviationPreviewCell"

    @IBOutlet weak var label: UILabel!
    var data : Deviaton!
    {
        didSet
        {
            self.label.text = "\(data.title ?? "__title__") by \(data.author_username ?? "__author__")"
        }
    }
    
    override func awakeFromNib()
    {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func setSelected(_ selected: Bool, animated: Bool)
    {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    override func prepareForReuse()
    {
        super.prepareForReuse()
    }

}
