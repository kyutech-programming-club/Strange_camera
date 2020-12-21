/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Implementation details of a view that visualizes the detected poses.
*/

import UIKit

@IBDesignable
class PoseImageView: UIImageView {

    /// A data structure used to describe a visual connection between two joints.
    struct JointSegment {
        let jointA: Joint.Name
        let jointB: Joint.Name
    }

    /// An array of joint-pairs that define the lines of a pose's wireframe drawing.
    static let jointSegments = [
        // The connected joints that are on the left side of the body.
        JointSegment(jointA: .leftHip, jointB: .leftShoulder),
        JointSegment(jointA: .leftShoulder, jointB: .leftElbow),
        JointSegment(jointA: .leftElbow, jointB: .leftWrist),
        JointSegment(jointA: .leftHip, jointB: .leftKnee),
        JointSegment(jointA: .leftKnee, jointB: .leftAnkle),
        // The connected joints that are on the right side of the body.
        JointSegment(jointA: .rightHip, jointB: .rightShoulder),
        JointSegment(jointA: .rightShoulder, jointB: .rightElbow),
        JointSegment(jointA: .rightElbow, jointB: .rightWrist),
        JointSegment(jointA: .rightHip, jointB: .rightKnee),
        JointSegment(jointA: .rightKnee, jointB: .rightAnkle),
        // The connected joints that cross over the body.
        JointSegment(jointA: .leftShoulder, jointB: .rightShoulder),
        JointSegment(jointA: .leftHip, jointB: .rightHip)
    ]

    /// The width of the line connecting two joints.
    @IBInspectable var segmentLineWidth: CGFloat = 2
    /// The color of the line connecting two joints.
    @IBInspectable var segmentColor: UIColor = UIColor.systemTeal
    /// The radius of the circles drawn for each joint.
    @IBInspectable var jointRadius: CGFloat = 4
    /// The color of the circles drawn for each joint.
    @IBInspectable var jointColor: UIColor = UIColor.systemPink

    // MARK: - Rendering methods

    /// Returns an image showing the detected poses.
    ///
    /// - parameters:
    ///     - poses: An array of detected poses.
    ///     - frame: The image used to detect the poses and used as the background for the returned image.
    func show(poses: [Pose], on frame: CGImage, isOk: Bool) {
        let dstImageSize = CGSize(width: frame.width, height: frame.height)
        let dstImageFormat = UIGraphicsImageRendererFormat()
        // 画像インスタンス用
        let imageJojo = UIImageView()

        dstImageFormat.scale = 1
        let renderer = UIGraphicsImageRenderer(size: dstImageSize,
                                               format: dstImageFormat)

        let dstImage = renderer.image { rendererContext in
            // Draw the current frame as the background for the new image.
            draw(image: frame, in: rendererContext.cgContext)
            if isOk == false {
                for pose in poses {
                    // Draw the segment lines.
                    for segment in PoseImageView.jointSegments {
                        let jointA = pose[segment.jointA]
                        let jointB = pose[segment.jointB]

                        guard jointA.isValid, jointB.isValid else {
                            continue
                        }

                        drawLine(from: jointA,
                                 to: jointB,
                                 in: rendererContext.cgContext)
                    }

                    // Draw the joints as circles above the segment lines.
                    for joint in pose.joints.values.filter({ $0.isValid }) {
                        draw(circle: joint, in: rendererContext.cgContext)
                    }
                }
            } else {
                print("文字が表示されるううううーーーーーー")
            }
        }

        image = dstImage
        
        if isOk == true {
            // 画像を読み込んで、準備しておいたimageSampleに設定
            imageJojo.image = UIImage(named: "baba-n")
            // 画像のフレームを設定
            imageJojo.frame = CGRect(x:0, y:0, width:dstImageSize.width * 2 / 3, height:dstImageSize.height * 2 / 3)

            // 画像を中央に設定
            imageJojo.center = CGPoint(x:dstImageSize.width/2, y:dstImageSize.height / 3)

            // 設定した画像をスクリーンに表示する
            self.addSubview(imageJojo)
//
//             画像を真ん中に重ねる
//            let rect = CGRect(x: dstImageSize.width/2,
//                y: dstImageSize.height/2,
//                width: dstImageSize.width,
//                height: dstImageSize.height)
//
//            imageJojo.image!.draw(in: rect)
//
            
            UIImageWriteToSavedPhotosAlbum(image!, nil, nil, nil)
        }
    }

