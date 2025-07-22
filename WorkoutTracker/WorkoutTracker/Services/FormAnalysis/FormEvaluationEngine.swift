import Foundation
import CoreGraphics

// MARK: - Form Evaluation Engine Protocol
protocol FormEvaluationEngineProtocol {
    func evaluateForm(_ poseSequence: [PoseKeypoints], exerciseType: ExerciseType) async throws -> FormAnalysisResult
    func generateFeedback(from analysis: FormAnalysisResult, userLevel: UserFitnessLevel) -> FormFeedback
}

// MARK: - Form Evaluation Engine Implementation
class FormEvaluationEngine: FormEvaluationEngineProtocol {
    
    // MARK: - Main Evaluation Method
    func evaluateForm(_ poseSequence: [PoseKeypoints], exerciseType: ExerciseType) async throws -> FormAnalysisResult {
        guard !poseSequence.isEmpty else {
            throw FormEvaluationError.noPoseData
        }
        
        switch exerciseType {
        case .squat:
            return try await evaluateSquatForm(poseSequence)
        case .deadlift:
            return try await evaluateDeadliftForm(poseSequence)
        case .benchPress:
            return try await evaluateBenchPressForm(poseSequence)
        case .shoulderPress:
            return try await evaluateShoulderPressForm(poseSequence)
        case .pullUp:
            return try await evaluatePullUpForm(poseSequence)
        case .unknown:
            throw FormEvaluationError.unsupportedExercise(exerciseType)
        }
    }
    
    // MARK: - Feedback Generation
    func generateFeedback(from analysis: FormAnalysisResult, userLevel: UserFitnessLevel) -> FormFeedback {
        let issues = analysis.identifiedIssues.sorted { $0.severity.rawValue > $1.severity.rawValue }
        let strengths = analysis.strengths
        
        // Prioritize feedback based on user level
        let prioritizedIssues = prioritizeIssues(issues, for: userLevel)
        let mainIssue = prioritizedIssues.first
        
        // Generate feedback message
        let feedbackMessage = createFeedbackMessage(
            analysis: analysis,
            mainIssue: mainIssue,
            strengths: strengths,
            userLevel: userLevel
        )
        
        // Generate specific corrections
        let corrections = generateCorrections(for: prioritizedIssues.prefix(3), userLevel: userLevel)
        
        return FormFeedback(
            overallScore: analysis.overallScore,
            mainFeedback: feedbackMessage,
            specificCorrections: Array(corrections),
            strengths: strengths,
            exerciseType: analysis.exerciseType,
            userLevel: userLevel,
            priority: mainIssue?.severity ?? .low
        )
    }
    
