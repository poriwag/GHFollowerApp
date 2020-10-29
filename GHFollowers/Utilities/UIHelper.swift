//
//  UIHelper.swift
//  GHFollowers
//
//  Created by billy pak on 10/9/20.
//  Copyright © 2020 Sean Allen. All rights reserved.
//

import UIKit

struct UIHelper {
    
    static func createThreeColumnFlowLayout(in view: UIView) -> UICollectionViewFlowLayout {
        
        let width                        = view.bounds.width     //total width of the screen
        let padding: CGFloat             = 12
        let mininumItemSpacing: CGFloat  = 10
        let avaliableWidth = width - padding - (padding * 2) - (mininumItemSpacing * 2)
       //The itemwidth is The Total avaliable width we can use for the padding including
        //the padding and space between images
        let itemWidth = avaliableWidth / 3
        //creating laylout
        let flowLayout     = UICollectionViewFlowLayout()
        flowLayout.sectionInset     = UIEdgeInsets(top: padding, left: padding, bottom: padding, right: padding)
        flowLayout.itemSize         = CGSize(width: itemWidth, height: itemWidth + 40)
        
        return flowLayout
    }
}
