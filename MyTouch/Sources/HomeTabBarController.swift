//
//  HomeTabBarController.swift
//  MyTouch
//
//  Created by Tommy Lin on 2019/1/16.
//  Copyright © 2019 NTU HCI Lab. All rights reserved.
//

import UIKit
import ResearchKit
import UserNotifications

extension Notification.Name {
    static let sessionsDidLoad = Notification.Name("sessionsDidLoad")
    static let sessionDidUpload = Notification.Name("sessionDidUpload")
}

/// The root view controller of This app.
///
/// It handles API client actions and store the sessions returned by the client.
///
/// It also handles ResearchKit-related flow, such as creating and handling consent, survey, and active task.
class HomeTabBarController: UITabBarController {

    // MARK: - UIViewController
    let motionManager = CMMotionManager()
    let activityManager = CMMotionActivityManager()
    var gyroAllTimeData = [GyroScopeData]()
    var accAllTimeData = [AccelerometerData]()
    var motionAllTimeData = [DeviceMotionData]()
    var activityAllTimeData = [MotionActivityData]()
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        // Display in landscape mode in iPad and in protrait mode on other devices (currently iPhone only).
        switch UIDevice.current.userInterfaceIdiom {
        case .pad:
            return [.landscapeLeft, .landscapeRight]
        default:
            return [.portrait]
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if #available(iOS 13.0, *) {
            overrideUserInterfaceStyle = .light
        }

        // Set up tab bar appearance.
        tabBar.isTranslucent = false
        tabBar.tintColor = UIColor(hex: 0x00b894)
        tabBar.unselectedItemTintColor = UIColor(hex: 0xb2bec3)
        
        // Set up notification observation.
        NotificationCenter.default.addObserver(self, selector: #selector(handleApplicationWillEnterForeground(_:)), name: UIApplication.willEnterForegroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleApplicationWillResignActive(_:)), name: UIApplication.willResignActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleApplicationWillResignActive(_:)), name: UIApplication.willTerminateNotification, object: nil)
        
        
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // If not consented, present consent form, else upload cached sessions if needed.
        if UserDefaults.standard.bool(forKey: UserDefaults.Key.consented) == false {
            presentConsent()
        } else {
            uploadCachedSessions()
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Sessions
    
    private(set) var isSessionsLoaded: Bool = false
    private(set) var sessions: [Session] = []
    private(set) var error: Error?
    
    
    // MARK: - API
    
    private let client = APIClient()
    
    func reloadSessions(completion: (() -> Void)? = nil) {
        print("Reload")
        client.loadSessions { (sessions, error) in
            
            self.isSessionsLoaded = true
            
            // save sessions in storage
//            sessions?.forEach {
//                do {
//                    try $0.save()
//                } catch {
//                    print(error.localizedDescription)
//                }
//            }
//
            // sort sessions by date, newest on top
            self.sessions = Session.locals().sorted { $0.start > $1.start }
            //self.error = error
            
            // notify everyone that sessions are loadeds
            let notification = Notification(name: .sessionsDidLoad, object: self, userInfo: nil)
            NotificationQueue.default.enqueue(notification, postingStyle: .asap)
            
            completion?()
        }
    }
    
    func uploadSession(_ session: Session, completion: @escaping (Session?, Error?) -> Void) {
        client.uploadSession(session,completion: completion)
    }
    
    func uploadCachedSessions() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.reloadSessions {
                
               /* for cache in self.sessions.filter({ $0.state == .local }) {
                    self.uploadSession(cache) { (_, _) in
                        self.reloadSessions()
                    }
                }*/
            }
        }
    }
    
    
    // MARK: - Handle App State Notification
    
    @objc private func handleApplicationWillEnterForeground(_ notification: Notification) {
        uploadCachedSessions()
    }
    
    @objc private func handleApplicationWillResignActive(_ notification: Notification) {
        
        // If any local cached session exists, schedule an local notification.
        if self.sessions.filter({ $0.state == .local }).count > 0 {
            
            let content = UNMutableNotificationContent()
            content.title = NSLocalizedString("LOCAL_SESSIONS_NOTIFICATION_TITLE", comment: "local sessions notification title")
            content.body = NSLocalizedString("LOCAL_SESSIONS_NOTIFICATION_BODY", comment: "local sessions notification body")
            
            // trigger every 15:30
            var dateComponents = DateComponents()
            dateComponents.hour = 15
            dateComponents.minute = 30
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
            let request = UNNotificationRequest(identifier: "test", content: content, trigger: trigger)
            
            UNUserNotificationCenter.current().add(request) { (error) in
                if let error = error {
                    print(error.localizedDescription)
                }
            }
        }
    }
    
    
    // MARK: - Research FLow

    private var currentSession: Session?
    