    // MARK: - Exercise-Specific Evaluations
    private func evaluateSquatForm(_ poseSequence: [PoseKeypoints]) async throws -> FormAnalysisResult {
        var issues: [FormIssue] = []
        var strengths: [FormStrength] = []
        var scores: [String: Double] = [:]
        
        // Analyze key form elements
        let kneeAnalysis = analyzeSquatKneeTracking(poseSequence)
        scores["kneeTracking"] = kneeAnalysis.score
        if kneeAnalysis.score < 0.7 {
            issues.append(FormIssue(
                type: .kneeValgus,
                severity: kneeAnalysis.score < 0.5 ? .high : .medium,
                description: "Knees are caving inward during the squat",
                affectedFrames: kneeAnalysis.problematicFrames
            ))
        } else {
            strengths.append(FormStrength(
                type: .kneeTracking,
                description: "Excellent knee tracking throughout the movement"
            ))
        }
        
        let depthAnalysis = analyzeSquatDepth(poseSequence)
        scores["depth"] = depthAnalysis.score
        if depthAnalysis.score < 0.6 {
            issues.append(FormIssue(
                type: .insufficientDepth,
                severity: .medium,
                description: "Not reaching adequate squat depth",
                affectedFrames: depthAnalysis.problematicFrames
            ))
        } else {
            strengths.append(FormStrength(
                type: .depth,
                description: "Good squat depth achieved"
            ))
        }
        
        let backAnalysis = analyzeSpinalAlignment(poseSequence)
        scores["spinalAlignment"] = backAnalysis.score
        if backAnalysis.score < 0.7 {
            issues.append(FormIssue(
                type: .spinalRounding,
                severity: backAnalysis.score < 0.5 ? .high : .medium,
                description: "Back rounding detected during the movement",
                affectedFrames: backAnalysis.problematicFrames
            ))
        } else {
            strengths.append(FormStrength(
                type: .spinalAlignment,
                description: "Maintained neutral spine throughout the movement"
            ))
        }
        
        let tempoAnalysis = analyzeMovementTempo(poseSequence)
        scores["tempo"] = tempoAnalysis.score
        if tempoAnalysis.score < 0.6 {
            issues.append(FormIssue(
                type: .inconsistentTempo,
                severity: .low,
                description: "Movement tempo is inconsistent",
                affectedFrames: []
            ))
        }
        
        // Calculate overall score
        let overallScore = calculateOverallScore(scores, weights: [
            "kneeTracking": 0.3,
            "depth": 0.25,
            "spinalAlignment": 0.35,
            "tempo": 0.1
        ])
        
        return FormAnalysisResult(
            exerciseType: .squat,
            overallScore: overallScore,
            identifiedIssues: issues,
            strengths: strengths,
            detailedScores: scores,
            repCount: detectRepCount(poseSequence, exerciseType: .squat),
            analysisDate: Date()
        )
    }
    
    private func evaluateDeadliftForm(_ poseSequence: [PoseKeypoints]) async throws -> FormAnalysisResult {
        var issues: [FormIssue] = []
        var strengths: [FormStrength] = []
        var scores: [String: Double] = [:]
        
        // Analyze bar path
        let barPathAnalysis = analyzeDeadliftBarPath(poseSequence)
        scores["barPath"] = barPathAnalysis.score
        if barPathAnalysis.score < 0.7 {
            issues.append(FormIssue(
                type: .inefficientBarPath,
                severity: .medium,
                description: "Bar is drifting away from the body",
                affectedFrames: barPathAnalysis.problematicFrames
            ))
        } else {
            strengths.append(FormStrength(
                type: .barPath,
                description: "Bar maintained close to body throughout lift"
            ))
        }
        
        // Analyze hip hinge pattern
        let hipHingeAnalysis = analyzeHipHingePattern(poseSequence)
        scores["hipHinge"] = hipHingeAnalysis.score
        if hipHingeAnalysis.score < 0.6 {
            issues.append(FormIssue(
                type: .improperHipHinge,
                severity: .high,
                description: "Hip hinge pattern needs improvement",
                affectedFrames: hipHingeAnalysis.problematicFrames
            ))
        }
        
        // Analyze spinal position
        let spinalAnalysis = analyzeSpinalAlignment(poseSequence)
        scores["spinalAlignment"] = spinalAnalysis.score
        if spinalAnalysis.score < 0.8 {
            issues.append(FormIssue(
                type: .spinalRounding,
                severity: .high,
                description: "Spinal rounding detected - high injury risk",
                affectedFrames: spinalAnalysis.problematicFrames
            ))
        } else {
            strengths.append(FormStrength(
                type: .spinalAlignment,
                description: "Maintained neutral spine - excellent form"
            ))
        }
        
        let overallScore = calculateOverallScore(scores, weights: [
            "barPath": 0.25,
            "hipHinge": 0.35,
            "spinalAlignment": 0.4
        ])
        
        return FormAnalysisResult(
            exerciseType: .deadlift,
            overallScore: overallScore,
            identifiedIssues: issues,
            strengths: strengths,
            detailedScores: scores,
            repCount: detectRepCount(poseSequence, exerciseType: .deadlift),
            analysisDate: Date()
        )
    }
    
