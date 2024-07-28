from flask import Flask, request, jsonify
from hand_written import HandWritten
from printed import Printed
from symspellpy import SymSpell, Verbosity
from spellchecker import SpellChecker

app = Flask(__name__)

@app.route('/', methods=['GET'])
def index():
    return jsonify({"message": "Welcome to the OCR API!"})

@app.route('/predict', methods=['POST'])
def upload():
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



sym_spell = SymSpell()
dictionary_path = "/path/to/frequency_dictionary_en_82_765.txt"
sym_spell.load_dictionary(dictionary_path, term_index=0, count_index=1)

spell_checker = SpellChecker()

@app.route('/correct_text', methods=['POST'])
def correct_text():
    data = request.get_json()
    text = data.get('text', '')

    print(text)
    # SymSpell check
    suggestions = sym_spell.lookup_compound(text, max_edit_distance=2)
    corrected_text = suggestions[0].term if suggestions else text

    # PySpellChecker check
    misspelled = spell_checker.unknown(corrected_text.split())
    corrected_text = ' '.join(spell_checker.correction(word) if word in misspelled else word for word in corrected_text.split())

    return jsonify({'corrected_text': corrected_text})


if __name__ == '__main__':
    app.run(debug=True)
