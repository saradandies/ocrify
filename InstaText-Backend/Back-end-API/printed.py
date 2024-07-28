import cv2
import numpy as np
class Printed:
    def model_predict(self,img_bytes):
        np_arr = np.frombuffer(img_bytes, np.uint8)
        img = cv2.imdecode(np_arr, cv2.IMREAD_COLOR)
        text="Printed text"
        #Correction model
        return text