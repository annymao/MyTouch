//
//  Participant.swift
//  MyTouch
//
//  Created by Tommy Lin on 2018/7/9.
//  Copyright © 2018年 NTU HCI Lab. All rights reserved.
//

import Foundation

struct Subject: Codable {

    enum Gender: String, Codable {
        case female, male, other
    }

    enum DominantHand: String, Codable {
        case left, right, both, none
    }

    struct Symptom: OptionSet {
        let rawValue: UInt

        static let slowMovement                   = Symptom(rawValue: 1 << 0)
        static let rapidFatigue                   = Symptom(rawValue: 1 << 1)
        static let poorCoordination               = Symptom(rawValue: 1 << 2)
        static let lowStrength                    = Symptom(rawValue: 1 << 3)
        static let difficultyGripping             = Symptom(rawValue: 1 << 4)
        static let difficultyHolding              = Symptom(rawValue: 1 << 5)
        static let tremor                         = Symptom(rawValue: 1 << 6)
        static let spasm                          = Symptom(rawValue: 1 << 7)
        static let lackOfSensation                = Symptom(rawValue: 1 << 8)
        static let difficultyControllingDirection = Symptom(rawValue: 1 << 9)
        static let difficultyControllingDistance  = Symptom(rawValue: 1 << 10)
    }

    enum Impairment: String, Codable {
        case parkinsons
        case cerebralPalsy
        case muscularDystrophy
        case spinalCordInjury
        case tetraplegia
        case friedreichsAtaxia
        case multipleSclerosis
        case others
        case none
    }

    enum Frequencies: String, Codable {
        case never
        case somedays
        case mostdays
        case everyday
    }

    enum Difficulties: String, Codable {
        case none
        case some
        case alot
        case unable
    }

    enum MedicalResults: String, Codable {
        case yes
        case no
    }

    enum Level: String, Codable {
        case one
        case two
        case three
        case four
        case five
    }

//    enum Level: String, Codable {
//        case alittle
//        case alot
//        case somewhereInBetween
//    }

    enum CellPhone: String, Codable {
        case none
        case basicphone
        case smartphone
        case tablet
        case other
    }

    enum Smartphone: String, Codable {
        case none
        case android
        case apple
        case blackberry
        case windows
        case other
    }

    enum Tablet: String, Codable {
        case none
        case android
        case apple
        case blackberry
        case windows
        case other
    }

    enum ReliablePrimaryDevice: String, Codable {
        case none
        case basicphone
        case androidSmartphone
        case appleSmartphone
        case blackberrySmartphone
        case windowsSmartphone
        case androidTablet
        case appleTablet
        case windowsTablet
        case other
    }

    enum PrimaryDeviceFunction: String, Codable {
        case professional
        case personal
        case both
        case emergencies
    }

    enum PrimaryDeviceUsageFrequency: String, Codable {
        case severalTimesADay
        case aboutOnceADay
        case threeToFiveDaysAWeek
        case oneToTwoDaysAWeek
        case everyFewWeeks
        case lessOften
    }

    enum PrimaryDeviceEasiness: String, Codable {
        case veryEasy
        case easyToUse
        case somewhatHardToUse
        case hardToUse
        case cannotUseWithoutHelp
    }

    enum PrimaryDeviceEnhancement: String, Codable {
        case noChanges
        case physicalAccessories
        case assistiveDevices
        case software
        case improvisedSolutions
        case other
    }

    enum PrimaryDeviceAccessibilityFeatures: String, Codable {
        case none
        case audioNavigation
        case gestureBasedControls
        case simpleDisplayOrLargeIcons
        case textMagnification
        case screenMagnification
        case customColorContrastOrAdjustment
        case increaseDecreaseContrast
        case screenReader
        case speakAutoCorrectionOrCapitalizations
        case subtitlesAndCaptioning
        case visualAlerts
        case vibratingAlerts
        case switchControlsAccess
        case menuShortcutsFavoriteApps
        case incomingCallsToHeadsetOrSpeaker
        case intelligentPersonalAssistant
        case other
    }