    /// Vertically flips and draws the given image.
    ///
    /// - parameters:
    ///     - image: The image to draw onto the context (vertically flipped).
    ///     - cgContext: The rendering context.
    func draw(image: CGImage, in cgContext: CGContext) {
        cgContext.saveGState()
        // The given image is assumed to be upside down; therefore, the context
        // is flipped before rendering the image.
        cgContext.scaleBy(x: 1.0, y: -1.0)
        // Render the image, adjusting for the scale transformation performed above.
        let drawingRect = CGRect(x: 0, y: -image.height, width: image.width, height: image.height)
        cgContext.draw(image, in: drawingRect)
        cgContext.restoreGState()
    }

    /// Draws a line between two joints.
    ///
    /// - parameters:
    ///     - parentJoint: A valid joint whose position is used as the start position of the line.
    ///     - childJoint: A valid joint whose position is used as the end of the line.
    ///     - cgContext: The rendering context.
    func drawLine(from parentJoint: Joint,
                  to childJoint: Joint,
                  in cgContext: CGContext) {
        cgContext.setStrokeColor(segmentColor.cgColor)
        cgContext.setLineWidth(segmentLineWidth)

        cgContext.move(to: parentJoint.position)
        cgContext.addLine(to: childJoint.position)
        cgContext.strokePath()
    }

    /// Draw a circle in the location of the given joint.
    ///
    /// - parameters:
    ///     - circle: A valid joint whose position is used as the circle's center.
    ///     - cgContext: The rendering context.
    private func draw(circle joint: Joint, in cgContext: CGContext) {
        cgContext.setFillColor(jointColor.cgColor)

        let rectangle = CGRect(x: joint.position.x - jointRadius, y: joint.position.y - jointRadius,
                               width: jointRadius * 2, height: jointRadius * 2)
        cgContext.addEllipse(in: rectangle)
        cgContext.drawPath(using: .fill)
    }
    
    func sortPose(poseList: [[String]]) -> [[String]] {
        let partBody: [String] = ["rightKnee", "rightAnkle", "rightShoulder", "rightHip", "rightWrist", "rightEar", "rightEye", "rightElbow", "leftKnee", "leftAnkle", "leftShoulder", "leftHip", "leftWrist", "leftEar", "leftEye", "leftElbow", "nose"]
        var sortList = [[String]](repeating: [String](repeating: "0", count: 3), count: 17)
        
        for pose in poseList {
            let index: Int = partBody.firstIndex(of: String("\(pose[0])"))!
            sortList[index] = pose
        }
        
        return sortList
    }
    
    func isJojo1(sortList: [[String]]) -> Bool {
        let rightAnkleX: Double = Double(sortList[1][1]) ?? 0.0
        let rightWristX: Double = Double(sortList[4][1]) ?? 0.0
        let rightWristY: Double = Double(sortList[4][2]) ?? 0.0
        let rightElbowX: Double = Double(sortList[7][1]) ?? 0.0
        let rightElbowY: Double = Double(sortList[7][2]) ?? 0.0
        let leftAnkleX: Double = Double(sortList[9][1]) ?? 0.0
        let leftShoulderX: Double = Double(sortList[10][1]) ?? 0.0
        let leftShoulderY: Double = Double(sortList[10][2]) ?? 0.0
        let leftWristX: Double = Double(sortList[12][1]) ?? 0.0
        let leftWristY: Double = Double(sortList[12][2]) ?? 0.0
        let leftElbowX: Double = Double(sortList[15][1]) ?? 0.0
        let leftElbowY: Double = Double(sortList[15][2]) ?? 0.0
        
        if rightAnkleX == 0.0 || leftElbowX == 0.0 || leftWristY == 0.0 || rightElbowY == 0.0 {
            return false
        }
        
        if rightAnkleX < rightWristX && rightWristX < rightElbowX {
            if leftElbowX < leftWristX && leftWristX < leftShoulderX && leftShoulderX < leftAnkleX {
                if leftWristY < leftShoulderY && leftShoulderY < leftElbowY {
                    if rightElbowY < rightWristY {
                        return true
                    }
                }
            }
        }
        return false
    }
//スタンド使いを判定する関数
    // 原点は左上
    func isStand(poseList: [[String]]) -> Bool {
        let sortList: [[String]] = sortPose(poseList: poseList)
        
        return isJojo1(sortList: sortList)
    }
    
    func toruyo(isOk: Bool) {
        if isOk == true {
            print("発火")
        } else {
            print("non")
        }
    }
}
