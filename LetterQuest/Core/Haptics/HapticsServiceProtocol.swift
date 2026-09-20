//
//  HapticsServiceProtocol.swift
//  LetterQuest
//
//  Created by Bratislav Ljubisic Home  on 19.08.26.
//

protocol HapticsServiceProtocol: AnyObject {
    var isEnabled: Bool { get set }
    func playSuccess()
    func playEncouragement()
    func playSoftError()
}
