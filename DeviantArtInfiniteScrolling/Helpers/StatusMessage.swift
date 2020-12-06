//
//  StatusMessage.swift
//  DeviantArtInfiniteScrolling
//
//  Created by El D on 05.12.2020.
//

import SwiftMessages

func showStatus(_ messageText: String, _ theme: Theme)
{
#if DEBUG
    
    DispatchQueue.main.async
    {
        let view = MessageView.viewFromNib(layout: .statusLine)
        
        // Theme message elements with the info style.
        view.configureTheme(theme)
        
        // Add a drop shadow.
        view.configureDropShadow()
        
        view.configureContent(body: messageText)
        
        // Increase the external margin around the card. In general, the effect of this setting
        // depends on how the given layout is constrained to the layout margins.
        view.layoutMarginAdditions = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        
        // Reduce the corner radius (applicable to layouts featuring rounded corners).
        (view.backgroundView as? CornerRoundingView)?.cornerRadius = 20
        
        // Show the message.
        SwiftMessages.show(view: view)
    }
    
#endif
}