    private func evaluateBenchPressForm(_ poseSequence: [PoseKeypoints]) async throws -> FormAnalysisResult {
        // Simplified bench press evaluation for MVP
        let issues: [FormIssue] = []
        var strengths: [FormStrength] = []
        var scores: [String: Double] = [:]
        
        // For bench press, we can mainly analyze arm/shoulder positioning
        let shoulderAnalysis = analyzeShoulderStability(poseSequence)
        scores["shoulderStability"] = shoulderAnalysis.score
        
        if shoulderAnalysis.score > 0.7 {
            strengths.append(FormStrength(
                type: .shoulderStability,
                description: "Good shoulder stability maintained"
            ))
        }
        
        let overallScore = scores["shoulderStability"] ?? 0.5
        
        return FormAnalysisResult(
            exerciseType: .benchPress,
            overallScore: overallScore,
            identifiedIssues: issues,
            strengths: strengths,
            detailedScores: scores,
            repCount: detectRepCount(poseSequence, exerciseType: .benchPress),
            analysisDate: Date()
        )
    }
    
    private func evaluateShoulderPressForm(_ poseSequence: [PoseKeypoints]) async throws -> FormAnalysisResult {
        // Simplified shoulder press evaluation
        let issues: [FormIssue] = []
        let strengths: [FormStrength] = []
        var scores: [String: Double] = [:]
        
        let shoulderAnalysis = analyzeShoulderStability(poseSequence)
        scores["shoulderStability"] = shoulderAnalysis.score
        
        let overallScore = scores["shoulderStability"] ?? 0.5
        
        return FormAnalysisResult(
            exerciseType: .shoulderPress,
            overallScore: overallScore,
            identifiedIssues: issues,
            strengths: strengths,
            detailedScores: scores,
            repCount: detectRepCount(poseSequence, exerciseType: .shoulderPress),
            analysisDate: Date()
        )
    }
    
    private func evaluatePullUpForm(_ poseSequence: [PoseKeypoints]) async throws -> FormAnalysisResult {
        // Simplified pull-up evaluation
        let issues: [FormIssue] = []
        let strengths: [FormStrength] = []
        var scores: [String: Double] = [:]
        
        let shoulderAnalysis = analyzeShoulderStability(poseSequence)
        scores["shoulderStability"] = shoulderAnalysis.score
        
        let overallScore = scores["shoulderStability"] ?? 0.5
        
        return FormAnalysisResult(
            exerciseType: .pullUp,
            overallScore: overallScore,
            identifiedIssues: issues,
            strengths: strengths,
            detailedScores: scores,
            repCount: detectRepCount(poseSequence, exerciseType: .pullUp),
            analysisDate: Date()
        )
    }
    
    // MARK: - Analysis Helper Methods
    private func analyzeSquatKneeTracking(_ poseSequence: [PoseKeypoints]) -> FormAnalysisScore {
        var problematicFrames: [Int] = []
        var scores: [Double] = []
        
        for (index, pose) in poseSequence.enumerated() {
            guard let leftKnee = pose.leftKnee,
                  let rightKnee = pose.rightKnee,
                  let leftAnkle = pose.leftAnkle,
                  let rightAnkle = pose.rightAnkle else {
                continue
            }
            
            // Calculate knee-ankle distance ratio
            let leftKneeAnkleDistance = abs(leftKnee.position.x - leftAnkle.position.x)
            let rightKneeAnkleDistance = abs(rightKnee.position.x - rightAnkle.position.x)
            
            // Ideal knee tracking: knees should be roughly over ankles
            let leftScore = max(0.0, 1.0 - (leftKneeAnkleDistance / 50.0)) // 50 pixels tolerance
            let rightScore = max(0.0, 1.0 - (rightKneeAnkleDistance / 50.0))
            
            let frameScore = (leftScore + rightScore) / 2.0
            scores.append(frameScore)
            
            if frameScore < 0.6 {
                problematicFrames.append(index)
            }
        }
        
        let averageScore = scores.isEmpty ? 0.0 : scores.reduce(0, +) / Double(scores.count)
        
        return FormAnalysisScore(
            score: averageScore,
            problematicFrames: problematicFrames
        )
    }
    
