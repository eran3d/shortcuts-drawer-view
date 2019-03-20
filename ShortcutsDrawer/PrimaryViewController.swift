//
//  ViewController.swift
//  ShortcutsDrawer
//
//  Created by Phill Farrugia on 10/16/18.
//  Copyright © 2018 Phill Farrugia. All rights reserved.
//

import UIKit

/// A View Controller which is the primary view controller
/// that contains a child view controller that interacts like a
/// drawer overlay and enables selection of secondary options.
class PrimaryViewController: UIViewController, DrawerViewControllerDelegate {

    /// Container View Top Constraint
    @IBOutlet private weak var containerViewTopConstraint: NSLayoutConstraint!

    /// Container View Bottom Constraint
    @IBOutlet private weak var containerViewBottomConstraint: NSLayoutConstraint!

    /// Previous Container View Top Constraint
    private var previousContainerViewConstant: CGFloat = 0.0
    
    /// Background Overlay View
    @IBOutlet private weak var backgroundColorOverlayView: UIView!

    /// Background Overlay Alpha
    private static let kBackgroundColorOverlayTargetAlpha: CGFloat = 0.4

    // MARK: - Configuration

    override func viewDidLoad() {
        super.viewDidLoad()

        configureAppearance()
        configureDrawerViewController()
    }

    private func configureAppearance() {
        backgroundColorOverlayView.alpha = 0.0
    }

    private func configureDrawerViewController() {

        // Set initial state
        if self.traitCollection.horizontalSizeClass == .regular && self.traitCollection.verticalSizeClass == .regular {
            let fullHeight = ExpansionState.height(forState: .fullHeight, inContainer: view.bounds)
            let fullBottomConstraint = view.bounds.height - fullHeight
            containerViewBottomConstraint.constant = fullBottomConstraint
            previousContainerViewConstant = containerViewBottomConstraint.constant

        } else {
            let compressedHeight = ExpansionState.height(forState: .compressed, inContainer: view.bounds)
            let compressedTopConstraint = view.bounds.height - compressedHeight
            containerViewTopConstraint.constant = compressedTopConstraint
            previousContainerViewConstant = containerViewTopConstraint.constant
        }

        // NB: Handle this in a more clean and production ready fashion.
        if let drawerViewController = children.first as? DrawerViewController {
            drawerViewController.delegate = self
        }
    }

    // MARK: - DrawerViewControllerDelegate

    func drawerViewController(_ drawerViewController: DrawerViewController,
                              didChangeTranslationPoint translationPoint: CGPoint,
                              withVelocity velocity: CGPoint) {
        /// Disable selection on drawerViewController's content while translating it.
        drawerViewController.view.isUserInteractionEnabled = false

        if self.traitCollection.horizontalSizeClass == .regular && self.traitCollection.verticalSizeClass == .regular {
            let newConstraintConstant = previousContainerViewConstant - translationPoint.y
            let fullHeight = ExpansionState.height(forState: .fullHeight, inContainer: view.bounds)
            let fullHeightBottomConstraint = -(view.bounds.height - fullHeight)
            let constraintPadding: CGFloat = 50.0

            /// Limit the user from translating the drawer too far to the bottom
            if (newConstraintConstant >= fullHeightBottomConstraint + constraintPadding/2) {
                containerViewBottomConstraint.constant = newConstraintConstant
            }

        } else {
            let newConstraintConstant = previousContainerViewConstant + translationPoint.y
            let fullHeight = ExpansionState.height(forState: .fullHeight, inContainer: view.bounds)
            let fullHeightTopConstraint = view.bounds.height - fullHeight
            let constraintPadding: CGFloat = 50.0

            /// Limit the user from translating the drawer too far to the top
            if (newConstraintConstant >= fullHeightTopConstraint - constraintPadding/2) {
                containerViewTopConstraint.constant = newConstraintConstant
                animateBackgroundFade(withCurrentTopConstraint: newConstraintConstant)
            }
        }


    }

    /// Animates the top constraint of the drawerViewController by a given constant
    /// using velocity to calculate a spring and damping animation effect.
    private func animateConstraint(constant: CGFloat, withVelocity velocity: CGPoint) {

        if self.traitCollection.horizontalSizeClass == .regular && self.traitCollection.verticalSizeClass == .regular {
            let previousConstraint = containerViewBottomConstraint.constant
            let distance = previousConstraint - constant
            let springVelocity = max(1 / (abs(velocity.y / distance)), 0.08)
            let springDampening = CGFloat(0.6)

            UIView.animate(withDuration: 0.5,
                           delay: 0.0,
                           usingSpringWithDamping: springDampening,
                           initialSpringVelocity: springVelocity,
                           options: [.curveLinear],
                           animations: {
                            self.containerViewBottomConstraint.constant = constant
                            self.previousContainerViewConstant = constant
                            self.view.layoutIfNeeded()
            })
        } else {
            let previousConstraint = containerViewTopConstraint.constant
            let distance = previousConstraint - constant
            let springVelocity = max(1 / (abs(velocity.y / distance)), 0.08)
            let springDampening = CGFloat(0.6)

            UIView.animate(withDuration: 0.5,
                           delay: 0.0,
                           usingSpringWithDamping: springDampening,
                           initialSpringVelocity: springVelocity,
                           options: [.curveLinear],
                           animations: {
                            self.containerViewTopConstraint.constant = constant
                            self.previousContainerViewConstant = constant
                            self.animateBackgroundFade(withCurrentTopConstraint: constant)
                            self.view.layoutIfNeeded()
            })
        }
    }