    func presentConsent() {
        let taskViewController = ORKTaskViewController(task: consentTask(), taskRun: consentID)
        taskViewController.delegate = self
        taskViewController.modalPresentationStyle = .fullScreen
        taskViewController.view.backgroundColor = .white
        if #available(iOS 13.0, *) {
            taskViewController.overrideUserInterfaceStyle = .light
        }
        present(taskViewController, animated: true, completion: nil)
    }
    
    func presentSurveyAndActivity() {
        
        var subject: Subject?
        if let data = UserDefaults.standard.data(forKey: UserDefaults.Key.latestSubject) {
            subject = try? APIClient.decoder.decode(Subject.self, from: data)
        }

        // if latest subject exists, ask user if he/she wants to auto fill in with it.
        if let subject = subject {
            
            // present subject summary view controller
            let vc = SubjectSummaryViewController(subject: subject) { [unowned self] vc, autoFillIn in
                
                // dismiss subject summary view controller
                vc.dismiss(animated: true) {
                    
                    // if should auto fill in, present activity flow with that subject
                    if autoFillIn {
                        let page = AdditionalPageViewController()
                        page.modalPresentationStyle = .fullScreen
                        self.present(page, animated: true, completion: nil)
                        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 8.0) {
                            page.dismiss(animated: true, completion: nil)
                            self.presentActivity(with: Session(deviceInfo: DeviceInfo(), subject: subject))
                        }
                    }
                    
                    // else, present subject survey
                    else {
                        let taskViewController = ORKTaskViewController(task: surveyTask(), taskRun: surveyID)
                        taskViewController.delegate = self
                        taskViewController.modalPresentationStyle = .fullScreen
                        taskViewController.view.backgroundColor = .white
                        if #available(iOS 13.0, *) {
                            taskViewController.overrideUserInterfaceStyle = .light
                        }
                        self.present(taskViewController, animated: true, completion: nil)
                    }
                }
            }
            
            vc.modalPresentationStyle = .custom
            vc.transitioningDelegate = self
            if #available(iOS 13.0, *) {
                vc.overrideUserInterfaceStyle = .light
            }
            present(vc, animated: true, completion: nil)
        }
            
        // latest subject not exists, present subject survey directly
        else {
            let taskViewController = ORKTaskViewController(task: surveyTask(), taskRun: surveyID)
            taskViewController.delegate = self
            taskViewController.modalPresentationStyle = .fullScreen
            taskViewController.view.backgroundColor = .white
            if #available(iOS 13.0, *) {
                taskViewController.overrideUserInterfaceStyle = .light
            }
            present(taskViewController, animated: true, completion: nil)
        }
    }
    
    private func presentActivity(with session: Session) {
        
        self.currentSession = session
        //Core Motion Manager
        self.motionAllTimeData.removeAll()
        print(self.motionAllTimeData.count)
        if (motionManager.isDeviceMotionAvailable) {
            motionManager.deviceMotionUpdateInterval = 1.0/60.0;
            motionManager.startDeviceMotionUpdates(to: OperationQueue.main, withHandler: { (deviceData: CMDeviceMotion?, NSError) -> Void in
                let rotation = deviceData!.rotationRate
                let userAcc = deviceData!.userAcceleration
                self.motionAllTimeData.append(DeviceMotionData(timestamp: deviceData!.timestamp, rotate: rotation, userAcc: userAcc))
                if (NSError != nil){
                    print("\(String(describing: NSError))")
                }
            })
        }
        else{
            print("No device motion available")
        }

        self.accAllTimeData.removeAll()
        print(self.accAllTimeData.count)
        if (motionManager.isAccelerometerAvailable) {
            motionManager.accelerometerUpdateInterval = 1.0/60.0;
            motionManager.startAccelerometerUpdates(to: OperationQueue.main, withHandler: { (accData: CMAccelerometerData?, NSError) -> Void in
                let acc = accData!.acceleration
                let x = acc.x
                let y = acc.y
                let z = acc.z
                self.accAllTimeData.append(AccelerometerData(timestamp: accData!.timestamp, x: x, y: y, z: z))
                if (NSError != nil){
                    print("\(String(describing: NSError))")
                }
            })
        }
        else{
            print("No accelerometer available")
        }
        
        self.gyroAllTimeData.removeAll()
        print(self.gyroAllTimeData.count)
        if (motionManager.isGyroAvailable) {
            print("startGyroData\n")
            motionManager.gyroUpdateInterval = 1.0/60.0
            motionManager.startGyroUpdates(to: OperationQueue.main, withHandler: { (gyroData: CMGyroData?, NSError) -> Void in
                let rotation = gyroData!.rotationRate
                let x = rotation.x
                let y = rotation.y
                let z = rotation.z
                self.gyroAllTimeData.append(GyroScopeData(timestamp: gyroData!.timestamp, x: x, y: y, z: z))
                if (NSError != nil){
                    print("\(String(describing: NSError))")
                }
            })
        } else {
            print("No gyro available")
        }
        self.activityAllTimeData.removeAll()
        print(activityAllTimeData.count)
        if(CMMotionActivityManager.isActivityAvailable()){
            
            print("start Activity Data\n")
            activityManager.startActivityUpdates(to: OperationQueue.main, withHandler: { activityData in
                let tmpData = MotionActivityData(motionActivity: activityData!)
                self.activityAllTimeData.append(tmpData)
                print(tmpData.activity)

            })
        }
        else{
            print("No activity available")
        }
        let taskViewController = ORKTaskViewController(task: activityTask(), taskRun: activityID)
        taskViewController.delegate = self
        taskViewController.modalPresentationStyle = .fullScreen
        taskViewController.view.backgroundColor = .white
        if #available(iOS 13.0, *) {
            taskViewController.overrideUserInterfaceStyle = .light
        }

        present(taskViewController, animated: true) {
            self.currentSession?.start = Date()
        }

    }
    
    private func consentDidFinish(taskViewController: ORKTaskViewController, with reason: ORKTaskViewControllerFinishReason, error: Error?) {
        
        if reason == .completed {
            UserDefaults.standard.set(true, forKey: UserDefaults.Key.consented)
            UserDefaults.standard.synchronize()
            
            taskViewController.dismiss(animated: true, completion: nil)
        } else {
            
            let title = NSLocalizedString("OOPS", comment: "")
            let message = NSLocalizedString("MUST_CONSENT_MESSAGE", comment: "")
            let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
            let action = UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil)
            
            alertController.addAction(action)
            if #available(iOS 13.0, *) {
                alertController.overrideUserInterfaceStyle = .light
            }
            taskViewController.present(alertController, animated: true, completion: nil)
        }
    }
    
    private func surveyDidFinish(taskViewController: ORKTaskViewController, with reason: ORKTaskViewControllerFinishReason, error: Error?) {
        
        switch reason {
        case .completed:
            
            if let autoFillResult = taskViewController.result.stepResult(forStepIdentifier: "autoFill")?.result(forIdentifier: "autoFill") as? ORKBooleanQuestionResult,
                autoFillResult.booleanAnswer == NSNumber(booleanLiteral: true) {
                
                let data = UserDefaults.standard.data(forKey: UserDefaults.Key.latestSubject)
                assert(data != nil, "Cannot load latest subject")
                
                do {
                    let subject = try APIClient.decoder.decode(Subject.self, from: data!)
                    taskViewController.dismiss(animated: true) {
                        let page = AdditionalPageViewController()
                        page.modalPresentationStyle = .fullScreen
                        self.present(page, animated: true, completion: nil)
                        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 8.0) {
                            page.dismiss(animated: true, completion: nil)
                            self.presentActivity(with: Session(deviceInfo: DeviceInfo(), subject: subject))
                        }

                    }
                } catch {
                    print(error)
                    fatalError()
                }
                
                return
            }
            
            // Generate subject object
            var subject = Subject()
            
            if let birthResult = taskViewController.result.stepResult(forStepIdentifier: "birth")?.result(forIdentifier: "birth") as? ORKNumericQuestionResult {
                subject.birthYear = birthResult.numericAnswer!.intValue
            }
            if let idResult = taskViewController.result.stepResult(forStepIdentifier: "id")?.result(forIdentifier: "id") as? ORKNumericQuestionResult {
                subject.id = idResult.numericAnswer!.intValue
            }
            
            if let nameResult = taskViewController.result.stepResult(forStepIdentifier: "situation")?.result(forIdentifier: "situation") as? ORKTextQuestionResult {
                subject.situation = nameResult.textAnswer!
            }
            
            if let genderResult = taskViewController.result.stepResult(forStepIdentifier: "gender")?.result(forIdentifier: "gender") as? ORKChoiceQuestionResult {
                if let answer = genderResult.choiceAnswers?.first as? String {
                    subject.gender = Subject.Gender(rawValue: answer) ?? .other
                }
            }
            
            if let handResult = taskViewController.result.stepResult(forStepIdentifier: "hand")?.result(forIdentifier: "hand") as? ORKChoiceQuestionResult {
                if let answer = handResult.choiceAnswers?.first as? String {
                    subject.dominantHand = Subject.DominantHand(rawValue: answer) ?? .none
                }
            }
            
            if let impairmentResult = taskViewController.result.stepResult(forStepIdentifier: "impairment")?.result(forIdentifier: "impairment") as? ORKChoiceQuestionResult {
                if let answer = impairmentResult.choiceAnswers?.first as? String {
                    subject.impairment = Subject.Impairment(rawValue: answer) ?? .none
                }
            }
            
            if let symptomResult = taskViewController.result.stepResult(forStepIdentifier: "symptom")?.result(forIdentifier: "symptom") as? ORKChoiceQuestionResult {
                if let answer = symptomResult.choiceAnswers as? [UInt] {
                    for n in answer {
                        switch Subject.Symptom(rawValue: n) {
                        case .slowMovement:                   subject.slowMovement = true
                        case .rapidFatigue:                   subject.rapidFatigue = true
                        case .poorCoordination:               subject.poorCoordination = true
                        case .lowStrength:                    subject.lowStrength = true
                        case .difficultyGripping:             subject.difficultyGripping = true
                        case .difficultyHolding:              subject.difficultyHolding = true
                        case .tremor:                         subject.tremor = true
                        case .spasm:                          subject.spasm = true
                        case .lackOfSensation:                subject.lackOfSensation = true
                        case .difficultyControllingDirection: subject.difficultyControllingDirection = true
                        case .difficultyControllingDistance:  subject.difficultyControllingDistance = true
                        default: break
                        }
                    }
                }
            }

            if let concentrationResult = taskViewController.result.stepResult(forStepIdentifier: "concentration")?.result(forIdentifier: "concentration") as? ORKChoiceQuestionResult {
                if let answer = concentrationResult.choiceAnswers?.first as? String {
                    subject.concentrationDifficulty = Subject.Difficulties(rawValue: answer) ?? .none
                }
            }

            if let anxietyResult = taskViewController.result.stepResult(forStepIdentifier: "anxiety")?.result(forIdentifier: "anxiety") as? ORKChoiceQuestionResult {
                if let answer = anxietyResult.choiceAnswers?.first as? String {
                    subject.anxietyFrequency = Subject.Frequencies(rawValue: answer) ?? .never
                }
            }

            if let seeingResult = taskViewController.result.stepResult(forStepIdentifier: "seeing")?.result(forIdentifier: "seeing") as? ORKChoiceQuestionResult {
                if let answer = seeingResult.choiceAnswers?.first as? String {
                    subject.seeingDifficulty = Subject.Difficulties(rawValue: answer) ?? .none
                }
            }

            if let hearingResult = taskViewController.result.stepResult(forStepIdentifier: "hearing")?.result(forIdentifier: "hearing") as? ORKChoiceQuestionResult {
                if let answer = hearingResult.choiceAnswers?.first as? String {
                    subject.hearingDifficulty = Subject.Difficulties(rawValue: answer) ?? .none
                }
            }

            if let communicationResult = taskViewController.result.stepResult(forStepIdentifier: "communication")?.result(forIdentifier: "communication") as? ORKChoiceQuestionResult {
                if let answer = communicationResult.choiceAnswers?.first as? String {
                    subject.communicationDifficutly = Subject.Difficulties(rawValue: answer) ?? .none
                }
            }

            if let armsMovementsResult = taskViewController.result.stepResult(forStepIdentifier: "armsMovements")?.result(forIdentifier: "armsMovements") as? ORKChoiceQuestionResult {
                if let answer = armsMovementsResult.choiceAnswers?.first as? String {
                    subject.armsMovementsDifficutly = Subject.Difficulties(rawValue: answer) ?? .none
                }
            }

            if let handsMovementsResult = taskViewController.result.stepResult(forStepIdentifier: "handsMovements")?.result(forIdentifier: "handsMovements") as? ORKChoiceQuestionResult {
                if let answer = handsMovementsResult.choiceAnswers?.first as? String {
                    subject.handsMovementsDifficutly = Subject.Difficulties(rawValue: answer) ?? .none
                }
            }

            if let walkingResult = taskViewController.result.stepResult(forStepIdentifier: "walking")?.result(forIdentifier: "walking") as? ORKChoiceQuestionResult {
                if let answer = walkingResult.choiceAnswers?.first as? String {
                    subject.walkingDifficulty = Subject.Difficulties(rawValue: answer) ?? .none
                }
            }

            if let medicalDiagnosisResult = taskViewController.result.stepResult(forStepIdentifier: "medicalDiagnosis")?.result(forIdentifier: "medicalDiagnosis") as? ORKChoiceQuestionResult {
                if let answer = medicalDiagnosisResult.choiceAnswers?.first as? String {
                    subject.medicalDiagnosis = Subject.MedicalResults(rawValue: answer) ?? .no
                }
            }

            if let medicationResult = taskViewController.result.stepResult(forStepIdentifier: "medication")?.result(forIdentifier: "medication") as? ORKChoiceQuestionResult {
                if let answer = medicationResult.choiceAnswers?.first as? String {
                    subject.medication = Subject.MedicalResults(rawValue: answer) ?? .no
                }
            }

            if let pastThreeMonthsConditionResult = taskViewController.result.stepResult(forStepIdentifier: "pastThreeMonthsCondition")?.result(forIdentifier: "pastThreeMonthsCondition") as? ORKChoiceQuestionResult {
                if let answer = pastThreeMonthsConditionResult.choiceAnswers?.first as? String {
                    subject.pastThreeMonthsCondition = Subject.Frequencies(rawValue: answer) ?? .never
                }
            }

            if let lastTimeConditionResult = taskViewController.result.stepResult(forStepIdentifier: "lastTimeCondition")?.result(forIdentifier: "lastTimeCondition") as? ORKChoiceQuestionResult {
                if let answer = lastTimeConditionResult.choiceAnswers?.first as? String {
                    subject.lastTimeCondition = Subject.Frequencies(rawValue: answer) ?? .never
                }
            }

            if let previousLevelOfTirednessResult = taskViewController.result.stepResult(forStepIdentifier: "previousLevelOfTiredness")?.result(forIdentifier: "previousLevelOfTiredness") as? ORKChoiceQuestionResult {
                if let answer = previousLevelOfTirednessResult.choiceAnswers?.first as? String {
                    subject.previousLevelOfTiredness = Subject.Level(rawValue: answer) ?? .one
                }
            }

            if let currentLevelOfTirednessResult = taskViewController.result.stepResult(forStepIdentifier: "currentLevelOfTiredness")?.result(forIdentifier: "currentLevelOfTiredness") as? ORKChoiceQuestionResult {
                if let answer = currentLevelOfTirednessResult.choiceAnswers?.first as? String {
                    subject.currentLevelOfTiredness = Subject.Level(rawValue: answer) ?? .one
                }
            }

            if let mobileDeviceUsageResult = taskViewController.result.stepResult(forStepIdentifier: "mobileDeviceUsage")?.result(forIdentifier: "mobileDeviceUsage") as? ORKChoiceQuestionResult {
                if let answer = mobileDeviceUsageResult.choiceAnswers?.first as? String {
                    subject.mobileDeviceUsage = Subject.MedicalResults(rawValue: answer) ?? .no
                }
            }


            if let cellphoneOrTableResult = taskViewController.result.stepResult(forStepIdentifier: "cellphoneOrTablet")?.result(forIdentifier: "cellphoneOrTablet") as? ORKChoiceQuestionResult {
                if let answer = cellphoneOrTableResult.choiceAnswers?.first as? String {
                    subject.cellphoneOrTablet = Subject.CellPhone(rawValue: answer) ?? .none
                }
            }

            if let smartphoneResult = taskViewController.result.stepResult(forStepIdentifier: "smartphone")?.result(forIdentifier: "smartphone") as? ORKChoiceQuestionResult {
                if let answer = smartphoneResult.choiceAnswers?.first as? String {
                    subject.smartphone = Subject.Smartphone(rawValue: answer) ?? .none
                }
            }

            if let tableResult = taskViewController.result.stepResult(forStepIdentifier: "tablet")?.result(forIdentifier: "tablet") as? ORKChoiceQuestionResult {
                if let answer = tableResult.choiceAnswers?.first as? String {
                    subject.tablet = Subject.Tablet(rawValue: answer) ?? .none
                }
            }

            if let reliablePrimaryDeviceResult = taskViewController.result.stepResult(forStepIdentifier: "reliablePrimaryDevice")?.result(forIdentifier: "reliablePrimaryDevice") as? ORKChoiceQuestionResult {
                if let answer = reliablePrimaryDeviceResult.choiceAnswers?.first as? String {
                    subject.reliablePrimaryDevice = Subject.ReliablePrimaryDevice(rawValue: answer) ?? .none
                }
            }

            if let primaryDeviceFunctionalityResult = taskViewController.result.stepResult(forStepIdentifier: "primaryDeviceFunctionality")?.result(forIdentifier: "primaryDeviceFunctionality") as? ORKChoiceQuestionResult {
                if let answer = primaryDeviceFunctionalityResult.choiceAnswers?.first as? String {
                    subject.primaryDeviceFunctionality = Subject.PrimaryDeviceFunction(rawValue: answer) ?? .personal
                }
            }

            if let primaryDeviceFrequencyResult = taskViewController.result.stepResult(forStepIdentifier: "primaryDeviceFrequency")?.result(forIdentifier: "primaryDeviceFrequency") as? ORKChoiceQuestionResult {
                if let answer = primaryDeviceFrequencyResult.choiceAnswers?.first as? String {
                    subject.primaryDeviceFrequency = Subject.PrimaryDeviceUsageFrequency(rawValue: answer) ?? .aboutOnceADay
                }
            }

            if let primaryDeviceEasinessResult = taskViewController.result.stepResult(forStepIdentifier: "primaryDeviceEasiness")?.result(forIdentifier: "primaryDeviceEasiness") as? ORKChoiceQuestionResult {
                if let answer = primaryDeviceEasinessResult.choiceAnswers?.first as? String {
                    subject.primaryDeviceEasiness = Subject.PrimaryDeviceEasiness(rawValue: answer) ?? .veryEasy
                }
            }

            if let primaryDeviceEnhancementResult = taskViewController.result.stepResult(forStepIdentifier: "primaryDeviceEnhancement")?.result(forIdentifier: "primaryDeviceEnhancement") as? ORKChoiceQuestionResult {
                if let answer = primaryDeviceEnhancementResult.choiceAnswers?.first as? String {
                    subject.primaryDeviceEnhancement = Subject.PrimaryDeviceEnhancement(rawValue: answer) ?? .noChanges
                }
            }

            if let primaryDeviceAccessibilityFeaturesResult = taskViewController.result.stepResult(forStepIdentifier: "primaryDeviceAccessibilityFeature")?.result(forIdentifier: "primaryDeviceAccessibilityFeature") as? ORKChoiceQuestionResult {
                if let answer = primaryDeviceAccessibilityFeaturesResult.choiceAnswers?.first as? String {
                    subject.primaryDeviceAccessibilityFeatures = Subject.PrimaryDeviceAccessibilityFeatures(rawValue: answer) ?? .none
                }
            }

            do {
                let data = try APIClient.encoder.encode(subject)
                UserDefaults.standard.set(data, forKey: UserDefaults.Key.latestSubject)
                UserDefaults.standard.synchronize()
            }
            catch {
                print(error)
            }
            
            // End of generate subject
            
            taskViewController.dismiss(animated: true) {
                let page = AdditionalPageViewController()
                page.modalPresentationStyle = .fullScreen
                self.present(page, animated: true, completion: nil)
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 8.0) {
                    page.dismiss(animated: true, completion: nil)
                    self.presentActivity(with: Session(deviceInfo: DeviceInfo(), subject: subject))
                }
            }
            
        default:
            self.currentSession = nil
            taskViewController.dismiss(animated: true, completion: nil)
        }
    }
    
    private func activityDidFinish(taskViewController: ORKTaskViewController, with reason: ORKTaskViewControllerFinishReason, error: Error?) {
        
        guard var session = currentSession else {
            return
        }
        
        switch reason {
        case .completed:
            
            session.end = Date()

            // SYENNY: (NEW UPDATE 11/15) add a delay for 5 seconds before running the task (tap, horizontal scroll, vertical scroll)
            if let result = taskViewController.result.stepResult(forStepIdentifier: "touchAbilityTap")?.result(forIdentifier: "touchAbilityTap") as? ORKTouchAbilityTapResult {
                session.tap = TapTask(result: result)
            }
            
            if let result = taskViewController.result.stepResult(forStepIdentifier: "touchAbilityLongPress")?.result(forIdentifier: "touchAbilityLongPress") as? ORKTouchAbilityLongPressResult {
                session.longPress = LongPressTask(result: result)
            }
            
            if let result = taskViewController.result.stepResult(forStepIdentifier: "touchAbilitySwipe")?.result(forIdentifier: "touchAbilitySwipe") as? ORKTouchAbilitySwipeResult {
                session.swipe = SwipeTask(result: result)
            }
            
            if let result = taskViewController.result.stepResult(forStepIdentifier: "touchAbilityHorizontalScroll")?.result(forIdentifier: "touchAbilityHorizontalScroll") as? ORKTouchAbilityScrollResult {
                session.horizontalScroll = ScrollTask(result: result)
            }
            
            if let result = taskViewController.result.stepResult(forStepIdentifier: "touchAbilityVerticalScroll")?.result(forIdentifier: "touchAbilityVerticalScroll") as? ORKTouchAbilityScrollResult {
                session.verticalScroll = ScrollTask(result: result)
            }
            self.motionManager.stopGyroUpdates()
            self.motionManager.stopDeviceMotionUpdates()
            self.motionManager.stopAccelerometerUpdates()
            self.activityManager.stopActivityUpdates()
            session.gyroData = self.gyroAllTimeData
            session.accData = self.accAllTimeData
            session.motionData = self.motionAllTimeData
            session.activityData = self.activityAllTimeData
            
            uploadSession(session) { uploaded, error in
                
                // if success, save and reload
                if let uploaded = uploaded {
                    
                    try? uploaded.save()
                    taskViewController.dismiss(animated: true) {
                        //self.reloadSessions()
                        let page = AdditionalPageViewController()
                        page.modalPresentationStyle = .fullScreen
                        self.present(page, animated: true, completion: nil)
                        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 8.0) {
                            page.dismiss(animated: true, completion: nil)
                        }
                    }
                }
                
                // if error occured, present error message
                else if error != nil {
                    
                    let alertController = UIAlertController(
                        title: NSLocalizedString("Finish", comment: ""),
                        message: "Thank you!",
                        preferredStyle: .alert
                    )
                    alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default) { action in
                        
                        // try to save local cache after presenting upload error meesage
                        do {
                            // Save session as local cache
                            try session.save()
                            taskViewController.dismiss(animated: true) {
                                //self.reloadSessions()
                                let page = AdditionalPageViewController()
                                page.modalPresentationStyle = .fullScreen
                                self.present(page, animated: true, completion: nil)
                                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 8.0) {
                                    page.dismiss(animated: true, completion: nil)
                                }
                            }
                            
                        } catch {
                            
                            // error occured when saving session, present error and DO NOT dismiss task view controller
                            let alertController = UIAlertController(
                                title: NSLocalizedString("ERROR2", comment: ""),
                                message: error.localizedDescription,
                                preferredStyle: .alert
                            )
                            alertController.addAction(UIAlertAction(
                                title: NSLocalizedString("OK", comment: ""),
                                style: .default,
                                handler: nil)
                            )
                            
                            // present error message, DO NOT dismiss task view controller
                            if #available(iOS 13.0, *) {
                                alertController.overrideUserInterfaceStyle = .light
                            }
                            taskViewController.present(alertController, animated: true, completion: nil)
                        }
                    })
                    
                    // present error message, DO NOT dismiss task view controller
                    if #available(iOS 13.0, *) {
                        alertController.overrideUserInterfaceStyle = .light
                    }
                    taskViewController.present(alertController, animated: true, completion: nil)
                }
            }
            
        case .discarded:
            
            let title = NSLocalizedString("FINISH_EXAM_QUESTION_TITLE", comment: "")
            let message = NSLocalizedString("FINISH_EXAM_QUESTION_BODY", comment: "")
            let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
            let confirm = UIAlertAction(title: NSLocalizedString("END", comment: ""), style: .destructive) { _ in
                self.currentSession = nil
                self.motionManager.stopGyroUpdates()
                self.motionManager.stopDeviceMotionUpdates()
                self.motionManager.stopAccelerometerUpdates()
                self.activityManager.stopActivityUpdates()
                self.gyroAllTimeData.removeAll()
                self.accAllTimeData.removeAll()
                self.motionAllTimeData.removeAll()
                self.activityAllTimeData.removeAll()
                taskViewController.dismiss(animated: true, completion: nil)
            }
            let cancel = UIAlertAction(title: NSLocalizedString("CONTINUE_EXAM", comment: ""), style: .default, handler: nil)
            
            alertController.addAction(confirm)
            alertController.addAction(cancel)

            if #available(iOS 13.0, *) {
                alertController.overrideUserInterfaceStyle = .light
            }

            taskViewController.present(alertController, animated: true, completion: nil)
            
        default:
            currentSession = nil
            self.motionManager.stopGyroUpdates()
            self.motionManager.stopDeviceMotionUpdates()
            self.motionManager.stopAccelerometerUpdates()
            self.activityManager.stopActivityUpdates()
            self.gyroAllTimeData.removeAll()
            self.accAllTimeData.removeAll()
            self.motionAllTimeData.removeAll()
            self.activityAllTimeData.removeAll()
            taskViewController.dismiss(animated: true, completion: nil)
            
        }
    }
}