    private func analyzeSquatDepth(_ poseSequence: [PoseKeypoints]) -> FormAnalysisScore {
        var problematicFrames: [Int] = []
        var minDepthScore = 1.0
        
        for (index, pose) in poseSequence.enumerated() {
            guard let leftHip = pose.leftHip,
                  let rightHip = pose.rightHip,
                  let leftKnee = pose.leftKnee,
                  let rightKnee = pose.rightKnee else {
                continue
            }
            
            // Calculate hip and knee heights
            let hipHeight = (leftHip.position.y + rightHip.position.y) / 2
            let kneeHeight = (leftKnee.position.y + rightKnee.position.y) / 2
            
            // Ideal squat: hips below knees at bottom
            let depthRatio = hipHeight / kneeHeight
            
            if depthRatio > 1.05 { // Hip significantly above knee
                problematicFrames.append(index)
                minDepthScore = min(minDepthScore, 0.5)
            } else if depthRatio > 0.98 { // Hip slightly above knee
                minDepthScore = min(minDepthScore, 0.7)
            }
        }
        
        return FormAnalysisScore(
            score: minDepthScore,
            problematicFrames: problematicFrames
        )
    }
    
    private func analyzeSpinalAlignment(_ poseSequence: [PoseKeypoints]) -> FormAnalysisScore {
        var problematicFrames: [Int] = []
        var scores: [Double] = []
        
        for (index, pose) in poseSequence.enumerated() {
            guard let _ = pose.neck,
                  let leftShoulder = pose.leftShoulder,
                  let rightShoulder = pose.rightShoulder,
                  let leftHip = pose.leftHip,
                  let rightHip = pose.rightHip else {
                continue
            }
            
            // Calculate spine angle
            let shoulderCenter = CGPoint(
                x: (leftShoulder.position.x + rightShoulder.position.x) / 2,
                y: (leftShoulder.position.y + rightShoulder.position.y) / 2
            )
            
            let hipCenter = CGPoint(
                x: (leftHip.position.x + rightHip.position.x) / 2,
                y: (leftHip.position.y + rightHip.position.y) / 2
            )
            
            // Calculate spine deviation from vertical
            let spineAngle = atan2(
                shoulderCenter.x - hipCenter.x,
                shoulderCenter.y - hipCenter.y
            )
            
            let angleDeviation = abs(spineAngle)
            let score = max(0.0, 1.0 - (angleDeviation / 0.5)) // 0.5 radians tolerance
            
            scores.append(score)
            
            if score < 0.6 {
                problematicFrames.append(index)
            }
        }
        
        let averageScore = scores.isEmpty ? 0.0 : scores.reduce(0, +) / Double(scores.count)
        
        return FormAnalysisScore(
            score: averageScore,
            problematicFrames: problematicFrames
        )
    }
    
