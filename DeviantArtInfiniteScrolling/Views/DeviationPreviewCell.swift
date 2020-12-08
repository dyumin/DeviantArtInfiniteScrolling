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

    var data: Deviaton!
    {
        didSet
        {
            self.label.text = "\(data.title ?? "__title__") by \(data.author_username ?? "__author__")"
            self.deviationImage.image = nil

            self.scrollView.isScrollEnabled = false
            self.scrollView.showsVerticalScrollIndicator = false

            self.disposeBag = DisposeBag()
            DAMediaManager.shared.getContent(for: data)?.image.asObservable().observeOn(MainScheduler.instance).subscribe(onNext:
            { (event) in
                if let image = event {
                    self.deviationImage.image = image

                    if (image.size.height > image.size.width) {
                        print(self.label.text)
                        let aspectX = image.size.width / self.scrollView.frame.size.width
                        let newHeight = image.size.height / aspectX

                        self.imageHeight.constant = newHeight

                        var contentFrameSize = self.deviationImage.frame.size
                        contentFrameSize.height = newHeight
                        self.scrollView.contentSize = contentFrameSize

                        self.scrollView.isScrollEnabled = true
                        self.scrollView.showsVerticalScrollIndicator = true
                    }
                    else {
                        self.imageHeight.constant = self.scrollView.frame.size.height
                        self.deviationImage.setNeedsLayout()

                        var contentFrameSize = self.deviationImage.frame.size
                        contentFrameSize.height = self.scrollView.frame.size.height
                        self.scrollView.contentSize = contentFrameSize
                    }
                }

            }).disposed(by: disposeBag)
        }
    }
}
