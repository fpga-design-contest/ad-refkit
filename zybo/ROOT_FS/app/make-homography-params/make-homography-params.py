#  make-calibration-param:
#
#  Copyright (C) 2019 Yuya Kudo.
#  Copyright (C) 2019 Atsushi Takada.
#  Authors:
#      Yuya Kudo      <ri0049ee@ed.ritsumei.ac.jp>
#      Atsushi Takada <ri0051rr@ed.ritsumei.ac.jp>
#

import cv2
import yaml
import time
import numpy as np
import math
import sys

class mouseParam:
    def __init__(self, input_img_name):
        self.mouseEvent = {"x":None, "y":None, "event":None, "flags":None}
        cv2.setMouseCallback(input_img_name, self.__CallBackFunc, None)

    def __CallBackFunc(self, eventType, x, y, flags, userdata):
        self.mouseEvent["x"] = x
        self.mouseEvent["y"] = y
        self.mouseEvent["event"] = eventType
        self.mouseEvent["flags"] = flags

    def getData(self):
        return self.mouseEvent

    def getEvent(self):
        return self.mouseEvent["event"]

    def getFlags(self):
        return self.mouseEvent["flags"]

    def getX(self):
        return self.mouseEvent["x"]

    def getY(self):
        return self.mouseEvent["y"]

    def getPos(self):
        return (self.mouseEvent["x"], self.mouseEvent["y"])

    def getPosNP(self):
        return [self.mouseEvent["x"], self.mouseEvent["y"]]

def set_dst_pt(img_witdh, img_height, pt_ratio, x_offset, y_offset):
    cx             = img_witdh / 2
    cy             = img_height / 2
    short_side_pix = img_witdh if img_height > img_witdh else img_height
    margin         = (short_side_pix * pt_ratio) / 2
    pt0_x = cx - margin + x_offset
    pt0_y = cy - margin + y_offset
    pt1_x = cx - margin + x_offset
    pt1_y = cy + margin + y_offset
    pt2_x = cx + margin + x_offset
    pt2_y = cy - margin + y_offset
    pt3_x = cx + margin + x_offset
    pt3_y = cy + margin + y_offset
    return np.float32([[pt0_x, pt0_y],
                       [pt1_x, pt1_y],
                       [pt2_x, pt2_y],
                       [pt3_x, pt3_y]])

if __name__ == "__main__":
    print("Please input a corrected image path from Pcam5C that has not been transformed.")
    print("Note that an image should be included a square pattern on the ground.")
    filepath = input(">> ")
    src = cv2.imread(filepath)

    dst = np.zeros_like(src)
    src_width  = np.size(src, 1)
    src_height = np.size(src, 0)
    select_pt = []
    cv2.imshow("src", src)
    mouseData = mouseParam("src")

    print("Click on the square vertices in the image in the order shown below:")
    print("1. Top Left")
    print("2. Bottom Left")
    print("3. Top Right")
    print("4. Bottom Right")
    while True:
        cv2.imshow("src", src)
        cv2.waitKey(1)
        if mouseData.getEvent() == cv2.EVENT_LBUTTONDOWN:
            cv2.circle(src, mouseData.getPos() , 2, (0, 0, 255), thickness=-1, lineType=cv2.LINE_AA)
            time.sleep(0.2)
            select_pt.append(mouseData.getPos())
            print(mouseData.getPos())
            if len(select_pt) == 4:
                break

    src_pt = np.float32([[select_pt[0][0], select_pt[0][1]],
                         [select_pt[1][0], select_pt[1][1]],
                         [select_pt[2][0], select_pt[2][1]],
                         [select_pt[3][0], select_pt[3][1]]])

    dst_pt = set_dst_pt(src_width, src_height, 1.0, 0, 0)
    M      = cv2.getPerspectiveTransform(src_pt, dst_pt)
    dst    = cv2.warpPerspective(src, M, (src_width, src_height))

    while True:
        cv2.imshow("dst", dst)
        print("Please choose menu shown below:")
        print("'c': Specify ratio and Y-axis offset")
        print("'q': Quit and Show the homography matrix")
        key = cv2.waitKey()
        if key & 0xFF == ord("q"):
            cv2.destroyAllWindows()
            break
        elif key & 0xFF == ord("c"):
            print("Please input parameters")
            ratio    = np.float32(input("Ratio: "))
            offset_x = ((select_pt[0][0] + select_pt[2][0]) / 2) - (src_width / 2)
            offset_y = np.float32(input("Y-axis offset: "))
            dst_pt   = set_dst_pt(src_width, src_height, ratio, offset_x, offset_y)
            M        = cv2.getPerspectiveTransform(src_pt, dst_pt)
            dst      = cv2.warpPerspective(src, M, (src_width,src_height))

inverse_M = np.linalg.inv(M)
print("Homography Matrix:")
print("[",
      inverse_M[0][0], ",", inverse_M[0][1], ",", inverse_M[0][2], "\n",
      inverse_M[1][0], ",", inverse_M[1][1], ",", inverse_M[1][2], "\n",
      inverse_M[2][0], ",", inverse_M[2][1], ",", inverse_M[2][2],
      "]")