    private func analyzeMovementTempo(_ poseSequence: [PoseKeypoints]) -> FormAnalysisScore {
        // Simplified tempo analysis - check for consistent movement speed
        guard poseSequence.count > 3 else {
            return FormAnalysisScore(score: 0.5, problematicFrames: [])
        }
        
        var velocities: [Double] = []
        
        for i in 1..<poseSequence.count {
            guard let currentCenterOfMass = poseSequence[i].centerOfMass,
                  let previousCenterOfMass = poseSequence[i-1].centerOfMass else {
                continue
            }
            
            let distance = sqrt(
                pow(currentCenterOfMass.x - previousCenterOfMass.x, 2) +
                pow(currentCenterOfMass.y - previousCenterOfMass.y, 2)
            )
            
            velocities.append(Double(distance))
        }
        
        guard !velocities.isEmpty else {
            return FormAnalysisScore(score: 0.5, problematicFrames: [])
        }
        
        // Calculate velocity variance (lower is better for consistent tempo)
        let meanVelocity = velocities.reduce(0, +) / Double(velocities.count)
        let variance = velocities.reduce(0) { sum, velocity in
            sum + pow(velocity - meanVelocity, 2)
        } / Double(velocities.count)
        
        let consistencyScore = max(0.0, 1.0 - (sqrt(variance) / 10.0)) // Normalize by expected variance
        
        return FormAnalysisScore(
            score: consistencyScore,
            problematicFrames: []
        )
    }
    
    private func analyzeDeadliftBarPath(_ poseSequence: [PoseKeypoints]) -> FormAnalysisScore {
        // Simplified bar path analysis using wrist position as proxy for bar
        var problematicFrames: [Int] = []
        var scores: [Double] = []
        
        for (index, pose) in poseSequence.enumerated() {
            guard let leftWrist = pose.leftWrist,
                  let rightWrist = pose.rightWrist,
                  let leftAnkle = pose.leftAnkle,
                  let rightAnkle = pose.rightAnkle else {
                continue
            }
            
            let wristCenter = CGPoint(
                x: (leftWrist.position.x + rightWrist.position.x) / 2,
                y: (leftWrist.position.y + rightWrist.position.y) / 2
            )
            
            let ankleCenter = CGPoint(
                x: (leftAnkle.position.x + rightAnkle.position.x) / 2,
                y: (leftAnkle.position.y + rightAnkle.position.y) / 2
            )
            
            // Bar should stay close to vertical line through ankles
            let horizontalDeviation = abs(wristCenter.x - ankleCenter.x)
            let score = max(0.0, 1.0 - (horizontalDeviation / 30.0)) // 30 pixels tolerance
            
            scores.append(score)
            
            if score < 0.6 {
                problematicFrames.append(index)
            }
        }
        
        let averageScore = scores.isEmpty ? 0.0 : scores.reduce(0, +) / Double(scores.count)
        
        return FormAnalysisScore(
            score: averageScore,
            problematicFrames: problematicFrames
        )
    }
    
    private func analyzeHipHingePattern(_ poseSequence: [PoseKeypoints]) -> FormAnalysisScore {
        // Analyze hip hinge by looking at hip angle changes
        var scores: [Double] = []
        
        for pose in poseSequence {
            guard let leftHip = pose.leftHip,
                  let rightHip = pose.rightHip,
                  let leftKnee = pose.leftKnee,
                  let rightKnee = pose.rightKnee else {
                continue
            }
            
            // Calculate hip angle (simplified)
            let hipCenter = CGPoint(
                x: (leftHip.position.x + rightHip.position.x) / 2,
                y: (leftHip.position.y + rightHip.position.y) / 2
            )
            
            let kneeCenter = CGPoint(
                x: (leftKnee.position.x + rightKnee.position.x) / 2,
                y: (leftKnee.position.y + rightKnee.position.y) / 2
            )
            
            // For deadlift, hips should move back as they descend
            let score = hipCenter.y > kneeCenter.y ? 0.8 : 0.5
            scores.append(score)
        }
        
        let averageScore = scores.isEmpty ? 0.0 : scores.reduce(0, +) / Double(scores.count)
        
        return FormAnalysisScore(
            score: averageScore,
            problematicFrames: []
        )
    }
    