    var id: Int = 1111//String = UUID().uuidString
    var situation: String = "John Doe"
    var birthYear: Int = 1991
    var gender: Gender = .other
    var dominantHand: DominantHand = .none
    var concentrationDifficulty: Difficulties = .none
    var anxietyFrequency: Frequencies = .never
    var seeingDifficulty: Difficulties = .none
    var hearingDifficulty: Difficulties = .none
    var communicationDifficutly: Difficulties = .none
    var armsMovementsDifficutly: Difficulties = .none
    var handsMovementsDifficutly: Difficulties = .none
    var walkingDifficulty: Difficulties = .none
    var medicalDiagnosis: MedicalResults = .no
    var medication: MedicalResults = .no
    var pastThreeMonthsCondition: Frequencies = .never
    var lastTimeCondition: Frequencies = .never
    var previousLevelOfTiredness: Level = .one
    var currentLevelOfTiredness: Level = .one
    var mobileDeviceUsage: MedicalResults = .no

    var cellphoneOrTablet: CellPhone = .none
    var smartphone: Smartphone = .none
    var tablet: Tablet = .none

    var reliablePrimaryDevice: ReliablePrimaryDevice = .none
    var primaryDeviceFunctionality: PrimaryDeviceFunction = .personal
    var primaryDeviceFrequency: PrimaryDeviceUsageFrequency = .aboutOnceADay
    var primaryDeviceEasiness: PrimaryDeviceEasiness = .veryEasy
    var primaryDeviceEnhancement: PrimaryDeviceEnhancement = .noChanges
    var primaryDeviceAccessibilityFeatures: PrimaryDeviceAccessibilityFeatures = .none

    var slowMovement = false
    var rapidFatigue = false
    var poorCoordination = false
    var lowStrength = false
    var difficultyGripping = false
    var difficultyHolding = false
    var tremor = false
    var spasm = false
    var lackOfSensation = false
    var difficultyControllingDirection = false
    var difficultyControllingDistance = false

    var impairment: Impairment = .none

    var note: String?

    var symptomStrings: [String] {
        var texts = [String]()
        if slowMovement {
            texts.append(Symptom.slowMovement.localizedString)
        }
        if rapidFatigue {
            texts.append(Symptom.rapidFatigue.localizedString)
        }
        if poorCoordination {
            texts.append(Symptom.poorCoordination.localizedString)
        }
        if lowStrength {
            texts.append(Symptom.lowStrength.localizedString)
        }
        if difficultyGripping {
            texts.append(Symptom.difficultyGripping.localizedString)
        }
        if difficultyHolding {
            texts.append(Symptom.difficultyHolding.localizedString)
        }
        if tremor {
            texts.append(Symptom.tremor.localizedString)
        }
        if spasm {
            texts.append(Symptom.spasm.localizedString)
        }
        if lackOfSensation {
            texts.append(Symptom.lackOfSensation.localizedString)
        }
        if difficultyControllingDirection {
            texts.append(Symptom.difficultyControllingDirection.localizedString)
        }
        if difficultyControllingDistance {
            texts.append(Symptom.difficultyControllingDistance.localizedString)
        }
        return texts
    }
}


extension Subject.Gender {

    var localizedString: String {
        switch self {
        case .female:
            return NSLocalizedString("GENDER_FEMALE", comment: "")
        case .male:
            return NSLocalizedString("GENDER_MALE", comment: "")
        case .other:
            return NSLocalizedString("GENDER_OTHER", comment: "")
        }
    }
}

extension Subject.DominantHand {

    var localizedString: String {
        switch self {
        case .left:
            return NSLocalizedString("DOMINANT_HAND_LEFT", comment: "")
        case .right:
            return NSLocalizedString("DOMINANT_HAND_RIGHT", comment: "")
        case .both:
            return NSLocalizedString("DOMINANT_HAND_BOTH", comment: "")
        case .none:
            return NSLocalizedString("DOMINANT_HAND_NONE", comment: "")
        }
    }
}

extension Subject.Impairment {

    var localizedString: String {
        switch self {
        case .parkinsons:
            return NSLocalizedString("IMPAIRMENT_PARKINSONS", comment: "")

        case .cerebralPalsy:
            return NSLocalizedString("IMPAIRMENT_CEREBRAL_PALSY", comment: "")

        case .muscularDystrophy:
            return NSLocalizedString("IMPAIRMENT_MUSCULAR_DYSTROPHY", comment: "")

        case .spinalCordInjury:
            return NSLocalizedString("IMPAIRMENT_SPINAL_CORD_INJURY", comment: "")

        case .tetraplegia:
            return NSLocalizedString("IMPAIRMENT_TETRAPLEGIA", comment: "")

        case .friedreichsAtaxia:
            return NSLocalizedString("IMPAIRMENT_FRIEDREICHS_ATAXIA", comment: "")

        case .multipleSclerosis:
            return NSLocalizedString("IMPAIRMENT_MULTIPLE_SCLEROSIS", comment: "")

        case .others:
            return NSLocalizedString("IMPAIRMENT_OTHERS", comment: "")

        case .none:
            return NSLocalizedString("IMPAIRMENT_NONE", comment: "")
        }
    }
}

