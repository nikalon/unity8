/*
 * Copyright 2014 Canonical Ltd.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 *
 * Authors: Michael Zanetti <michael.zanetti@canonical.com>
*/

import QtQuick 2.0
import Utils 0.1
import Ubuntu.Components 0.1

SpreadDelegate {
    id: root

    property bool selected: false
    property bool otherSelected: false

    property real progress: 0
    property real animatedProgress: 0

    property real startAngle: 0
    property real endAngle: 0

    property real startScale: 1
    property real endScale: 1

    // Specific to just one tile
    property real tile1StartScale: startScale + .4
    property real tile0SnapAngle: 10

    property real startDistance: units.gu(5)
    property real endDistance: units.gu(.5)

    onSelectedChanged: {
        if (selected) {
            priv.snapshot();
        }
        priv.isSelected = selected;
    }

    onOtherSelectedChanged: {
        if (otherSelected) {
            priv.snapshot();
        }
        priv.otherSelected = otherSelected;
    }

    Connections {
        target: spreadView
        onPhaseChanged: {
            if (spreadView.phase == 1) {
                if (index == 0) {
                    priv.phase2startTranslate = priv.easingAnimation(0, spreadView.positionMarker4, 0, -spreadView.width, spreadView.positionMarker4) + spreadView.width;
                    priv.phase2startAngle = priv.easingAnimation(0, spreadView.positionMarker4, root.startAngle, root.endAngle, spreadView.positionMarker4);
                    priv.phase2startScale = priv.easingAnimation(0, spreadView.positionMarker4, root.startScale, root.endScale, spreadView.positionMarker4);
                    priv.phase2startTopMarginProgress = priv.easingAnimation(0, 1, 0, 1, spreadView.positionMarker4);
                } else if (index == 1) {
                    // find where the main easing for Tile 1 would be when reaching phase 2
                    var phase2Progress = spreadView.positionMarker4 - spreadView.tileDistance / spreadView.width;
                    priv.phase2startTranslate = priv.easingAnimation(0, phase2Progress, 0, -spreadView.width + root.endDistance, phase2Progress);
                    priv.phase2startAngle = priv.easingAnimation(0, phase2Progress, root.startAngle, root.endAngle, phase2Progress);
                    priv.phase2startScale = priv.easingAnimation(0, phase2Progress, root.startScale, root.endScale, phase2Progress);
                    priv.phase2startTopMarginProgress = priv.easingAnimation(0, 1, 0, spreadView.positionMarker4, phase2Progress);
                }
            }
        }
    }

    QtObject {
        id: priv
        property bool isSelected: false
        property bool otherSelected: false
        property real selectedProgress
        property real selectedXTranslate
        property real selectedAngle
        property real selectedScale
        property real selectedOpacity
        property real selectedTopMarginProgress

        // Those values are needed as target values for the end of phase 1.
        // As they are static values, lets caluclate them once when entering phase 1 instead of calculating them in each animation pass.
        property real phase2startTranslate
        property real phase2startAngle
        property real phase2startScale
        property real phase2startTopMarginProgress

        function snapshot() {
            selectedProgress = root.progress;
            selectedXTranslate = xTranslate;
            selectedAngle = angle;
            selectedScale = scale;
            selectedOpacity = opacity;
            selectedTopMarginProgress = topMarginProgress;
            if (index == 1) print("snapshotting values:", selectedProgress, selectedXTranslate, selectedAngle, selectedScale, selectedOpacity, selectedTopMarginProgress)
        }

        property real negativeProgress: {
            if (index == 1 && spreadView.phase < 2) {
                return 0;
            }
            return -index * spreadView.tileDistance / spreadView.width;
        }

        function linearAnimation(startProgress, endProgress, startValue, endValue, progress) {
            // progress : progressDiff = value : valueDiff => value = progress * valueDiff / progressDiff
            return (progress - startProgress) * (endValue - startValue) / (endProgress - startProgress) + startValue;
        }

        function easingAnimation(startProgress, endProgress, startValue, endValue, progress) {
            helperEasingCurve.progress = progress - startProgress;
            helperEasingCurve.period = endProgress - startProgress;
            return helperEasingCurve.value * (endValue - startValue) + startValue;
        }

        property real animatedEndDistance: linearAnimation(0, 2, root.endDistance, 0, root.progress)

        property real xTranslate: {
            if (otherSelected) {
                if (spreadView.phase < 2 && index == 0) {
                    return linearAnimation(selectedProgress, negativeProgress, selectedXTranslate, selectedXTranslate - spreadView.tileDistance, root.progress);
                }

                return selectedXTranslate;
            }

            switch (index) {
            case 0:
                if (spreadView.phase == 0) {
                    return Math.min(0, linearAnimation(0, spreadView.positionMarker2,
                                                       0, -spreadView.width * .25, root.animatedProgress));
                } else if (spreadView.phase == 1){
                    return linearAnimation(spreadView.positionMarker2, spreadView.positionMarker4,
                                           -spreadView.width * .25, priv.phase2startTranslate, root.progress);
                } else if (!priv.isSelected){ // phase 2
                    // Apply the same animation as with the rest but add spreadView.width to align it with the others.
                    return -easingCurve.value * spreadView.width + spreadView.width;
                } else if (priv.isSelected) {
                    return linearAnimation(selectedProgress, negativeProgress, selectedXTranslate, 0, root.progress);
                }

            case 1:
                if (spreadView.phase == 0 && !priv.isSelected) {
                    return linearAnimation(0, spreadView.positionMarker2,
                                           0, -spreadView.width * spreadView.snapPosition, root.animatedProgress);
                } else if (spreadView.phase == 1 && !priv.isSelected) {
                    return linearAnimation(spreadView.positionMarker2, spreadView.positionMarker4,
                                           -spreadView.width * spreadView.snapPosition, priv.phase2startTranslate,
                                           root.progress);
                }
            }

            if (priv.isSelected) {
                // Distance to left edge
                var targetTranslate = -spreadView.width - ((index - 1) * root.startDistance);
                return linearAnimation(selectedProgress, negativeProgress,
                                       selectedXTranslate, targetTranslate, root.progress);
            }

            // Fix it at the right edge...
            var rightEdgeOffset =  -((index - 1) * root.startDistance);
            // ...and use our easing to move them to the left. Stop a bit earlier for each tile
            return -easingCurve.value * spreadView.width + (index * animatedEndDistance) + rightEdgeOffset;

        }

        property real angle: {
            if (priv.otherSelected) {
                return priv.selectedAngle;
            }
            if (priv.isSelected) {
                return linearAnimation(selectedProgress, negativeProgress, selectedAngle, 0, root.progress);
            }
            switch (index) {
            case 0:
                if (spreadView.phase == 0) {
                    return Math.max(0, linearAnimation(0, spreadView.positionMarker2,
                                                       0, root.tile0SnapAngle, root.animatedProgress));
                } else if (spreadView.phase == 1) {
                    return linearAnimation(spreadView.positionMarker2, spreadView.positionMarker4,
                                           root.tile0SnapAngle, phase2startAngle, root.progress);
                }
            case 1:
                if (spreadView.phase == 0) {
                    return linearAnimation(0, spreadView.positionMarker2, root.startAngle,
                                           root.startAngle * (1-spreadView.snapPosition), root.animatedProgress);
                } else if (spreadView.phase == 1) {
                    return linearAnimation(spreadView.positionMarker2, spreadView.positionMarker4,
                                           root.startAngle * (1-spreadView.snapPosition), priv.phase2startAngle,
                                           root.progress);
                }
            }
            return root.startAngle - easingCurve.value * (root.startAngle - root.endAngle);
        }

        property real scale: {
            if (priv.otherSelected) {
                return priv.selectedScale;
            }
            if (priv.isSelected) {
                return linearAnimation(selectedProgress, negativeProgress, selectedScale, 1, root.progress);
            }

            switch (index) {
            case 0:
                if (spreadView.phase == 0) {
                    return 1;
                } else if(spreadView.phase == 1) {
                    return linearAnimation(spreadView.positionMarker2, spreadView.positionMarker4,
                                           1, phase2startScale, root.progress);
                }
            case 1:
                if (spreadView.phase == 0) {
                    var targetScale = tile1StartScale - ((tile1StartScale - 1) * spreadView.snapPosition);
                    return linearAnimation(0, spreadView.positionMarker2,
                                           root.tile1StartScale, targetScale, root.animatedProgress);
                } else if (spreadView.phase == 1) {
                    var startScale = tile1StartScale - ((tile1StartScale - 1) * spreadView.snapPosition);
                    return linearAnimation(spreadView.positionMarker2, spreadView.positionMarker4,
                                           startScale, priv.phase2startScale, root.progress);
                }
            }
            return root.startScale - easingCurve.value * (root.startScale - root.endScale);
        }

        property real opacity: {
            if (priv.otherSelected) {
                return linearAnimation (selectedProgress, Math.max(0, selectedProgress - .5),
                                        selectedOpacity, 0, root.progress);
            }
            if (index == 0) {
                switch (spreadView.phase) {
                case 0:
                    return linearAnimation(0, spreadView.positionMarker2, 1, .3, root.animatedProgress);
                case 1:
                    return linearAnimation(spreadView.positionMarker2, spreadView.positionMarker4,
                                           .3, 1, root.animatedProgress);
                }
            }

            return 1;
        }

        property real topMarginProgress: {
            if (priv.isSelected) {
                return linearAnimation(selectedProgress, negativeProgress, selectedTopMarginProgress, 0, root.progress);
            }

            switch (index) {
            case 0:
                if (spreadView.phase == 0) {
                    return 0;
                } else if (spreadView.phase == 1) {
                    return linearAnimation(spreadView.positionMarker2, spreadView.positionMarker4,
                                           0, priv.phase2startTopMarginProgress, root.progress);
                }
                break;
            case 1:
                if (spreadView.phase == 0) {
                    return 0;
                } else if (spreadView.phase == 1) {
                    return linearAnimation(spreadView.positionMarker2, spreadView.positionMarker4,
                                           0, priv.phase2startTopMarginProgress, root.progress);
                }
            }

            return easingCurve.value;
        }
    }

    transform: [
        Rotation {
            origin { x: 0; y: spreadView.height / 2 }
            axis { x: 0; y: 1; z: 0 }
            angle: priv.angle
        },
        Scale {
            origin { x: 0; y: spreadView.height / 2 }
            xScale: priv.scale
            yScale: xScale
        },
        Translate {
            x: priv.xTranslate
        }
    ]
    opacity: priv.opacity
    topMarginProgress: priv.topMarginProgress

    EasingCurve {
        id: easingCurve
        type: EasingCurve.OutSine
        period: 1 - spreadView.positionMarker2
        progress: root.animatedProgress
    }

    // This is used as a calculation helper to figure values for progress other than the current one
    // Do not bind anything to this...
    EasingCurve {
        id: helperEasingCurve
        type: easingCurve.type
        period: easingCurve.period
    }
}