// MARK: - ORKTaskViewControllerDelegate

extension HomeTabBarController: ORKTaskViewControllerDelegate {
    
    func taskViewController(_ taskViewController: ORKTaskViewController, didFinishWith reason: ORKTaskViewControllerFinishReason, error: Error?) {
        
        switch taskViewController.taskRunUUID {
        case consentID:
            consentDidFinish(taskViewController: taskViewController, with: reason, error: error)
            
        case surveyID:
            surveyDidFinish(taskViewController: taskViewController, with: reason, error: error)
            
        case activityID:
            activityDidFinish(taskViewController: taskViewController, with: reason, error: error)
            
        default:
            break
        }
    }
}

extension HomeTabBarController: UIViewControllerTransitioningDelegate {
    
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        
        if presented is SubjectSummaryViewController {
            return CenterModalPresentationController(presentedViewController: presented, presenting: presenting)
        }
        
        return nil
    }
}


// MARK: - ResearchKit Flow

private func consentTask() -> ORKOrderedTask {
    
    let document = ORKConsentDocument()
    document.title = NSLocalizedString("MYTOUCH_CONSENT_DOCUMENT", comment: "")
    
    /*
     * Supported types (in ResearchKit recommanded order):
     * .overview, .dataGathering, .privacy, .dataUse, .timeCommitment, .studySurvey, .studyTasks, .withdrawing
     */
    let sectionTypes: [ORKConsentSectionType] = [
        .overview,
        .dataGathering,
        .privacy,
        .studySurvey,
        .withdrawing
    ]

    let consentSections: [ORKConsentSection] = sectionTypes.map { contentSectionType in
        let consentSection = ORKConsentSection(type: contentSectionType)
        switch contentSectionType {
        case .overview:
            consentSection.summary = NSLocalizedString("MYTOUCH_CONSENT_OVERVIEW_SUMMARY", comment: "")
            // consentSection.content = ""

        case .dataGathering:
            consentSection.summary = NSLocalizedString("MYTOUCH_CONSENT_DATA_GATHERING_SUMMARY", comment: "")

        case .privacy:
            consentSection.summary = NSLocalizedString("MYTOUCH_CONSENT_PRIVACY_SUMMARY", comment: "")

        case .studySurvey:
            consentSection.summary = NSLocalizedString("MYTOUCH_CONSENT_STUDY_SURVEY_SUMMARY", comment: "")

        case .withdrawing:
            consentSection.summary = NSLocalizedString("MYTOUCH_CONSENT_WITHDRAWING_SUMMARY", comment: "")

        default:
            break
        }
        return consentSection
    }

    document.sections = consentSections
    document.addSignature(ORKConsentSignature(forPersonWithTitle: NSLocalizedString("MYOTUCH_USER_TITLE", comment: ""), dateFormatString: nil, identifier: "signature"))

    var steps = [ORKStep]()

    let visualConsentStep = ORKVisualConsentStep(identifier: "visualConsent", document: document)
    steps.append(visualConsentStep)

//    let signature = document.signatures?.first
//    let reviewStep = ORKConsentReviewStep(identifier: "review", signature: signature, in: document)
//    reviewStep.text = "檢閱同意書" // "Review the consent"
//    reviewStep.reasonForConsent = "MyTouch 使用同意書"// "Consent to join the Research Study."
//    steps.append(reviewStep)

    let completionStep = ORKCompletionStep(identifier: "completion")
    completionStep.title = NSLocalizedString("WELCOME", comment: "")
    completionStep.text = NSLocalizedString("THANK_YOU", comment: "")
    steps.append(completionStep)

    return ORKOrderedTask(identifier: "consentTask", steps: steps)
}

