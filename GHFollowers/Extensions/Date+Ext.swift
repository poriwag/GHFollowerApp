//
//  Date+Ext.swift
//  GHFollowers
//
//  Created by billy pak on 10/20/20.
//  Copyright © 2020 Sean Allen. All rights reserved.
//

import Foundation

extension Date {
    
    func convertToMonthYearFormat() -> String? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM yyyy"
        
        return dateFormatter.string(from: self)
    }

}