    /// Animates the alpha of the `backgroundColorOverlayView` based on the progress of the
    /// translation of the drawer between the expansion state and the fullHeight state.
    private func animateBackgroundFade(withCurrentTopConstraint currentTopConstraint: CGFloat) {
        let expandedHeight = ExpansionState.height(forState: .expanded, inContainer: view.bounds)
        let fullHeight = ExpansionState.height(forState: .fullHeight, inContainer: view.bounds)
        let expandedTopConstraint = view.bounds.height - expandedHeight
        let fullHeightTopConstraint = view.bounds.height - fullHeight

        let totalDistance = (expandedTopConstraint - fullHeightTopConstraint)
        let currentDistance = (expandedTopConstraint - currentTopConstraint)
        var progress = currentDistance / totalDistance

        progress = max(0.0, progress)
        progress = min(PrimaryViewController.kBackgroundColorOverlayTargetAlpha, progress)
        backgroundColorOverlayView.alpha = progress
    }

    func drawerViewController(_ drawerViewController: DrawerViewController,
                              didEndTranslationPoint translationPoint: CGPoint,
                              withVelocity velocity: CGPoint) {
        let compressedHeight = ExpansionState.height(forState: .compressed, inContainer: view.bounds)
        let expandedHeight = ExpansionState.height(forState: .expanded, inContainer: view.bounds)
        let fullHeight = ExpansionState.height(forState: .fullHeight, inContainer: view.bounds)
        let compressedConstraint = view.bounds.height - compressedHeight
        let expandedConstraint = view.bounds.height - expandedHeight
        let fullHeightConstraint = view.bounds.height - fullHeight
        let constraintPadding: CGFloat = 50.0
        let velocityThreshold: CGFloat = 200.0
        drawerViewController.view.isUserInteractionEnabled = true

        let releaseValue = containerViewBottomConstraint.constant

        if self.traitCollection.horizontalSizeClass == .regular && self.traitCollection.verticalSizeClass == .regular {

            if abs(velocity.y) > velocityThreshold {
                // Handle High Velocity Pan Gesture
                if previousContainerViewConstant == fullHeightConstraint {
                    if containerViewBottomConstraint.constant <= expandedConstraint - constraintPadding {
                        // From Full Height to Expanded
                        drawerViewController.expansionState = .expanded
                        animateConstraint(constant: expandedConstraint, withVelocity: velocity)
                    } else {
                        // From Full Height to Compressed
                        drawerViewController.expansionState = .compressed
                        animateConstraint(constant: compressedConstraint, withVelocity: velocity)
                    }
                } else if previousContainerViewConstant == expandedConstraint {
                    if containerViewBottomConstraint.constant <= expandedConstraint - constraintPadding {
                        // From Expanded to Full Height
                        drawerViewController.expansionState = .fullHeight
                        animateConstraint(constant: fullHeightConstraint, withVelocity: velocity)
                    } else {
                        // From Expanded to Compressed
                        drawerViewController.expansionState = .compressed
                        animateConstraint(constant: compressedConstraint, withVelocity: velocity)
                    }
                } else {
                    if containerViewBottomConstraint.constant <= expandedConstraint - constraintPadding {
                        // From Compressed to Full Height
                        drawerViewController.expansionState = .fullHeight
                        animateConstraint(constant: fullHeightConstraint, withVelocity: velocity)
                    } else {
                        // From Compressed back to Compressed
                        drawerViewController.expansionState = .expanded
                        animateConstraint(constant: expandedConstraint, withVelocity: velocity)
                    }
                }
            } else {
                // Handle Low Velocity Pan Gesture
                // Snap to nearest state after releasing Drag
                let snapToCompressedThreshold = (expandedConstraint + compressedConstraint) / 2
                let snapToFullHeightThreshold = (expandedConstraint + fullHeightConstraint) / 2

                if releaseValue > snapToCompressedThreshold {
                    print("snap to compressed")
                    drawerViewController.expansionState = .compressed
                    animateConstraint(constant: compressedConstraint, withVelocity: velocity)
                } else if releaseValue < snapToFullHeightThreshold {
                    print("snap to full height")
                    drawerViewController.expansionState = .fullHeight
                    animateConstraint(constant: fullHeightConstraint, withVelocity: velocity)
                } else {
                    print("snap to expanded")
                    drawerViewController.expansionState = .expanded
                    animateConstraint(constant: expandedConstraint, withVelocity: velocity)
                }

                print(releaseValue)

//                print(containerViewBottomConstraint.constant)
//                if containerViewBottomConstraint.constant >= compressedConstraint - constraintPadding {
//                    drawerViewController.expansionState = .compressed
//                    animateConstraint(constant: compressedConstraint, withVelocity: velocity)
//                } else if containerViewBottomConstraint.constant < compressedConstraint - constraintPadding && containerViewBottomConstraint.constant > expandedConstraint - constraintPadding {
//                    drawerViewController.expansionState = .expanded
//                    animateConstraint(constant: compressedConstraint, withVelocity: velocity)
//                }
//                if containerViewBottomConstraint.constant >= expandedConstraint - constraintPadding {
//                    // Animate to the full height top constraint with velocity
//                    drawerViewController.expansionState = .fullHeight
//                    animateConstraint(constant: fullHeightConstraint, withVelocity: velocity)
//                } else if containerViewBottomConstraint.constant > compressedConstraint - constraintPadding {
//                    // Animate to the expanded top constraint with velocity
//                    drawerViewController.expansionState = .expanded
//                    animateConstraint(constant: expandedConstraint, withVelocity: velocity)
//                } else {
//                    // Animate to the compressed top constraint with velocity
//                    drawerViewController.expansionState = .compressed
//                    animateConstraint(constant: compressedConstraint, withVelocity: velocity)
//                }
            }
        } else {
            if velocity.y > velocityThreshold {
                // Handle High Velocity Pan Gesture
                if previousContainerViewConstant == fullHeightConstraint {
                    if containerViewTopConstraint.constant <= expandedConstraint - constraintPadding {
                        // From Full Height to Expanded
                        drawerViewController.expansionState = .expanded
                        animateConstraint(constant: expandedConstraint, withVelocity: velocity)
                    } else {
                        // From Full Height to Compressed
                        drawerViewController.expansionState = .compressed
                        animateConstraint(constant: compressedConstraint, withVelocity: velocity)
                    }
                } else if previousContainerViewConstant == expandedConstraint {
                    if containerViewTopConstraint.constant <= expandedConstraint - constraintPadding {
                        // From Expanded to Full Height
                        drawerViewController.expansionState = .fullHeight
                        animateConstraint(constant: fullHeightConstraint, withVelocity: velocity)
                    } else {
                        // From Expanded to Compressed
                        drawerViewController.expansionState = .compressed
                        animateConstraint(constant: compressedConstraint, withVelocity: velocity)
                    }
                } else {
                    if containerViewTopConstraint.constant <= expandedConstraint - constraintPadding {
                        // From Compressed to Full Height
                        drawerViewController.expansionState = .fullHeight
                        animateConstraint(constant: fullHeightConstraint, withVelocity: velocity)
                    } else {
                        // From Compressed back to Compressed
                        drawerViewController.expansionState = .compressed
                        animateConstraint(constant: compressedConstraint, withVelocity: velocity)
                    }
                }
            } else {
                // Handle Low Velocity Pan Gesture
                if containerViewTopConstraint.constant <= expandedConstraint - constraintPadding {
                    // Animate to the full height top constraint with velocity
                    drawerViewController.expansionState = .fullHeight
                    animateConstraint(constant: fullHeightConstraint, withVelocity: velocity)
                } else if containerViewTopConstraint.constant < compressedConstraint - constraintPadding {
                    // Animate to the expanded top constraint with velocity
                    drawerViewController.expansionState = .expanded
                    animateConstraint(constant: expandedConstraint, withVelocity: velocity)
                } else {
                    // Animate to the compressed top constraint with velocity
                    drawerViewController.expansionState = .compressed
                    animateConstraint(constant: compressedConstraint, withVelocity: velocity)
                }
            }
        }
    }

    func drawerViewController(_ drawerViewController: DrawerViewController,
                              didChangeExpansionState expansionState: ExpansionState) {
        /// User tapped on the search bar, animate to FullHeight (NB: Abandoned this as it's not important to the demo,
        /// but it could be animated better and add support for dismissing the keyboard).
        let fullHeight = ExpansionState.height(forState: .fullHeight, inContainer: view.bounds)
        let fullHeightTopConstraint = view.bounds.height - fullHeight
        animateConstraint(constant: fullHeightTopConstraint, withVelocity: CGPoint(x: 0, y: -4536))
    }

}