private func surveyTask(with subject: Subject? = nil) -> ORKOrderedTask {

    var steps = [ORKStep]()

    let instructionStep = ORKInstructionStep(identifier: "intro")
    instructionStep.title = NSLocalizedString("SURVEY_INSTRUCTION_TITLE", comment: "")
    instructionStep.text = NSLocalizedString("SURVEY_INSTRUCTION_TEXT", comment: "")
    steps += [instructionStep]

    // ANNY-NOTE: ID
    let idFormat = ORKNumericAnswerFormat.integerAnswerFormat(withUnit: nil)
    idFormat.minimum = NSNumber(value: 0)
    idFormat.maximum = NSNumber(value: 10000)
    steps.append(ORKQuestionStep(
        identifier: "id",
        title: NSLocalizedString("SURVEY_ID_TITLE", comment: ""),
        question: NSLocalizedString("SURVEY_ID_TITLE", comment: ""),
        answer: idFormat)
    )

    // name -> situation
    let nameAnswerFormat = ORKTextAnswerFormat(maximumLength: 100)
    nameAnswerFormat.multipleLines = false
    steps.append(ORKQuestionStep(
        identifier: "situation",
        title: NSLocalizedString("SURVEY_SITUATION_TITLE", comment: ""),
        question: NSLocalizedString("SURVEY_SITUATION_TITLE", comment: ""),
        answer: nameAnswerFormat)
    )



    // birth year
    let birthYearFormat = ORKNumericAnswerFormat.integerAnswerFormat(withUnit: nil)
    birthYearFormat.minimum = NSNumber(value: Calendar(identifier: .iso8601).component(.year, from: Date.distantPast))
    birthYearFormat.maximum = NSNumber(value: Calendar(identifier: .iso8601).component(.year, from: Date()))
    steps.append(ORKQuestionStep(
        identifier: "birth",
        title: NSLocalizedString("SURVEY_BIRTH_YEAR_TITLE", comment: ""),
        question: NSLocalizedString("SURVEY_BIRTH_YEAR_QUESTION", comment: ""),
        answer: birthYearFormat)
    )


    // gender
    let genderFormat = ORKTextChoiceAnswerFormat(style: .singleChoice, textChoices: [
        ORKTextChoice(text: NSLocalizedString("GENDER_FEMALE", comment: ""), value: Subject.Gender.female.rawValue as NSString),
        ORKTextChoice(text: NSLocalizedString("GENDER_MALE", comment: ""), value: Subject.Gender.male.rawValue as NSString),
        ORKTextChoice(text: NSLocalizedString("GENDER_OTHER", comment: ""), value: Subject.Gender.other.rawValue as NSString),
    ])
    steps.append(ORKQuestionStep(
        identifier: "gender",
        title: NSLocalizedString("SURVEY_GENDER_TITLE", comment: ""),
        question: NSLocalizedString("SURVEY_GENDER_QUESTION", comment: ""),
        answer: genderFormat)
    )


    // dominant hand
    let dominantHandFormat = ORKTextChoiceAnswerFormat(style: .singleChoice, textChoices: [
        ORKTextChoice(text: NSLocalizedString("DOMINANT_HAND_LEFT", comment: ""), value: Subject.DominantHand.left.rawValue as NSString),
        ORKTextChoice(text: NSLocalizedString("DOMINANT_HAND_RIGHT", comment: ""), value: Subject.DominantHand.right.rawValue as NSString),
        ORKTextChoice(text: NSLocalizedString("DOMINANT_HAND_BOTH", comment: ""), value: Subject.DominantHand.both.rawValue as NSString),
        ORKTextChoice(text: NSLocalizedString("DOMINANT_HAND_NONE", comment: ""), value: Subject.DominantHand.none.rawValue as NSString)
    ])
    steps.append(ORKQuestionStep(
        identifier: "hand",
        title: NSLocalizedString("SURVEY_DOMINANT_HAND_TITLE", comment: ""),
        question: NSLocalizedString("SURVEY_DOMINANT_HAND_QUESTION", comment: ""),
        answer: dominantHandFormat)
    )


    // health impairment
    let impairmentFormat = ORKTextChoiceAnswerFormat(style: .singleChoice, textChoices: [
        ORKTextChoice(text: NSLocalizedString("IMPAIRMENT_NONE", comment: ""), value: Subject.Impairment.none.rawValue as NSString),
        ORKTextChoice(text: NSLocalizedString("IMPAIRMENT_PARKINSONS", comment: ""), value: Subject.Impairment.parkinsons.rawValue as NSString),
        ORKTextChoice(text: NSLocalizedString("IMPAIRMENT_CEREBRAL_PALSY", comment: ""), value: Subject.Impairment.cerebralPalsy.rawValue as NSString),
        ORKTextChoice(text: NSLocalizedString("IMPAIRMENT_MUSCULAR_DYSTROPHY", comment: ""), value: Subject.Impairment.muscularDystrophy.rawValue as NSString),
        ORKTextChoice(text: NSLocalizedString("IMPAIRMENT_SPINAL_CORD_INJURY", comment: ""), value: Subject.Impairment.spinalCordInjury.rawValue as NSString),
        ORKTextChoice(text: NSLocalizedString("IMPAIRMENT_TETRAPLEGIA", comment: ""), value: Subject.Impairment.tetraplegia.rawValue as NSString),
        ORKTextChoice(text: NSLocalizedString("IMPAIRMENT_FRIEDREICHS_ATAXIA", comment: ""), value: Subject.Impairment.friedreichsAtaxia.rawValue as NSString),
        ORKTextChoice(text: NSLocalizedString("IMPAIRMENT_MULTIPLE_SCLEROSIS", comment: ""), value: Subject.Impairment.multipleSclerosis.rawValue as NSString),
        ORKTextChoice(text: NSLocalizedString("IMPAIRMENT_OTHERS", comment: ""), value: Subject.Impairment.others.rawValue as NSString),
    ])
    steps.append(ORKQuestionStep(
        identifier: "impairment",
        title: NSLocalizedString("SURVEY_IMPAIRMENT_TITLE", comment: ""),
        question: NSLocalizedString("SURVEY_IMPAIRMENT_QUESTION", comment: ""),
        answer: impairmentFormat)
    )

    // health impairment free text
    let impairmentFreeTextFormat = ORKTextAnswerFormat(maximumLength: 200)
    impairmentFreeTextFormat.multipleLines = true
    steps.append(ORKQuestionStep(
        identifier: "impairmentFreeText",
        title: NSLocalizedString("SURVEY_IMPAIRMENT_TITLE", comment: ""),
        question: NSLocalizedString("SURVEY_IMPAIRMENT_QUESTION", comment: ""),
        answer: impairmentFreeTextFormat)
    )

    // symptom
    let symptomFormat = ORKTextChoiceAnswerFormat(style: .multipleChoice, textChoices: [
        ORKTextChoice(text: NSLocalizedString("SYMPTOM_NONE", comment: ""), value: 0 as NSNumber),
        ORKTextChoice(text: NSLocalizedString("SYMPTOM_SLOW_MOVEMENT", comment: ""), value: Subject.Symptom.slowMovement.rawValue as NSNumber),
        ORKTextChoice(text: NSLocalizedString("SYMPTOM_RAPID_FATIGUE", comment: ""), value: Subject.Symptom.rapidFatigue.rawValue as NSNumber),
        ORKTextChoice(text: NSLocalizedString("SYMPTOM_POOR_COORDINATION", comment: ""), value: Subject.Symptom.poorCoordination.rawValue as NSNumber),
        ORKTextChoice(text: NSLocalizedString("SYMPTOM_LOW_STRENGTH", comment: ""), value: Subject.Symptom.lowStrength.rawValue as NSNumber),
        ORKTextChoice(text: NSLocalizedString("SYMPTOM_DIFFICULTY_GRIPPING", comment: ""), value: Subject.Symptom.difficultyGripping.rawValue as NSNumber),
        ORKTextChoice(text: NSLocalizedString("SYMPTOM_DIFFICULTY_HOLDING", comment: ""), value: Subject.Symptom.difficultyHolding.rawValue as NSNumber),
        ORKTextChoice(text: NSLocalizedString("SYMPTOM_TREMOR", comment: ""), value: Subject.Symptom.tremor.rawValue as NSNumber),
        ORKTextChoice(text: NSLocalizedString("SYMPTOM_SPASM", comment: ""), value: Subject.Symptom.spasm.rawValue as NSNumber),
        ORKTextChoice(text: NSLocalizedString("SYMPTOM_LACK_OF_SENSATION", comment: ""), value: Subject.Symptom.lackOfSensation.rawValue as NSNumber),
        ORKTextChoice(text: NSLocalizedString("SYMPTOM_DIFFICULTY_CONTROLLING_DIRECTION", comment: ""), value: Subject.Symptom.difficultyControllingDirection.rawValue as NSNumber),
        ORKTextChoice(text: NSLocalizedString("SYMPTOM_DIFFICULTY_CONTROLLING_DISTANCE", comment: ""), value: Subject.Symptom.difficultyControllingDistance.rawValue as NSNumber),
    ])
    steps.append(ORKQuestionStep(
        identifier: "symptom",
        title: NSLocalizedString("SURVEY_SYMPTOMS_TITLE", comment: ""),
        question: NSLocalizedString("SURVEY_SYMPTOMS_QUESTION", comment: ""),
        answer: symptomFormat)
    )


    // SYENNY: Add new survey (12/8)
    // concetration difficulty
    let concentrationDifficultyFormat = ORKTextChoiceAnswerFormat(style: .singleChoice, textChoices: [
        ORKTextChoice(text: NSLocalizedString("NO_DIFFICULTY", comment: ""), value: Subject.Difficulties.none.rawValue as NSString),
        ORKTextChoice(text: NSLocalizedString("SOME_DIFFICULTY", comment: ""), value: Subject.Difficulties.some.rawValue as NSString),
        ORKTextChoice(text: NSLocalizedString("ALOT_DIFFICULTY", comment: ""), value: Subject.Difficulties.alot.rawValue as NSString),
        ORKTextChoice(text: NSLocalizedString("UNABLE_TODO", comment: ""), value: Subject.Difficulties.unable.rawValue as NSString)
    ])

    steps.append(ORKQuestionStep(identifier: "concentration",
                                 title: NSLocalizedString("SURVEY_GENERAL_FUNCTIONING_AND_HEALTH_TITLE", comment: ""),
                                 question: NSLocalizedString("SURVEY_CONCENTRATION_DIFFICULTY_QUESTION", comment: ""),
                                 answer: concentrationDifficultyFormat)
    )


    // Anxiety frequency
    let anxietyFrequencyFormat = ORKTextChoiceAnswerFormat(style: .singleChoice, textChoices: [
        ORKTextChoice(text: NSLocalizedString("FREQUENCY_NEVER", comment: ""), value: Subject.Frequencies.never.rawValue as NSString),
        ORKTextChoice(text: NSLocalizedString("FREQUENCY_SOME_DAYS", comment: ""), value: Subject.Frequencies.somedays.rawValue as NSString),
        ORKTextChoice(text: NSLocalizedString("FREQUENCY_MOST_DAYS", comment: ""), value: Subject.Frequencies.mostdays.rawValue as NSString),
        ORKTextChoice(text: NSLocalizedString("FREQUENCY_EVERY_DAY", comment: ""), value: Subject.Frequencies.everyday.rawValue as NSString)
    ])

    steps.append(ORKQuestionStep(identifier: "anxiety",
                                 title: NSLocalizedString("SURVEY_GENERAL_FUNCTIONING_AND_HEALTH_TITLE", comment: ""),
                                 question: NSLocalizedString("SURVEY_ANXIETY_QUESTION", comment: ""),
                                 answer: anxietyFrequencyFormat)
    )

    // seeing difficulty
    let seeingDifficultyFormat = ORKTextChoiceAnswerFormat(style: .singleChoice, textChoices: [
          ORKTextChoice(text: NSLocalizedString("NO_DIFFICULTY", comment: ""), value: Subject.Difficulties.none.rawValue as NSString),
          ORKTextChoice(text: NSLocalizedString("SOME_DIFFICULTY", comment: ""), value: Subject.Difficulties.some.rawValue as NSString),
          ORKTextChoice(text: NSLocalizedString("ALOT_DIFFICULTY", comment: ""), value: Subject.Difficulties.alot.rawValue as NSString),
          ORKTextChoice(text: NSLocalizedString("UNABLE_TODO", comment: ""), value: Subject.Difficulties.unable.rawValue as NSString)
       ])

   steps.append(ORKQuestionStep(identifier: "seeing",
                               title: NSLocalizedString("SURVEY_GENERAL_FUNCTIONING_AND_HEALTH_TITLE", comment: ""),
                               question: NSLocalizedString("SURVEY_SEEING_DIFFICULTY_QUESTION", comment: ""),
                               answer: seeingDifficultyFormat)
   )

    // hearing difficulty
    let hearingDifficultyFormat = ORKTextChoiceAnswerFormat(style: .singleChoice, textChoices: [
       ORKTextChoice(text: NSLocalizedString("NO_DIFFICULTY", comment: ""), value: Subject.Difficulties.none.rawValue as NSString),
       ORKTextChoice(text: NSLocalizedString("SOME_DIFFICULTY", comment: ""), value: Subject.Difficulties.some.rawValue as NSString),
       ORKTextChoice(text: NSLocalizedString("ALOT_DIFFICULTY", comment: ""), value: Subject.Difficulties.alot.rawValue as NSString),
       ORKTextChoice(text: NSLocalizedString("UNABLE_TODO", comment: ""), value: Subject.Difficulties.unable.rawValue as NSString)
    ])

    steps.append(ORKQuestionStep(identifier: "hearing",
                                title: NSLocalizedString("SURVEY_GENERAL_FUNCTIONING_AND_HEALTH_TITLE", comment: ""),
                                question: NSLocalizedString("SURVEY_HEARING_DIFFICULTY_QUESTION", comment: ""),
                                answer: hearingDifficultyFormat)
    )

    // communication difficulty
    let communicationDifficultyFormat = ORKTextChoiceAnswerFormat(style: .singleChoice, textChoices: [
       ORKTextChoice(text: NSLocalizedString("NO_DIFFICULTY", comment: ""), value: Subject.Difficulties.none.rawValue as NSString),
       ORKTextChoice(text: NSLocalizedString("SOME_DIFFICULTY", comment: ""), value: Subject.Difficulties.some.rawValue as NSString),
       ORKTextChoice(text: NSLocalizedString("ALOT_DIFFICULTY", comment: ""), value: Subject.Difficulties.alot.rawValue as NSString),
       ORKTextChoice(text: NSLocalizedString("UNABLE_TODO", comment: ""), value: Subject.Difficulties.unable.rawValue as NSString)
    ])

    steps.append(ORKQuestionStep(identifier: "communication",
                                title: NSLocalizedString("SURVEY_GENERAL_FUNCTIONING_AND_HEALTH_TITLE", comment: ""),
                                question: NSLocalizedString("SURVEY_COMMUNICATION_DIFFICULTY_QUESTION", comment: ""),
                                answer: communicationDifficultyFormat)
    )

    // Arms movements difficulty
    let armsMovementsDifficultyFormat = ORKTextChoiceAnswerFormat(style: .singleChoice, textChoices: [
       ORKTextChoice(text: NSLocalizedString("NO_DIFFICULTY", comment: ""), value: Subject.Difficulties.none.rawValue as NSString),
       ORKTextChoice(text: NSLocalizedString("SOME_DIFFICULTY", comment: ""), value: Subject.Difficulties.some.rawValue as NSString),
       ORKTextChoice(text: NSLocalizedString("ALOT_DIFFICULTY", comment: ""), value: Subject.Difficulties.alot.rawValue as NSString),
       ORKTextChoice(text: NSLocalizedString("UNABLE_TODO", comment: ""), value: Subject.Difficulties.unable.rawValue as NSString)
    ])

    steps.append(ORKQuestionStep(identifier: "armsMovements",
                                title: NSLocalizedString("SURVEY_GENERAL_FUNCTIONING_AND_HEALTH_TITLE", comment: ""),
                                question: NSLocalizedString("SURVEY_ARMS_MOVEMENTS_DIFFICULTY_QUESTION", comment: ""),
                                answer: armsMovementsDifficultyFormat)
    )

    // hands movements difficulty
    let handsMovementsDifficultyFormat = ORKTextChoiceAnswerFormat(style: .singleChoice, textChoices: [
       ORKTextChoice(text: NSLocalizedString("NO_DIFFICULTY", comment: ""), value: Subject.Difficulties.none.rawValue as NSString),
       ORKTextChoice(text: NSLocalizedString("SOME_DIFFICULTY", comment: ""), value: Subject.Difficulties.some.rawValue as NSString),
       ORKTextChoice(text: NSLocalizedString("ALOT_DIFFICULTY", comment: ""), value: Subject.Difficulties.alot.rawValue as NSString),
       ORKTextChoice(text: NSLocalizedString("UNABLE_TODO", comment: ""), value: Subject.Difficulties.unable.rawValue as NSString)
    ])

    steps.append(ORKQuestionStep(identifier: "handsMovements",
                                title: NSLocalizedString("SURVEY_GENERAL_FUNCTIONING_AND_HEALTH_TITLE", comment: ""),
                                question: NSLocalizedString("SURVEY_HANDS_MOVEMENTS_DIFFICULTY_QUESTION", comment: ""),
                                answer: handsMovementsDifficultyFormat)
    )

    // walking difficulty
    let walkingDifficultyFormat = ORKTextChoiceAnswerFormat(style: .singleChoice, textChoices: [
       ORKTextChoice(text: NSLocalizedString("NO_DIFFICULTY", comment: ""), value: Subject.Difficulties.none.rawValue as NSString),
       ORKTextChoice(text: NSLocalizedString("SOME_DIFFICULTY", comment: ""), value: Subject.Difficulties.some.rawValue as NSString),
       ORKTextChoice(text: NSLocalizedString("ALOT_DIFFICULTY", comment: ""), value: Subject.Difficulties.alot.rawValue as NSString),
       ORKTextChoice(text: NSLocalizedString("UNABLE_TODO", comment: ""), value: Subject.Difficulties.unable.rawValue as NSString)
    ])

    steps.append(ORKQuestionStep(identifier: "walking",
                                title: NSLocalizedString("SURVEY_GENERAL_FUNCTIONING_AND_HEALTH_TITLE", comment: ""),
                                question: NSLocalizedString("SURVEY_WALKING_DIFFICULTY_QUESTION", comment: ""),
                                answer: walkingDifficultyFormat)
    )

    // medical diagnosis
    let medicalDiagnosisFormat = ORKTextChoiceAnswerFormat(style: .singleChoice, textChoices: [
        ORKTextChoice(text: NSLocalizedString("ANSWER_YES_WITH_EXPLANATION", comment: ""), value: Subject.MedicalResults.yes.rawValue as NSString),
       ORKTextChoice(text: NSLocalizedString("ANSWER_NO", comment: ""), value: Subject.MedicalResults.no.rawValue as NSString),
    ])

    steps.append(ORKQuestionStep(identifier: "medicalDiagnosis",
                                title: NSLocalizedString("SURVEY_GENERAL_FUNCTIONING_AND_HEALTH_TITLE", comment: ""),
                                question: NSLocalizedString("SURVEY_MEDICAL_DIAGNOSIS_QUESTION", comment: ""),
                                answer: medicalDiagnosisFormat)
    )

    // medical diagnosis free text
    let medicalDiagnosisFreeTextFormat = ORKTextAnswerFormat(maximumLength: 200)
    impairmentFreeTextFormat.multipleLines = true
    steps.append(ORKQuestionStep(
        identifier: "medicalDiagnosisFreeText",
        title: NSLocalizedString("SURVEY_GENERAL_FUNCTIONING_AND_HEALTH_TITLE", comment: ""),
        question: NSLocalizedString("SURVEY_MEDICAL_DIAGNOSIS_YES_QUESTION", comment: ""),
        answer: medicalDiagnosisFreeTextFormat)
    )

    // medication
    let medicationFormat = ORKTextChoiceAnswerFormat(style: .singleChoice, textChoices: [
        ORKTextChoice(text: NSLocalizedString("ANSWER_YES_WITH_EXPLANATION", comment: ""), value: Subject.MedicalResults.yes.rawValue as NSString),
       ORKTextChoice(text: NSLocalizedString("ANSWER_NO", comment: ""), value: Subject.MedicalResults.no.rawValue as NSString),
    ])

    steps.append(ORKQuestionStep(identifier: "medication",
                                title: NSLocalizedString("SURVEY_GENERAL_FUNCTIONING_AND_HEALTH_TITLE", comment: ""),
                                question: NSLocalizedString("SURVEY_MEDICATION_QUESTION", comment: ""),
                                answer: medicationFormat)
    )

    // medication free text
    let medicationFreeTextFormat = ORKTextAnswerFormat(maximumLength: 200)
    impairmentFreeTextFormat.multipleLines = true
    steps.append(ORKQuestionStep(
        identifier: "medicationFreeText",
        title: NSLocalizedString("SURVEY_GENERAL_FUNCTIONING_AND_HEALTH_TITLE", comment: ""),
        question: NSLocalizedString("SURVEY_MEDICATION_YES_QUESTION", comment: ""),
        answer: medicationFreeTextFormat)
    )

    // past 3 months condition
    let neverText = NSLocalizedString("FREQUENCY_NEVER", comment: "")
    let skipText = NSLocalizedString("SKIP_TO_THE_NEXT_SECTION", comment: "")
    let pastThreeMonthsConditionFormat = ORKTextChoiceAnswerFormat(style: .singleChoice, textChoices: [
        ORKTextChoice(text: neverText + skipText, value: Subject.Frequencies.never.rawValue as NSString),
        ORKTextChoice(text: NSLocalizedString("FREQUENCY_SOME_DAYS", comment: ""), value: Subject.Frequencies.somedays.rawValue as NSString),
        ORKTextChoice(text: NSLocalizedString("FREQUENCY_MOST_DAYS", comment: ""), value: Subject.Frequencies.mostdays.rawValue as NSString),
        ORKTextChoice(text: NSLocalizedString("FREQUENCY_EVERY_DAY", comment: ""), value: Subject.Frequencies.everyday.rawValue as NSString)
    ])

    steps.append(ORKQuestionStep(identifier: "pastThreeMonthsCondition",
                                 title: NSLocalizedString("SURVEY_FATIGUE_TITLE", comment: ""),
                                 question: NSLocalizedString("SURVEY_PAST_THREE_MONTHS_CONDITION_QUESTION", comment: ""),
                                 answer: pastThreeMonthsConditionFormat)
    )

    // last time condition
    let lastTimeConditionFormat = ORKTextChoiceAnswerFormat(style: .singleChoice, textChoices: [
        ORKTextChoice(text: NSLocalizedString("FREQUENCY_NEVER", comment: ""), value: Subject.Frequencies.never.rawValue as NSString),
        ORKTextChoice(text: NSLocalizedString("FREQUENCY_SOME_DAYS", comment: ""), value: Subject.Frequencies.somedays.rawValue as NSString),
        ORKTextChoice(text: NSLocalizedString("FREQUENCY_MOST_DAYS", comment: ""), value: Subject.Frequencies.mostdays.rawValue as NSString),
        ORKTextChoice(text: NSLocalizedString("FREQUENCY_EVERY_DAY", comment: ""), value: Subject.Frequencies.everyday.rawValue as NSString)
    ])

    steps.append(ORKQuestionStep(identifier: "lastTimeCondition",
                                 title: NSLocalizedString("SURVEY_FATIGUE_TITLE", comment: ""),
                                 question: NSLocalizedString("SURVEY_LAST_TIME_FEEL_TIRED_QUESTION", comment: ""),
                                 answer: lastTimeConditionFormat)
    )


    // last time level of tiredness
    let lastTimeLevelOfTirednessFormat = ORKTextChoiceAnswerFormat(style: .singleChoice, textChoices: [
        ORKTextChoice(text: NSLocalizedString("LEVEL_ONE", comment: ""), value: Subject.Level.one.rawValue as NSString),
        ORKTextChoice(text: NSLocalizedString("LEVEL_TWO", comment: ""), value: Subject.Level.two.rawValue as NSString),
        ORKTextChoice(text: NSLocalizedString("LEVEL_THREE", comment: ""), value: Subject.Level.three.rawValue as NSString),
        ORKTextChoice(text: NSLocalizedString("LEVEL_FOUR", comment: ""), value: Subject.Level.four.rawValue as NSString),
        ORKTextChoice(text: NSLocalizedString("LEVEL_FIVE", comment: ""), value: Subject.Level.five.rawValue as NSString)
    ])

    steps.append(ORKQuestionStep(identifier: "previousLevelOfTiredness",
                                 title: NSLocalizedString("SURVEY_FATIGUE_TITLE", comment: ""),
                                 question: NSLocalizedString("SURVEY_LAST_TIME_LEVEL_OF_TIREDNESS_QUESTION", comment: ""),
                                 answer: lastTimeLevelOfTirednessFormat)
    )


    // current level of tiredness
    let currentLevelOfTirednessFormat = ORKTextChoiceAnswerFormat(style: .singleChoice, textChoices: [
        ORKTextChoice(text: NSLocalizedString("LEVEL_ONE", comment: ""), value: Subject.Level.one.rawValue as NSString),
        ORKTextChoice(text: NSLocalizedString("LEVEL_TWO", comment: ""), value: Subject.Level.two.rawValue as NSString),
        ORKTextChoice(text: NSLocalizedString("LEVEL_THREE", comment: ""), value: Subject.Level.three.rawValue as NSString),
        ORKTextChoice(text: NSLocalizedString("LEVEL_FOUR", comment: ""), value: Subject.Level.four.rawValue as NSString),
        ORKTextChoice(text: NSLocalizedString("LEVEL_FIVE", comment: ""), value: Subject.Level.five.rawValue as NSString)
    ])

    steps.append(ORKQuestionStep(identifier: "currentLevelOfTiredness",
                                 title: NSLocalizedString("SURVEY_FATIGUE_TITLE", comment: ""),
                                 question: NSLocalizedString("SURVEY_RIGHT_NOW_LEVEL_OF_TIREDNESS_QUESTION", comment: ""),
                                 answer: currentLevelOfTirednessFormat)
    )


    // mobile device usage
    let mobileDeviceUsageFormat = ORKTextChoiceAnswerFormat(style: .singleChoice, textChoices: [
        ORKTextChoice(text: NSLocalizedString("ANSWER_YES", comment: ""), value: Subject.MedicalResults.yes.rawValue as NSString),
       ORKTextChoice(text: NSLocalizedString("ANSWER_NO", comment: ""), value: Subject.MedicalResults.no.rawValue as NSString),
    ])

    steps.append(ORKQuestionStep(identifier: "mobileDeviceUsage",
                                title: NSLocalizedString("SURVEY_MOBILE_DEVICE_USE_TITLE", comment: ""),
                                question: NSLocalizedString("SURVEY_MOBILE_DEVICE_USE_QUESTION", comment: ""),
                                answer: mobileDeviceUsageFormat)
    )

    // mobile device usage free text
    let mobileDeviceUsageFreeTextFormat = ORKTextAnswerFormat(maximumLength: 200)
    mobileDeviceUsageFreeTextFormat.multipleLines = true
    steps.append(ORKQuestionStep(
        identifier: "mobileDeviceUsageFreeText",
        title: NSLocalizedString("SURVEY_MOBILE_DEVICE_USE_TITLE", comment: ""),
        question: NSLocalizedString("SURVEY_MOBILE_DEVICE_USE_QUESTION", comment: ""),
        answer: mobileDeviceUsageFreeTextFormat)
    )


    // what kind of cellphone or tablet?
    let cellphoneOrTabletFormat = ORKTextChoiceAnswerFormat(style: .singleChoice, textChoices: [
        ORKTextChoice(text: NSLocalizedString("CELLPHONE_OR_TABLET_DONT_USE", comment: ""), value: Subject.CellPhone.none.rawValue as NSString),
        ORKTextChoice(text: NSLocalizedString("CELLPHONE_OR_TABLET_BASICPHONE", comment: ""), value: Subject.CellPhone.basicphone.rawValue as NSString),
        ORKTextChoice(text: NSLocalizedString("CELLPHONE_OR_TABLET_SMARTPHONE", comment: ""), value: Subject.CellPhone.smartphone.rawValue as NSString),
        ORKTextChoice(text: NSLocalizedString("CELLPHONE_OR_TABLET_TABLET", comment: ""), value: Subject.CellPhone.tablet.rawValue as NSString),
        ORKTextChoice(text: NSLocalizedString("CELLPHONE_OR_TABLET_OTHER", comment: ""), value: Subject.CellPhone.other.rawValue as NSString)
    ])

    steps.append(ORKQuestionStep(identifier: "cellphoneOrTablet",
                                title: NSLocalizedString("SURVEY_MOBILE_DEVICE_USE_TITLE", comment: ""),
                                question: NSLocalizedString("SURVEY_MOBILE_DEVICE_USE_TYPE_QUESTION", comment: ""),
                                answer: cellphoneOrTabletFormat)
    )


    // cellphone or tablet free text
    let otherCellPhoneOrTabletFreeTextFormat = ORKTextAnswerFormat(maximumLength: 200)
    otherCellPhoneOrTabletFreeTextFormat.multipleLines = true
    steps.append(ORKQuestionStep(
        identifier: "otherCellPhoneOrTabletFreeText",
        title: NSLocalizedString("SURVEY_MOBILE_DEVICE_USE_TITLE", comment: ""),
        question: NSLocalizedString("SURVEY_MOBILE_DEVICE_USE_TYPE_QUESTION", comment: ""),
        answer: otherCellPhoneOrTabletFreeTextFormat)
    )

    // kind of smartphone
       let smartphoneFormat = ORKTextChoiceAnswerFormat(style: .singleChoice, textChoices: [
           ORKTextChoice(text: NSLocalizedString("SMARTPHONE_KIND_DONT_USE", comment: ""), value: Subject.Smartphone.none.rawValue as NSString),
           ORKTextChoice(text: NSLocalizedString("SMARTPHONE_KIND_ANDROID", comment: ""), value: Subject.Smartphone.android.rawValue as NSString),
           ORKTextChoice(text: NSLocalizedString("SMARTPHONE_KIND_APPLE", comment: ""), value: Subject.Smartphone.apple.rawValue as NSString),
           ORKTextChoice(text: NSLocalizedString("SMARTPHONE_KIND_BLACKBERRY", comment: ""), value: Subject.Smartphone.blackberry.rawValue as NSString),
           ORKTextChoice(text: NSLocalizedString("SMARTPHONE_KIND_WINDOWS", comment: ""), value: Subject.Smartphone.windows.rawValue as NSString),
           ORKTextChoice(text: NSLocalizedString("SMARTPHONE_KIND_OTHER", comment: ""), value: Subject.Smartphone.other.rawValue as NSString)
       ])

       steps.append(ORKQuestionStep(identifier: "smartphone",
                                   title: NSLocalizedString("SURVEY_MOBILE_DEVICE_USE_TITLE", comment: ""),
                                   question: NSLocalizedString("SURVEY_MOBILE_DEVICE_BRAND_QUESTION", comment: ""),
                                   answer: smartphoneFormat)
       )

       // smartphone free text
       let smartphoneFreeTextFormat = ORKTextAnswerFormat(maximumLength: 200)
       otherCellPhoneOrTabletFreeTextFormat.multipleLines = true
       steps.append(ORKQuestionStep(
           identifier: "smartphoneFreeText",
           title: NSLocalizedString("SURVEY_MOBILE_DEVICE_USE_TITLE", comment: ""),
           question: NSLocalizedString("SURVEY_MOBILE_DEVICE_BRAND_QUESTION", comment: ""),
           answer: smartphoneFreeTextFormat)
       )

    // kind of tablet
    let tabletFormat = ORKTextChoiceAnswerFormat(style: .singleChoice, textChoices: [
        ORKTextChoice(text: NSLocalizedString("TABLET_KIND_DONT_USE", comment: ""), value: Subject.Smartphone.none.rawValue as NSString),
        ORKTextChoice(text: NSLocalizedString("TABLET_KIND_ANDROID", comment: ""), value: Subject.Smartphone.android.rawValue as NSString),
        ORKTextChoice(text: NSLocalizedString("TABLET_KIND_APPLE", comment: ""), value: Subject.Smartphone.apple.rawValue as NSString),
        ORKTextChoice(text: NSLocalizedString("TABLET_KIND_BLACKBERRY", comment: ""), value: Subject.Smartphone.blackberry.rawValue as NSString),
        ORKTextChoice(text: NSLocalizedString("TABLET_KIND_WINDOWS", comment: ""), value: Subject.Smartphone.windows.rawValue as NSString),
        ORKTextChoice(text: NSLocalizedString("TABLET_KIND_OTHER", comment: ""), value: Subject.Smartphone.other.rawValue as NSString)
    ])

    steps.append(ORKQuestionStep(identifier: "tablet",
                                title: NSLocalizedString("SURVEY_MOBILE_DEVICE_USE_TITLE", comment: ""),
                                question: NSLocalizedString("SURVEY_MOBILE_DEVICE_TABLET_QUESTION", comment: ""),
                                answer: tabletFormat)
    )

    // smartphone free text
    let tabletFreeTextFormat = ORKTextAnswerFormat(maximumLength: 200)
    otherCellPhoneOrTabletFreeTextFormat.multipleLines = true
    steps.append(ORKQuestionStep(
        identifier: "tabletFreeText",
        title: NSLocalizedString("SURVEY_MOBILE_DEVICE_USE_TITLE", comment: ""),
        question: NSLocalizedString("SURVEY_MOBILE_DEVICE_TABLET_QUESTION", comment: ""),
        answer: tabletFreeTextFormat)
    )


    // which primary device is the most reliable
    let reliablePrimaryDeviceFormat = ORKTextChoiceAnswerFormat(style: .singleChoice, textChoices: [
           ORKTextChoice(text: NSLocalizedString("PRIMARY_DEVICE_DONT_USE", comment: ""), value: Subject.ReliablePrimaryDevice.none.rawValue as NSString),
           ORKTextChoice(text: NSLocalizedString("PRIMARY_DEVICE_BASICPHONE", comment: ""), value: Subject.ReliablePrimaryDevice.basicphone.rawValue as NSString),
           ORKTextChoice(text: NSLocalizedString("PRIMARY_DEVICE_ANDROID_SMARTPHONE", comment: ""), value: Subject.ReliablePrimaryDevice.androidSmartphone.rawValue as NSString),
           ORKTextChoice(text: NSLocalizedString("PRIMARY_DEVICE_APPLE_SMARTPHONE", comment: ""), value: Subject.ReliablePrimaryDevice.appleSmartphone.rawValue as NSString),
           ORKTextChoice(text: NSLocalizedString("PRIMARY_DEVICE_BLACKBERRY_SMARTPHONE", comment: ""), value: Subject.ReliablePrimaryDevice.blackberrySmartphone.rawValue as NSString),
           ORKTextChoice(text: NSLocalizedString("PRIMARY_DEVICE_WINDOWS_SMARTPHONE", comment: ""), value: Subject.ReliablePrimaryDevice.windowsSmartphone.rawValue as NSString),
           ORKTextChoice(text: NSLocalizedString("PRIMARY_DEVICE_ANDROID_TABLET", comment: ""), value: Subject.ReliablePrimaryDevice.androidTablet.rawValue as NSString),
           ORKTextChoice(text: NSLocalizedString("PRIMARY_DEVICE_APPLE_TABLET", comment: ""), value: Subject.ReliablePrimaryDevice.appleTablet.rawValue as NSString),
           ORKTextChoice(text: NSLocalizedString("PRIMARY_DEVICE_WINDOWS_TABLET", comment: ""), value: Subject.ReliablePrimaryDevice.windowsTablet.rawValue as NSString),
           ORKTextChoice(text: NSLocalizedString("PRIMARY_DEVICE_OTHER", comment: ""), value: Subject.ReliablePrimaryDevice.other.rawValue as NSString)
       ])

    steps.append(ORKQuestionStep(identifier: "reliablePrimaryDevice",
                                title: NSLocalizedString("SURVEY_MOBILE_DEVICE_USE_TITLE", comment: ""),
                                question: NSLocalizedString("SURVEY_MOBILE_DEVICE_PRIMARY_DEVICE_QUESTION", comment: ""),
                                answer: reliablePrimaryDeviceFormat)
    )

    // smartphone free text
    let reliablePrimaryDeviceFreeTextFormat = ORKTextAnswerFormat(maximumLength: 200)
    otherCellPhoneOrTabletFreeTextFormat.multipleLines = true
    steps.append(ORKQuestionStep(
        identifier: "reliablePrimaryDeviceFreeText",
        title: NSLocalizedString("SURVEY_MOBILE_DEVICE_USE_TITLE", comment: ""),
        question: NSLocalizedString("SURVEY_MOBILE_DEVICE_PRIMARY_DEVICE_QUESTION", comment: ""),
        answer: reliablePrimaryDeviceFreeTextFormat)
    )

    // primary device's functionality
    let primaryDeviceFunctionalityFormat = ORKTextChoiceAnswerFormat(style: .singleChoice, textChoices: [
        ORKTextChoice(text: NSLocalizedString("PRIMARY_DEVICE_FUNCTIONALITY_PROFESSIONAL", comment: ""), value: Subject.PrimaryDeviceFunction.professional.rawValue as NSString),
        ORKTextChoice(text: NSLocalizedString("PRIMARY_DEVICE_FUNCTIONALITY_PERSONAL", comment: ""), value: Subject.PrimaryDeviceFunction.personal.rawValue as NSString),
        ORKTextChoice(text: NSLocalizedString("PRIMARY_DEVICE_FUNCTIONALITY_BOTH", comment: ""), value: Subject.PrimaryDeviceFunction.both.rawValue as NSString),
        ORKTextChoice(text: NSLocalizedString("PRIMARY_DEVICE_FUNCTIONALITY_EMERGENCIES", comment: ""), value: Subject.PrimaryDeviceFunction.emergencies.rawValue as NSString)
    ])

    steps.append(ORKQuestionStep(identifier: "primaryDeviceFunctionality",
                                title: NSLocalizedString("SURVEY_MOBILE_DEVICE_USE_TITLE", comment: ""),
                                question: NSLocalizedString("SURVEY_MOBILE_DEVICE_PRIMARY_DEVICE_USAGE_QUESTION", comment: ""),
                                answer: primaryDeviceFunctionalityFormat)
    )


    // primary device's use frequency
    let primaryDeviceFrequenciesFormat = ORKTextChoiceAnswerFormat(style: .singleChoice, textChoices: [
        ORKTextChoice(text: NSLocalizedString("PRIMARY_DEVICE_SERVERAL", comment: ""), value: Subject.PrimaryDeviceUsageFrequency.severalTimesADay.rawValue as NSString),
        ORKTextChoice(text: NSLocalizedString("PRIMARY_DEVICE_ONCEADAY", comment: ""), value: Subject.PrimaryDeviceUsageFrequency.aboutOnceADay.rawValue as NSString),
        ORKTextChoice(text: NSLocalizedString("PRIMARY_DEVICE_3_TO_5", comment: ""), value: Subject.PrimaryDeviceUsageFrequency.threeToFiveDaysAWeek.rawValue as NSString),
        ORKTextChoice(text: NSLocalizedString("PRIMARY_DEVICE_1_OR_2", comment: ""), value: Subject.PrimaryDeviceUsageFrequency.oneToTwoDaysAWeek.rawValue as NSString),
        ORKTextChoice(text: NSLocalizedString("PRIMARY_DEVICE_FEW_WEEKS", comment: ""), value: Subject.PrimaryDeviceUsageFrequency.everyFewWeeks.rawValue as NSString),
        ORKTextChoice(text: NSLocalizedString("PRIMARY_DEVICE_LESS_OFTEN", comment: ""), value: Subject.PrimaryDeviceUsageFrequency.lessOften.rawValue as NSString)
    ])

    steps.append(ORKQuestionStep(identifier: "primaryDeviceFrequency",
                                title: NSLocalizedString("SURVEY_MOBILE_DEVICE_USE_TITLE", comment: ""),
                                question: NSLocalizedString("SURVEY_MOBILE_DEVICE_PRIMARY_DEVICE_USAGE_FREQUENCY_QUESTION", comment: ""),
                                answer: primaryDeviceFrequenciesFormat)
    )


    // primary device's easiness
    let primaryDeviceEasinessFormat = ORKTextChoiceAnswerFormat(style: .singleChoice, textChoices: [
        ORKTextChoice(text: NSLocalizedString("PRIMARY_DEVICE_VERY_EASY", comment: ""), value: Subject.PrimaryDeviceEasiness.veryEasy.rawValue as NSString),
        ORKTextChoice(text: NSLocalizedString("PRIMARY_DEVICE_EASY", comment: ""), value: Subject.PrimaryDeviceEasiness.easyToUse.rawValue as NSString),
        ORKTextChoice(text: NSLocalizedString("PRIMARY_DEVICE_SOMEWHAT", comment: ""), value: Subject.PrimaryDeviceEasiness.somewhatHardToUse.rawValue as NSString),
        ORKTextChoice(text: NSLocalizedString("PRIMARY_DEVICE_HARD", comment: ""), value: Subject.PrimaryDeviceEasiness.hardToUse.rawValue as NSString),
        ORKTextChoice(text: NSLocalizedString("PRIMARY_DEVICE_WITH_HELP", comment: ""), value: Subject.PrimaryDeviceEasiness.cannotUseWithoutHelp.rawValue as NSString)
    ])

    steps.append(ORKQuestionStep(identifier: "primaryDeviceEasiness",
                                title: NSLocalizedString("SURVEY_MOBILE_DEVICE_USE_TITLE", comment: ""),
                                question: NSLocalizedString("SURVEY_MOBILE_DEVICE_PRIMARY_DEVICE_EASINESS_QUESTION", comment: ""),
                                answer: primaryDeviceEasinessFormat)
    )


    // primary device's enhancement
    let primaryDeviceEnhancementFormat = ORKTextChoiceAnswerFormat(style: .singleChoice, textChoices: [
           ORKTextChoice(text: NSLocalizedString("PRIMARY_DEVICE_NO_CHANGES", comment: ""), value: Subject.PrimaryDeviceEnhancement.noChanges.rawValue as NSString),
           ORKTextChoice(text: NSLocalizedString("PRIMARY_DEVICE_PHYSICAL_ACCESSORIES", comment: ""), value: Subject.PrimaryDeviceEnhancement.physicalAccessories.rawValue as NSString),
           ORKTextChoice(text: NSLocalizedString("PRIMARY_DEVICE_ASSISTANT", comment: ""), value: Subject.PrimaryDeviceEnhancement.assistiveDevices.rawValue as NSString),
           ORKTextChoice(text: NSLocalizedString("PRIMARY_DEVICE_SOFTWARE", comment: ""), value: Subject.PrimaryDeviceEnhancement.software.rawValue as NSString),
           ORKTextChoice(text: NSLocalizedString("PRIMARY_DEVICE_IMPROVISED", comment: ""), value: Subject.PrimaryDeviceEnhancement.improvisedSolutions.rawValue as NSString),
           ORKTextChoice(text: NSLocalizedString("PRIMARY_DEVICE_OTHER", comment: ""), value: Subject.PrimaryDeviceEnhancement.other.rawValue as NSString)
    ])

    steps.append(ORKQuestionStep(identifier: "primaryDeviceEnhancement",
                                title: NSLocalizedString("SURVEY_MOBILE_DEVICE_USE_TITLE", comment: ""),
                                question: NSLocalizedString("SURVEY_MOBILE_DEVICE_PRIMARY_DEVICE_ENHANCEMENT_QUESTION", comment: ""),
                                answer: primaryDeviceEnhancementFormat)
    )

    // primary device's enhancement free text
    let primaryDeviceEnhancementFreeTextFormat = ORKTextAnswerFormat(maximumLength: 200)
    otherCellPhoneOrTabletFreeTextFormat.multipleLines = true
    steps.append(ORKQuestionStep(
        identifier: "primaryDeviceEnhancementFreeText",
        title: NSLocalizedString("SURVEY_MOBILE_DEVICE_USE_TITLE", comment: ""),
        question: NSLocalizedString("SURVEY_MOBILE_DEVICE_PRIMARY_DEVICE_ENHANCEMENT_QUESTION", comment: ""),
        answer: primaryDeviceEnhancementFreeTextFormat)
    )

    // primary device's accessibilty features
    let primaryDeviceAccessibilityFeaturesFormat = ORKTextChoiceAnswerFormat(style: .singleChoice, textChoices: [
           ORKTextChoice(text: NSLocalizedString("PRIMARY_DEVICE_DONT_USE_ACCESSIBILITY", comment: ""), value: Subject.PrimaryDeviceAccessibilityFeatures.none.rawValue as NSString),
           ORKTextChoice(text: NSLocalizedString("PRIMARY_DEVICE_AUDIO", comment: ""), value: Subject.PrimaryDeviceAccessibilityFeatures.audioNavigation.rawValue as NSString),
           ORKTextChoice(text: NSLocalizedString("PRIMARY_DEVICE_GESTURE", comment: ""), value: Subject.PrimaryDeviceAccessibilityFeatures.gestureBasedControls.rawValue as NSString),
           ORKTextChoice(text: NSLocalizedString("PRIMARY_DEVICE_SIMPLE_DISPLAY", comment: ""), value: Subject.PrimaryDeviceAccessibilityFeatures.simpleDisplayOrLargeIcons.rawValue as NSString),
           ORKTextChoice(text: NSLocalizedString("PRIMARY_DEVICE_TEXT_MAGNIFICATION", comment: ""), value: Subject.PrimaryDeviceAccessibilityFeatures.textMagnification.rawValue as NSString),
           ORKTextChoice(text: NSLocalizedString("PRIMARY_DEVICE_SCREEN_MAGNIFICATION", comment: ""), value: Subject.PrimaryDeviceAccessibilityFeatures.screenMagnification.rawValue as NSString),
           ORKTextChoice(text: NSLocalizedString("PRIMARY_DEVICE_CUSTOM_COLOR", comment: ""), value: Subject.PrimaryDeviceAccessibilityFeatures.customColorContrastOrAdjustment.rawValue as NSString),
           ORKTextChoice(text: NSLocalizedString("PRIMARY_DEVICE_INCREASE_CONTRAST", comment: ""), value: Subject.PrimaryDeviceAccessibilityFeatures.increaseDecreaseContrast.rawValue as NSString),
           ORKTextChoice(text: NSLocalizedString("PRIMARY_DEVICE_SCREEN_RADAR", comment: ""), value: Subject.PrimaryDeviceAccessibilityFeatures.screenReader.rawValue as NSString),
           ORKTextChoice(text: NSLocalizedString("PRIMARY_DEVICE_SPEAK_AUTO", comment: ""), value: Subject.PrimaryDeviceAccessibilityFeatures.speakAutoCorrectionOrCapitalizations.rawValue as NSString),
           ORKTextChoice(text: NSLocalizedString("PRIMARY_DEVICE_SUBSTITLES", comment: ""), value: Subject.PrimaryDeviceAccessibilityFeatures.subtitlesAndCaptioning.rawValue as NSString),
           ORKTextChoice(text: NSLocalizedString("PRIMARY_DEVICE_VISUAL_ALERTS", comment: ""), value: Subject.PrimaryDeviceAccessibilityFeatures.visualAlerts.rawValue as NSString),
           ORKTextChoice(text: NSLocalizedString("PRIMARY_DEVICE_VIBRATING_ALERTS", comment: ""), value: Subject.PrimaryDeviceAccessibilityFeatures.vibratingAlerts.rawValue as NSString),
           ORKTextChoice(text: NSLocalizedString("PRIMARY_DEVICE_SWITCH_CONTROL", comment: ""), value: Subject.PrimaryDeviceAccessibilityFeatures.switchControlsAccess.rawValue as NSString),
           ORKTextChoice(text: NSLocalizedString("PRIMARY_DEVICE_MENU_SHORTCUTS", comment: ""), value: Subject.PrimaryDeviceAccessibilityFeatures.menuShortcutsFavoriteApps.rawValue as NSString),
           ORKTextChoice(text: NSLocalizedString("PRIMARY_DEVICE_HEADSET", comment: ""), value: Subject.PrimaryDeviceAccessibilityFeatures.incomingCallsToHeadsetOrSpeaker.rawValue as NSString),
           ORKTextChoice(text: NSLocalizedString("PRIMARY_DEVICE_INTELLIGENT_ASSISTANT", comment: ""), value: Subject.PrimaryDeviceAccessibilityFeatures.intelligentPersonalAssistant.rawValue as NSString),
           ORKTextChoice(text: NSLocalizedString("PRIMARY_DEVICE_OTHER", comment: ""), value: Subject.PrimaryDeviceAccessibilityFeatures.other.rawValue as NSString)
    ])

    steps.append(ORKQuestionStep(identifier: "primaryDeviceAccessibilityFeature",
                                title: NSLocalizedString("SURVEY_MOBILE_DEVICE_USE_TITLE", comment: ""),
                                question: NSLocalizedString("SURVEY_MOBILE_DEVICE_PRIMARY_DEVICE_FEATURES_QUESTION", comment: ""),
                                answer: primaryDeviceAccessibilityFeaturesFormat)
    )

    // primary device's accessibilty features free text
    let primaryDeviceAccessibilityFeaturesFreeTextFormat = ORKTextAnswerFormat(maximumLength: 200)
    otherCellPhoneOrTabletFreeTextFormat.multipleLines = true
    steps.append(ORKQuestionStep(
        identifier: "primaryDeviceAccessibilityFeatureFreeText",
        title: NSLocalizedString("SURVEY_MOBILE_DEVICE_USE_TITLE", comment: ""),
        question: NSLocalizedString("SURVEY_MOBILE_DEVICE_PRIMARY_DEVICE_FEATURES_QUESTION", comment: ""),
        answer: primaryDeviceAccessibilityFeaturesFreeTextFormat)
    )


    let completionStep = ORKCompletionStep(identifier: "summary")
    completionStep.title = NSLocalizedString("THANK_YOU", comment: "")
    completionStep.text = NSLocalizedString("SURVEY_COMPLETION_TEXT", comment: "")
    steps += [completionStep]
    
    return OrderedTask(identifier: "survey", steps: steps)
}
//ANNY-NOTE: remove pinch and rotation, (NEW UPDATE 11/15) removed longPress and swipe
//ANNY-NOTE: Define which task to do here
private func activityTask() -> ORKOrderedTask {
    return ORKOrderedTask.touchAbilityTask(withIdentifier: "touch", intendedUseDescription: nil, taskOptions: [.tap, .longPress, .swipe, .verticalScroll, .horizontalScroll], options: [])
}