extension Subject.Symptom {

    var localizedString: String {
        switch self {

        case .slowMovement:
            return NSLocalizedString("SYMPTOM_SLOW_MOVEMENT", comment: "")

        case .rapidFatigue:
            return NSLocalizedString("SYMPTOM_RAPID_FATIGUE", comment: "")

        case .poorCoordination:
            return NSLocalizedString("SYMPTOM_POOR_COORDINATION", comment: "")

        case .lowStrength:
            return NSLocalizedString("SYMPTOM_LOW_STRENGTH", comment: "")

        case .difficultyGripping:
            return NSLocalizedString("SYMPTOM_DIFFICULTY_GRIPPING", comment: "")

        case .difficultyHolding:
            return NSLocalizedString("SYMPTOM_DIFFICULTY_HOLDING", comment: "")

        case .tremor:
            return NSLocalizedString("SYMPTOM_TREMOR", comment: "")

        case .spasm:
            return NSLocalizedString("SYMPTOM_SPASM", comment: "")

        case .lackOfSensation:
            return NSLocalizedString("SYMPTOM_LACK_OF_SENSATION", comment: "")

        case .difficultyControllingDirection:
            return NSLocalizedString("SYMPTOM_DIFFICULTY_CONTROLLING_DIRECTION", comment: "")

        case .difficultyControllingDistance:
            return NSLocalizedString("SYMPTOM_DIFFICULTY_CONTROLLING_DISTANCE", comment: "")

        default:
            return NSLocalizedString("SYMPTOM_UNKNOWN", comment: "")
        }
    }
}

extension Subject.Difficulties {

    var localizedString: String {
        switch self {
        case .none:
            return NSLocalizedString("NO_DIFFICULTY", comment: "")
        case .some:
            return NSLocalizedString("SOME_DIFFICULTY", comment: "")
        case .alot:
            return NSLocalizedString("A_LOT_DIFFICULTY", comment: "")
        case .unable:
            return NSLocalizedString("UNABLE_TO_DO", comment: "")
        }
    }
}

extension Subject.Frequencies {

    var localizedString: String {
        switch self {
        case .never:
            return NSLocalizedString("FREQUENCY_NEVER", comment: "")
        case .somedays:
            return NSLocalizedString("FREQUENCY_SOME_DAYS", comment: "")
        case .mostdays:
            return NSLocalizedString("FREQUENCY_MOST_DAYS", comment: "")
        case .everyday:
            return NSLocalizedString("FREQUENCY_EVERY_DAY", comment: "")
        }
    }
}

extension Subject.MedicalResults {

    var localizedString: String {
        switch self {
        case .yes:
            return NSLocalizedString("ANSWER_YES", comment: "")
        case .no:
            return NSLocalizedString("ANSWER_NO", comment: "")
        }
    }
}

extension Subject.Level {

    var localizedString: String {
        switch self {
        case .one:
            return NSLocalizedString("LEVEL_ONE", comment: "")
        case .two:
            return NSLocalizedString("LEVEL_TWO", comment: "")
        case .three:
            return NSLocalizedString("LEVEL_THREE", comment: "")
        case .four:
            return NSLocalizedString("LEVEL_FOUR", comment: "")
        case .five:
            return NSLocalizedString("LEVEL_FIVE", comment: "")
        }
    }
}

extension Subject.CellPhone {

    var localizedString: String {
        switch self {
        case .none:
            return NSLocalizedString("CELLPHONE_OR_TABLET_DONT_USE", comment: "")
        case .basicphone:
            return NSLocalizedString("CELLPHONE_OR_TABLET_BASICPHONE", comment: "")
        case .smartphone:
            return NSLocalizedString("CELLPHONE_OR_TABLET_SMARTPHONE", comment: "")
        case .tablet:
            return NSLocalizedString("CELLPHONE_OR_TABLET_TABLET", comment: "")
        case .other:
            return NSLocalizedString("CELLPHONE_OR_TABLET_OTHER", comment: "")
        }
    }
}

