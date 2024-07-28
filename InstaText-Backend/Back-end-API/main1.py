from flask import Flask, request, jsonify
from hand_written import HandWritten
from printed import Printed

app = Flask(__name__)

@app.route('/', methods=['GET'])
def index():
    return jsonify({"message": "Welcome to the OCR API!"})

@app.route('/predict', methods=['POST'])
def upload(type):
    if 'file' not in request.files:
        return jsonify({"error": "No file part"}), 400
    
    f = request.files['file']
    if not f or (f.filename == '' and f.content_length == 0):
        return jsonify({"error": "No selected file"}), 400
    
    if '.' not in f.filename or f.filename.rsplit('.', 1)[1].lower() not in ["jpeg", "jpg", "png"]:
        return jsonify({"error": "Invalid file type"}), 400
    
    img_bytes = f.read()
    img_to_text_model = HandWritten()
    result = img_to_text_model.model_predict(img_bytes)

    return jsonify({"result": result})

if __name__ == '__main__':
    app.run(debug=True)