private let consentID = UUID()

private let surveyID = UUID()

private let activityID = UUID()

private var filename = ""
// MARK: - Private OrderedTask for skipping steps

private class OrderedTask: ORKOrderedTask {
    
    override func step(after step: ORKStep?, with result: ORKTaskResult) -> ORKStep? {
        
        if step?.identifier == "impairment" {
            
            guard let choice = result.stepResult(forStepIdentifier: "impairment")?.result(forIdentifier: "impairment") as? ORKChoiceQuestionResult else {
                return super.step(after: step, with: result)
            }
            
            guard let answer = choice.choiceAnswers?.first as? String else {
                return super.step(after: step, with: result)
            }
            
            if answer == "others" {
                return self.step(withIdentifier: "impairmentFreeText")
            } else {
                return self.step(withIdentifier: "symptom")
            }
        } else if step?.identifier == "medicalDiagnosis" {
            guard let choice = result.stepResult(forStepIdentifier: "medicalDiagnosis")?.result(forIdentifier: "medicalDiagnosis") as? ORKChoiceQuestionResult else {
                return super.step(after: step, with: result)
            }

            guard let answer = choice.choiceAnswers?.first as? String else {
                return super.step(after: step, with: result)
            }

            if answer == "yes" {
                return self.step(withIdentifier: "medicalDiagnosisFreeText")
            } else {
                return self.step(withIdentifier: "medication")
            }

        } else if step?.identifier == "medication" {
            guard let choice = result.stepResult(forStepIdentifier: "medication")?.result(forIdentifier: "medication") as? ORKChoiceQuestionResult else {
                return super.step(after: step, with: result)
            }

            guard let answer = choice.choiceAnswers?.first as? String else {
                return super.step(after: step, with: result)
            }

            if answer == "yes" {
                return self.step(withIdentifier: "medicationFreeText")
            } else {
                return self.step(withIdentifier: "pastThreeMonthsCondition")
            }
        } else if step?.identifier == "mobileDeviceUsage" {
            guard let choice = result.stepResult(forStepIdentifier: "mobileDeviceUsage")?.result(forIdentifier: "mobileDeviceUsage") as? ORKChoiceQuestionResult else {
                return super.step(after: step, with: result)
            }

            guard let answer = choice.choiceAnswers?.first as? String else {
                return super.step(after: step, with: result)
            }

            if answer == "other" {
                return self.step(withIdentifier: "mobileDeviceUsageFreeText")
            } else {
                return self.step(withIdentifier: "cellphoneOrTablet")
            }
        } else if step?.identifier == "cellphoneOrTablet" {
            guard let choice = result.stepResult(forStepIdentifier: "cellphoneOrTablet")?.result(forIdentifier: "cellphoneOrTablet") as? ORKChoiceQuestionResult else {
                return super.step(after: step, with: result)
            }

            guard let answer = choice.choiceAnswers?.first as? String else {
                return super.step(after: step, with: result)
            }

            if answer == "other" {
                return self.step(withIdentifier: "cellphoneOrTabletFreeText")
            } else {
                return self.step(withIdentifier: "smartphone")
            }
        } else if step?.identifier == "smartphone" {
            guard let choice = result.stepResult(forStepIdentifier: "smartphone")?.result(forIdentifier: "smartphone") as? ORKChoiceQuestionResult else {
                return super.step(after: step, with: result)
            }

            guard let answer = choice.choiceAnswers?.first as? String else {
                return super.step(after: step, with: result)
            }

            if answer == "other" {
                return self.step(withIdentifier: "smartphoneFreeText")
            } else {
                return self.step(withIdentifier: "tablet")
            }
        } else if step?.identifier == "tablet" {
            guard let choice = result.stepResult(forStepIdentifier: "tablet")?.result(forIdentifier: "tablet") as? ORKChoiceQuestionResult else {
                return super.step(after: step, with: result)
            }

            guard let answer = choice.choiceAnswers?.first as? String else {
                return super.step(after: step, with: result)
            }

            if answer == "other" {
                return self.step(withIdentifier: "tabletFreeText")
            } else {
                return self.step(withIdentifier: "reliablePrimaryDevice")
            }
        } else if step?.identifier == "reliablePrimaryDevice" {
            guard let choice = result.stepResult(forStepIdentifier: "reliablePrimaryDevice")?.result(forIdentifier: "reliablePrimaryDevice") as? ORKChoiceQuestionResult else {
                return super.step(after: step, with: result)
            }

            guard let answer = choice.choiceAnswers?.first as? String else {
                return super.step(after: step, with: result)
            }

            if answer == "other" {
                return self.step(withIdentifier: "reliablePrimaryDeviceFreeText")
            } else {
                return self.step(withIdentifier: "primaryDeviceFunctionality")
            }
        } else if step?.identifier == "primaryDeviceEnhancement" {
            guard let choice = result.stepResult(forStepIdentifier: "primaryDeviceEnhancement")?.result(forIdentifier: "primaryDeviceEnhancement") as? ORKChoiceQuestionResult else {
                return super.step(after: step, with: result)
            }

            guard let answer = choice.choiceAnswers?.first as? String else {
                return super.step(after: step, with: result)
            }

            if answer == "other" {
                return self.step(withIdentifier: "primaryDeviceEnhancementFreeText")
            } else {
                return self.step(withIdentifier: "primaryDeviceAccessibilityFeature")
            }
        } else if step?.identifier == "primaryDeviceAccessibilityFeature" {
            guard let choice = result.stepResult(forStepIdentifier: "primaryDeviceAccessibilityFeature")?.result(forIdentifier: "primaryDeviceAccessibilityFeature") as? ORKChoiceQuestionResult else {
                return super.step(after: step, with: result)
            }

            guard let answer = choice.choiceAnswers?.first as? String else {
                return super.step(after: step, with: result)
            }

            if answer == "other" {
                return self.step(withIdentifier: "primaryDeviceAccessibilityFeatureFreeText")
            }
        } else if step?.identifier == "autoFill" {

            guard let choice = result.stepResult(forStepIdentifier: "autoFill")?.result(forIdentifier: "autoFill") as? ORKBooleanQuestionResult else {
                return super.step(after: step, with: result)
            }

            if choice.booleanAnswer == NSNumber(booleanLiteral: true) {
                return self.step(withIdentifier: "summary")
            } else {
                return super.step(after: step, with: result)
            }
        }

        return super.step(after: step, with: result)
    }