extension Subject.Smartphone {

    var localizedString: String {
        switch self {
        case .none:
            return NSLocalizedString("SMARTPHONE_KIND_DONT_USE", comment: "")
        case .android:
            return NSLocalizedString("SMARTPHONE_KIND_ANDROID", comment: "")
        case .apple:
            return NSLocalizedString("SMARTPHONE_KIND_APPLE", comment: "")
        case .blackberry:
            return NSLocalizedString("SMARTPHONE_KIND_BLACKBERRY", comment: "")
        case .windows:
            return NSLocalizedString("SMARTPHONE_KIND_WINDOWS", comment: "")
        case .other:
            return NSLocalizedString("SMARTPHONE_KIND_OTHER", comment: "")
        }
    }
}

extension Subject.Tablet {

    var localizedString: String {
        switch self {
        case .none:
            return NSLocalizedString("TABLET_KIND_DONT_USE", comment: "")
        case .android:
            return NSLocalizedString("TABLET_KIND_ANDROID", comment: "")
        case .apple:
            return NSLocalizedString("TABLET_KIND_APPLE", comment: "")
        case .blackberry:
            return NSLocalizedString("TABLET_KIND_BLACKBERRY", comment: "")
        case .windows:
            return NSLocalizedString("TABLET_KIND_WINDOWS", comment: "")
        case .other:
            return NSLocalizedString("TABLET_KIND_OTHER", comment: "")
        }
    }
}

extension Subject.ReliablePrimaryDevice {

    var localizedString: String {
        switch self {
        case .none:
            return NSLocalizedString("PRIMARY_DEVICE_DONT_USE", comment: "")
        case .basicphone:
            return NSLocalizedString("PRIMARY_DEVICE_BASICPHONE", comment: "")
        case .androidSmartphone:
            return NSLocalizedString("PRIMARY_DEVICE_ANDROID_SMARTPHONE", comment: "")
        case .appleSmartphone:
            return NSLocalizedString("PRIMARY_DEVICE_APPLE_SMARTPHONE", comment: "")
        case .blackberrySmartphone:
            return NSLocalizedString("PRIMARY_DEVICE_BLACKBERRY_SMARTPHONE", comment: "")
        case .windowsSmartphone:
            return NSLocalizedString("PRIMARY_DEVICE_WINDOWS_SMARTPHONE", comment: "")
        case .androidTablet:
            return NSLocalizedString("PRIMARY_DEVICE_ANDROID_TABLET", comment: "")
        case .appleTablet:
            return NSLocalizedString("PRIMARY_DEVICE_APPLE_TABLET", comment: "")
        case .windowsTablet:
            return NSLocalizedString("PRIMARY_DEVICE_WINDOWS_TABLET", comment: "")
        case .other:
            return NSLocalizedString("PRIMARY_DEVICE_OTHER", comment: "")
        }
    }
}

extension Subject.PrimaryDeviceFunction {

    var localizedString: String {
        switch self {
        case .professional:
            return NSLocalizedString("PRIMARY_DEVICE_FUNCTIONALITY_PROFESSIONAL", comment: "")
        case .personal:
            return NSLocalizedString("PRIMARY_DEVICE_FUNCTIONALITY_PERSONAL", comment: "")
        case .both:
            return NSLocalizedString("PRIMARY_DEVICE_FUNCTIONALITY_BOTH", comment: "")
        case .emergencies:
            return NSLocalizedString("PRIMARY_DEVICE_FUNCTIONALITY_EMERGENCIES", comment: "")
        }
    }
}

extension Subject.PrimaryDeviceUsageFrequency {

    var localizedString: String {
        switch self {
        case .severalTimesADay:
            return NSLocalizedString("PRIMARY_DEVICE_SERVERAL", comment: "")
        case .aboutOnceADay:
            return NSLocalizedString("PRIMARY_DEVICE_ONCEADAY", comment: "")
        case .threeToFiveDaysAWeek:
            return NSLocalizedString("PRIMARY_DEVICE_3_TO_5", comment: "")
        case .oneToTwoDaysAWeek:
            return NSLocalizedString("PRIMARY_DEVICE_1_OR_2", comment: "")
        case .everyFewWeeks:
            return NSLocalizedString("PRIMARY_DEVICE_FEW_WEEKS", comment: "")
        case .lessOften:
            return NSLocalizedString("PRIMARY_DEVICE_LESS_OFTEN", comment: "")
        }
    }
}

