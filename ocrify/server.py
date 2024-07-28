# server.py
from flask import Flask, request, jsonify
import cv2
import numpy as np
import pytesseract

app = Flask(__name__)

class HandWritten:
    @app.route('/api/handwritten-ocr', methods=['POST'])
    def handwritten_ocr():
        img_bytes = request.files['image'].read()
        np_arr = np.frombuffer(img_bytes, np.uint8)
        img = cv2.imdecode(np_arr, cv2.IMREAD_COLOR)
        gray_image = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
        _, threshold_img = cv2.threshold(gray_image, 0, 255, cv2.THRESH_BINARY + cv2.THRESH_OTSU)
        text = pytesseract.image_to_string(threshold_img)
        return jsonify({'text': text})

if __name__ == '__main__':
    app.run(debug=True)