    override func step(before step: ORKStep?, with result: ORKTaskResult) -> ORKStep? {

        if step?.identifier == "symptom" {

            guard let choice = result.stepResult(forStepIdentifier: "impairment")?.result(forIdentifier: "impairment") as? ORKChoiceQuestionResult else {
                return super.step(before: step, with: result)
            }

            guard let answer = choice.choiceAnswers?.first as? String else {
                return super.step(before: step, with: result)
            }

            if answer == "others" {
                return self.step(withIdentifier: "impairmentFreeText")
            } else {
                return self.step(withIdentifier: "impairment")
            }
        } else if step?.identifier == "medication" {
            guard let choice = result.stepResult(forStepIdentifier: "medicalDiagnosis")?.result(forIdentifier: "medicalDiagnosis") as? ORKChoiceQuestionResult else {
                return super.step(after: step, with: result)
            }

            guard let answer = choice.choiceAnswers?.first as? String else {
                return super.step(after: step, with: result)
            }

            if answer == "yes" {
                return self.step(withIdentifier: "medicalDiagnosisFreeText")
            } else {
                return self.step(withIdentifier: "medicalDiagnosis")
            }
        } else if step?.identifier == "pastThreeMonthsCondition" {
            guard let choice = result.stepResult(forStepIdentifier: "medication")?.result(forIdentifier: "medication") as? ORKChoiceQuestionResult else {
                return super.step(after: step, with: result)
            }

            guard let answer = choice.choiceAnswers?.first as? String else {
                return super.step(after: step, with: result)
            }

            if answer == "yes" {
                return self.step(withIdentifier: "medicationFreeText")
            } else {
                return self.step(withIdentifier: "medication")
            }
        } else if step?.identifier == "cellphoneOrTablet" {
            guard let choice = result.stepResult(forStepIdentifier: "mobileDeviceUsage")?.result(forIdentifier: "mobileDeviceUsage") as? ORKChoiceQuestionResult else {
                return super.step(after: step, with: result)
            }

            guard let answer = choice.choiceAnswers?.first as? String else {
                return super.step(after: step, with: result)
            }

            if answer == "other" {
                return self.step(withIdentifier: "mobileDeviceUsageFreeText")
            } else {
                return self.step(withIdentifier: "mobileDeviceUsage")
            }
        } else if step?.identifier == "smartphone" {
            guard let choice = result.stepResult(forStepIdentifier: "cellphoneOrTablet")?.result(forIdentifier: "cellphoneOrTablet") as? ORKChoiceQuestionResult else {
                return super.step(after: step, with: result)
            }

            guard let answer = choice.choiceAnswers?.first as? String else {
                return super.step(after: step, with: result)
            }

            if answer == "other" {
                return self.step(withIdentifier: "cellphoneOrTabletFreeText")
            } else {
                return self.step(withIdentifier: "cellphoneOrTablet")
            }
        } else if step?.identifier == "tablet" {
            guard let choice = result.stepResult(forStepIdentifier: "smartphone")?.result(forIdentifier: "smartphone") as? ORKChoiceQuestionResult else {
                return super.step(after: step, with: result)
            }

            guard let answer = choice.choiceAnswers?.first as? String else {
                return super.step(after: step, with: result)
            }

            if answer == "other" {
                return self.step(withIdentifier: "smartphoneFreeText")
            } else {
                return self.step(withIdentifier: "smartphone")
            }
        } else if step?.identifier == "reliablePrimaryDevice" {
            guard let choice = result.stepResult(forStepIdentifier: "tablet")?.result(forIdentifier: "tablet") as? ORKChoiceQuestionResult else {
                return super.step(after: step, with: result)
            }

            guard let answer = choice.choiceAnswers?.first as? String else {
                return super.step(after: step, with: result)
            }

            if answer == "other" {
                return self.step(withIdentifier: "tabletFreeText")
            } else {
                return self.step(withIdentifier: "tablet")
            }
        } else if step?.identifier == "primaryDeviceFunctionality" {
            guard let choice = result.stepResult(forStepIdentifier: "reliablePrimaryDevice")?.result(forIdentifier: "reliablePrimaryDevice") as? ORKChoiceQuestionResult else {
                return super.step(after: step, with: result)
            }

            guard let answer = choice.choiceAnswers?.first as? String else {
                return super.step(after: step, with: result)
            }

            if answer == "other" {
                return self.step(withIdentifier: "reliablePrimaryDeviceFreeText")
            } else {
                return self.step(withIdentifier: "reliablePrimaryDevice")
            }
        } else if step?.identifier == "primaryDeviceAccessibilityFeature" {
            guard let choice = result.stepResult(forStepIdentifier: "primaryDeviceEnhancement")?.result(forIdentifier: "primaryDeviceEnhancement") as? ORKChoiceQuestionResult else {
                return super.step(after: step, with: result)
            }

            guard let answer = choice.choiceAnswers?.first as? String else {
                return super.step(after: step, with: result)
            }

            if answer == "other" {
                return self.step(withIdentifier: "primaryDeviceEnhancementFreeText")
            } else {
                return self.step(withIdentifier: "primaryDeviceEnhancement")
            }
        } else if step?.identifier == "summary" {

            guard let choice = result.stepResult(forStepIdentifier: "autoFill")?.result(forIdentifier: "autoFill") as? ORKBooleanQuestionResult else {
                return super.step(before: step, with: result)
            }

            if choice.booleanAnswer == NSNumber(booleanLiteral: true) {
                return self.step(withIdentifier: "autoFill")
            } else {
                return super.step(before: step, with: result)
            }
        }

        return super.step(before: step, with: result)
    }
}
