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
    {
        didSet
        {
            deviationImage.translatesAutoresizingMaskIntoConstraints = false
        }
    }
    @IBOutlet weak var imageHeight: NSLayoutConstraint!

    @IBOutlet weak var label: UILabel!
    
    @IBOutlet weak var scrollView: UIScrollView!

    
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
                    
                    if (image.size.height > image.size.width)
                    {
                        print(self.label.text)
                        let aspectX = image.size.width / self.scrollView.frame.size.width
                        let newHeight = image.size.height / aspectX

                        self.imageHeight.constant = newHeight
                        self.deviationImage.setNeedsLayout()
                        
                        var contentFrameSize = self.deviationImage.frame.size
                        contentFrameSize.height = newHeight
                        self.scrollView.contentSize = contentFrameSize
                    }
                    else
                    {
                        self.imageHeight.constant = self.scrollView.frame.size.height
                        self.deviationImage.setNeedsLayout()
                        
                        var contentFrameSize = self.deviationImage.frame.size
                        contentFrameSize.height = self.scrollView.frame.size.height
                        self.scrollView.contentSize = contentFrameSize
                    }
                    
//                    if (image.size.height > image.size.width)
//                    {
//                        let aspectX = image.size.width / self.scrollView.frame.size.width
//                        let newHeight = image.size.height / aspectX
//
//                        var newFrame = self.scrollView.frame
//                        newFrame.size.height = newHeight
//
//                        self.deviationImage.frame = newFrame
//                    }
//                    else
//                    {
//                        self.deviationImage.frame = self.scrollView.frame
//                    }
//
//                    self.deviationImage.setNeedsLayout()

//                    NSLayoutConstraint.init(item: <#T##Any#>, attribute: <#T##NSLayoutConstraint.Attribute#>, relatedBy: <#T##NSLayoutConstraint.Relation#>, toItem: <#T##Any?#>, attribute: <#T##NSLayoutConstraint.Attribute#>, multiplier: <#T##CGFloat#>, constant: <#T##CGFloat#>)
                    
//                    let constraint = self.deviationImage.heightAnchor.constraint(lessThanOrEqualToConstant: newHeight)
//                    self.deviationImage.addConstraint(constraint)
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