extension Subject.PrimaryDeviceEasiness {
    var localizedString: String {
        switch self {
        case .veryEasy:
            return NSLocalizedString("PRIMARY_DEVICE_VERY_EASY", comment: "")
        case .easyToUse:
            return NSLocalizedString("PRIMARY_DEVICE_EASY", comment: "")
        case .somewhatHardToUse:
            return NSLocalizedString("PRIMARY_DEVICE_SOMEWHAT", comment: "")
        case .hardToUse:
            return NSLocalizedString("PRIMARY_DEVICE_HARD", comment: "")
        case .cannotUseWithoutHelp:
            return NSLocalizedString("PRIMARY_DEVICE_WITH_HELP", comment: "")
        }
    }
}

extension Subject.PrimaryDeviceEnhancement {
    var localizedString: String {
        switch self {
        case .noChanges:
            return NSLocalizedString("PRIMARY_DEVICE_NO_CHANGES", comment: "")
        case .physicalAccessories:
            return NSLocalizedString("PRIMARY_DEVICE_PHYSICAL_ACCESSORIES", comment: "")
        case .assistiveDevices:
            return NSLocalizedString("PRIMARY_DEVICE_ASSISTANT", comment: "")
        case .software:
            return NSLocalizedString("PRIMARY_DEVICE_SOFTWARE", comment: "")
        case .improvisedSolutions:
            return NSLocalizedString("PRIMARY_DEVICE_IMPROVISED", comment: "")
        case .other:
            return NSLocalizedString("PRIMARY_DEVICE_OTHER", comment: "")
        }
    }
}

extension Subject.PrimaryDeviceAccessibilityFeatures {

    var localizedString: String {
        switch self {
        case .none:
            return NSLocalizedString("PRIMARY_DEVICE_DONT_USE_ACCESSIBILITY", comment: "")
        case .audioNavigation:
            return NSLocalizedString("PRIMARY_DEVICE_AUDIO", comment: "")
        case .gestureBasedControls:
            return NSLocalizedString("PRIMARY_DEVICE_GESTURE", comment: "")
        case .simpleDisplayOrLargeIcons:
            return NSLocalizedString("PRIMARY_DEVICE_SIMPLE_DISPLAY", comment: "")
        case .textMagnification:
            return NSLocalizedString("PRIMARY_DEVICE_TEXT_MAGNIFICATION", comment: "")
        case .screenMagnification:
            return NSLocalizedString("PRIMARY_DEVICE_SCREEN_MAGNIFICATION", comment: "")
        case .customColorContrastOrAdjustment:
            return NSLocalizedString("PRIMARY_DEVICE_CUSTOM_COLOR", comment: "")
        case .increaseDecreaseContrast:
            return NSLocalizedString("PRIMARY_DEVICE_INCREASE_CONTRAST", comment: "")
        case .screenReader:
            return NSLocalizedString("PRIMARY_DEVICE_SCREEN_RADAR", comment: "")
        case .speakAutoCorrectionOrCapitalizations:
            return NSLocalizedString("PRIMARY_DEVICE_SPEAK_AUTO", comment: "")
        case .subtitlesAndCaptioning:
            return NSLocalizedString("PRIMARY_DEVICE_SUBSTITLES", comment: "")
        case .visualAlerts:
            return NSLocalizedString("PRIMARY_DEVICE_VISUAL_ALERTS", comment: "")
        case .vibratingAlerts:
            return NSLocalizedString("PRIMARY_DEVICE_VIBRATING_ALERTS", comment: "")
        case .switchControlsAccess:
            return NSLocalizedString("PRIMARY_DEVICE_SWITCH_CONTROL", comment: "")
        case .menuShortcutsFavoriteApps:
            return NSLocalizedString("PRIMARY_DEVICE_MENU_SHORTCUTS", comment: "")
        case .incomingCallsToHeadsetOrSpeaker:
            return NSLocalizedString("PRIMARY_DEVICE_HEADSET", comment: "")
        case .intelligentPersonalAssistant:
            return NSLocalizedString("PRIMARY_DEVICE_INTELLIGENT_ASSISTANT", comment: "")
        case .other:
            return NSLocalizedString("PRIMARY_DEVICE_OTHER", comment: "")
        }
    }
}
