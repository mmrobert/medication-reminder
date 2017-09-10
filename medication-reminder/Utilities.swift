//
//  Utilities.swift
//  medication-reminder
//
//  Created by boqian cheng on 2017-09-07.
//  Copyright © 2017 Vikas Gandhi. All rights reserved.
//

import UIKit
import Foundation
import AudioToolbox

class Utilities: NSObject {
    
    static public func weekdayString() -> [String] {
        var wl: [String] = []
        
        let formatter : DateFormatter = DateFormatter()
        
        for index in 1...7 {
            
            let day : String = formatter.weekdaySymbols[index % 7]
            let dayShortIndex = day.index(day.startIndex, offsetBy: 2)
            let dayShort = day.substring(to: dayShortIndex).uppercased()
            
            wl.append(dayShort)
        }
        
        return wl
    }
    
    static public func playSysSound(filename: String) {
        let ext = "wav"
        
        if let soundUrl = Bundle.main.url(forResource: filename, withExtension: ext) {
            var soundId: SystemSoundID = 0
            
            AudioServicesCreateSystemSoundID(soundUrl as CFURL, &soundId)
            
            AudioServicesAddSystemSoundCompletion(soundId, nil, nil, { (soundId, clientData) -> Void in
                AudioServicesDisposeSystemSoundID(soundId)
            }, nil)
            
            AudioServicesPlaySystemSound(soundId)
        }
    }
}
