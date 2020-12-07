//
//  DeviationPreviewCell.swift
//  DeviantArtInfiniteScrolling
//
//  Created by El D on 05.12.2020.
//

import UIKit
import RxSwift

class DeviationPreviewCell: UITableViewCell
{
    static let identifier: String = "DeviationPreviewCell"
    
    var disposeBag = DisposeBag()
    
    @IBOutlet weak var deviationImage: UIImageView!
    @IBOutlet weak var label: UILabel!
    
    var data : Deviaton!
    {
        didSet
        {
            self.label.text = "\(data.title ?? "__title__") by \(data.author_username ?? "__author__")"
            self.deviationImage.image = nil
            
            let disposeBag = DisposeBag()
            DAMediaManager.shared.getContent(for: data)?.image.asObservable().observeOn(MainScheduler.instance).subscribe(onNext:
            { (event) in
                if let image = event
                {
                    self.deviationImage.image = image
                }
                
            }).disposed(by: disposeBag)
            
            self.disposeBag = disposeBag
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