    private func analyzeShoulderStability(_ poseSequence: [PoseKeypoints]) -> FormAnalysisScore {
        // Analyze shoulder stability by looking at shoulder position consistency
        var scores: [Double] = []
        
        guard let firstPose = poseSequence.first,
              let firstLeftShoulder = firstPose.leftShoulder,
              let firstRightShoulder = firstPose.rightShoulder else {
            return FormAnalysisScore(score: 0.5, problematicFrames: [])
        }
        
        let referenceShoulderWidth = abs(firstLeftShoulder.position.x - firstRightShoulder.position.x)
        
        for pose in poseSequence {
            guard let leftShoulder = pose.leftShoulder,
                  let rightShoulder = pose.rightShoulder else {
                continue
            }
            
            let currentShoulderWidth = abs(leftShoulder.position.x - rightShoulder.position.x)
            let widthDeviation = abs(currentShoulderWidth - referenceShoulderWidth) / referenceShoulderWidth
            
            let score = max(0.0, 1.0 - widthDeviation * 2.0)
            scores.append(score)
        }
        
        let averageScore = scores.isEmpty ? 0.0 : scores.reduce(0, +) / Double(scores.count)
        
        return FormAnalysisScore(
            score: averageScore,
            problematicFrames: []
        )
    }
    
    private func detectRepCount(_ poseSequence: [PoseKeypoints], exerciseType: ExerciseType) -> Int {
        // Simplified rep counting based on vertical movement patterns
        guard poseSequence.count > 10 else { return 0 }
        
        var peaks: [Int] = []
        var valleys: [Int] = []
        
        let centerOfMassData = poseSequence.compactMap { $0.centerOfMass?.y }
        guard centerOfMassData.count > 10 else { return 0 }
        
        // Find peaks and valleys in vertical movement
        for i in 1..<centerOfMassData.count-1 {
            let current = centerOfMassData[i]
            let previous = centerOfMassData[i-1]
            let next = centerOfMassData[i+1]
            
            if current > previous && current > next {
                peaks.append(i)
            } else if current < previous && current < next {
                valleys.append(i)
            }
        }
        
        // Rep count is approximately the minimum of peaks and valleys
        return min(peaks.count, valleys.count)
    }
    
    // MARK: - Utility Methods
    private func calculateOverallScore(_ scores: [String: Double], weights: [String: Double]) -> Double {
        var weightedSum = 0.0
        var totalWeight = 0.0
        
        for (key, weight) in weights {
            if let score = scores[key] {
                weightedSum += score * weight
                totalWeight += weight
            }
        }
        
        return totalWeight > 0 ? weightedSum / totalWeight : 0.0
    }
    
    private func prioritizeIssues(_ issues: [FormIssue], for userLevel: UserFitnessLevel) -> [FormIssue] {
        return issues.sorted { issue1, issue2 in
            // Prioritize by severity first
            if issue1.severity != issue2.severity {
                return issue1.severity.rawValue > issue2.severity.rawValue
            }
            
            // Then by user level relevance
            switch userLevel {
            case .beginner:
                // Focus on safety issues for beginners
                let safetyIssues: Set<FormIssueType> = [.spinalRounding, .kneeValgus, .improperHipHinge]
                if safetyIssues.contains(issue1.type) && !safetyIssues.contains(issue2.type) {
                    return true
                }
            case .intermediate, .advanced:
                // More focus on efficiency for advanced users
                let efficiencyIssues: Set<FormIssueType> = [.inefficientBarPath, .inconsistentTempo, .insufficientDepth]
                if efficiencyIssues.contains(issue1.type) && !efficiencyIssues.contains(issue2.type) {
                    return true
                }
            }
            
            return false
        }
    }
    
    private func createFeedbackMessage(
        analysis: FormAnalysisResult,
        mainIssue: FormIssue?,
        strengths: [FormStrength],
        userLevel: UserFitnessLevel
    ) -> String {
        var message = ""
        
        // Start with encouragement if there are strengths
        if let strength = strengths.first {
            message += "Great job with your \(strength.description.lowercased())! "
        }
        
        // Add main feedback based on score
        if analysis.overallScore >= 0.8 {
            message += "Your form looks excellent overall. "
        } else if analysis.overallScore >= 0.6 {
            message += "Good form with room for improvement. "
        } else {
            message += "Let's work on improving your form for better results and safety. "
        }
        
        // Add specific issue feedback
        if let issue = mainIssue {
            message += issue.description + ". "
        }
        
        return message.trimmingCharacters(in: .whitespaces)
    }
    
    private func generateCorrections(for issues: ArraySlice<FormIssue>, userLevel: UserFitnessLevel) -> [FormCorrection] {
        return issues.map { issue in
            FormCorrection(
                issue: issue.type,
                instruction: getCorrectiveInstruction(for: issue.type, userLevel: userLevel),
                priority: issue.severity
            )
        }
    }
    
    private func getCorrectiveInstruction(for issueType: FormIssueType, userLevel: UserFitnessLevel) -> String {
        switch issueType {
        case .kneeValgus:
            switch userLevel {
            case .beginner:
                return "Focus on pushing your knees out in the direction of your toes."
            case .intermediate:
                return "Engage your glutes and think about spreading the floor with your feet."
            case .advanced:
                return "Consider hip mobility work and ensure proper glute activation before lifting."
            }
        case .spinalRounding:
            switch userLevel {
            case .beginner:
                return "Keep your chest up and shoulders back throughout the movement."
            case .intermediate:
                return "Engage your core and maintain a neutral spine position."
            case .advanced:
                return "Focus on thoracic extension and lat engagement to maintain spinal integrity."
            }
        case .insufficientDepth:
            return "Try to lower until your hip crease is just below your knee level."
        case .inefficientBarPath:
            return "Keep the bar close to your body throughout the entire movement."
        case .improperHipHinge:
            return "Initiate the movement by pushing your hips back, not bending your knees first."
        case .inconsistentTempo:
            return "Maintain a controlled, steady pace throughout each repetition."
        }
    }
}

// MARK: - Supporting Data Models
struct FormAnalysisResult {
    let exerciseType: ExerciseType
    let overallScore: Double
    let identifiedIssues: [FormIssue]
    let strengths: [FormStrength]
    let detailedScores: [String: Double]
    let repCount: Int
    let analysisDate: Date
}

struct FormFeedback {
    let overallScore: Double
    let mainFeedback: String
    let specificCorrections: [FormCorrection]
    let strengths: [FormStrength]
    let exerciseType: ExerciseType
    let userLevel: UserFitnessLevel
    let priority: FormIssueSeverity
}

struct FormIssue {
    let type: FormIssueType
    let severity: FormIssueSeverity
    let description: String
    let affectedFrames: [Int]
}

struct FormStrength {
    let type: FormStrengthType
    let description: String
}

struct FormCorrection {
    let issue: FormIssueType
    let instruction: String
    let priority: FormIssueSeverity
}

struct FormAnalysisScore {
    let score: Double
    let problematicFrames: [Int]
}

enum FormIssueType {
    case kneeValgus
    case spinalRounding
    case insufficientDepth
    case inefficientBarPath
    case improperHipHinge
    case inconsistentTempo
}

enum FormStrengthType {
    case kneeTracking
    case spinalAlignment
    case depth
    case barPath
    case shoulderStability
}

enum FormIssueSeverity: Int {
    case low = 1
    case medium = 2
    case high = 3
}

enum UserFitnessLevel {
    case beginner
    case intermediate
    case advanced
}

enum FormEvaluationError: LocalizedError {
    case noPoseData
    case unsupportedExercise(ExerciseType)
    case analysisIncomplete
    
    var errorDescription: String? {
        switch self {
        case .noPoseData:
            return "No pose data available for analysis."
        case .unsupportedExercise(let type):
            return "Exercise type \(type.rawValue) is not supported yet."
        case .analysisIncomplete:
            return "Form analysis could not be completed."
        }
    }
}
