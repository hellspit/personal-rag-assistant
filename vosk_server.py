from vosk import Model, KaldiRecognizer
from flask import Flask, request, jsonify
from flask_cors import CORS
import json
import os
import wave
import numpy as np
from werkzeug.utils import secure_filename
import io
import base64
import subprocess
import tempfile
import struct
import scipy.signal as signal
import re

app = Flask(__name__)
CORS(app)  # Enable CORS for Flutter app

# Initialize Vosk model
model_path = "vosk-model-en"
if not os.path.exists(model_path):
    print(f"Error: Vosk model not found at {model_path}")
    print("Please ensure the model files are in the correct location")
    exit(1)

print(f"Loading Vosk model from: {model_path}")
model = Model(model_path)
print("Vosk model loaded successfully!")

def is_complete_sentence(text):
    """Check if the text appears to be a complete sentence or phrase"""
    if not text or len(text.strip()) < 3:
        return False
    
    # Remove extra whitespace
    text = text.strip()
    
    # Check for common sentence endings
    sentence_endings = ['.', '!', '?', '।', '?', '!']
    if any(text.endswith(ending) for ending in sentence_endings):
        return True
    
    # Check for natural pause indicators (comma, semicolon)
    pause_indicators = [',', ';', ':', '।']
    if any(indicator in text for indicator in pause_indicators):
        # If there's a pause indicator and the text is reasonably long
        if len(text) > 10:
            return True
    
    # Check if text is long enough to be considered complete
    if len(text) > 20:
        return True
    
    return False

def apply_noise_filtering(audio_data, sample_rate=16000):
    """Apply noise filtering to audio data"""
    try:
        # Convert bytes to numpy array
        audio_array = np.frombuffer(audio_data, dtype=np.int16)
        
        # Normalize audio to float
        audio_float = audio_array.astype(np.float32) / 32768.0
        
        # Apply high-pass filter to remove low-frequency noise (like AC hum)
        highpass_cutoff = 80  # Hz
        nyquist = sample_rate / 2
        highpass_normalized = highpass_cutoff / nyquist
        b_highpass, a_highpass = signal.butter(4, highpass_normalized, btype='high')
        audio_filtered = signal.filtfilt(b_highpass, a_highpass, audio_float)
        
        # Apply low-pass filter to remove high-frequency noise
        lowpass_cutoff = 8000  # Hz
        lowpass_normalized = lowpass_cutoff / nyquist
        b_lowpass, a_lowpass = signal.butter(4, lowpass_normalized, btype='low')
        audio_filtered = signal.filtfilt(b_lowpass, a_lowpass, audio_filtered)
        
        # Apply noise gate (remove very quiet parts)
        noise_threshold = 0.01
        audio_filtered[np.abs(audio_filtered) < noise_threshold] = 0
        
        # Convert back to int16
        audio_filtered_int16 = (audio_filtered * 32767).astype(np.int16)
        
        return audio_filtered_int16.tobytes()
        
    except Exception as e:
        return audio_data  # Return original if filtering fails

@app.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint"""
    return jsonify({
        'status': 'healthy',
        'model_loaded': True,
        'model_path': model_path
    })

@app.route('/transcribe', methods=['POST'])
def transcribe():
    """Transcribe audio data using Vosk"""
    try:
        if 'audio' not in request.files:
            return jsonify({'error': 'No audio file provided'}), 400
        
        audio_file = request.files['audio']
        if audio_file.filename == '':
            return jsonify({'error': 'No audio file selected'}), 400
        
        # Read audio data
        audio_data = audio_file.read()
        
        # Create recognizer (16kHz sample rate)
        rec = KaldiRecognizer(model, 16000)
        
        # Process audio data
        if rec.AcceptWaveform(audio_data):
            # Get final result
            result = json.loads(rec.FinalResult())
            text = result.get('text', '')
            
            return jsonify({
                'success': True,
                'text': text,
                'confidence': result.get('confidence', 0.0)
            })
        else:
            # Get partial result
            result = json.loads(rec.PartialResult())
            text = result.get('partial', '')
            
            return jsonify({
                'success': True,
                'text': text,
                'partial': True
            })
            
    except Exception as e:
        print(f"Error processing audio: {str(e)}")
        return jsonify({'error': str(e)}), 500

@app.route('/transcribe_raw', methods=['POST'])
def transcribe_raw():
    """Transcribe raw audio data (for real-time processing)"""
    try:
        # Get raw audio data from request
        audio_data = request.get_data()
        
        if not audio_data:
            return jsonify({'error': 'No audio data provided'}), 400
        
        # Expect WAV/PCM audio, skip 44-byte header
        try:
            if len(audio_data) > 44:
                pcm_data = audio_data[44:]
            else:
                pcm_data = audio_data
            
            # Apply noise filtering
            filtered_pcm_data = apply_noise_filtering(pcm_data, sample_rate=16000)
            
            # Create recognizer with better settings
            rec = KaldiRecognizer(model, 16000)
            
            # Only process if we have enough audio data
            if len(filtered_pcm_data) > 1000:  # At least 1KB of audio
                if rec.AcceptWaveform(filtered_pcm_data):
                    result = json.loads(rec.FinalResult())
                    text = result.get('text', '')
                    confidence = result.get('confidence', 0.0)
                    
                    # Check if we have a complete sentence
                    is_complete = is_complete_sentence(text)
                    
                    # Only return text if confidence is reasonable or text is complete
                    if (confidence > 0.1 or text.strip()) and text:
                        return jsonify({
                            'success': True,
                            'text': text,
                            'partial': False,
                            'confidence': confidence,
                            'speech_ended': True,
                            'is_complete': is_complete
                        })
                    else:
                        return jsonify({
                            'success': True,
                            'text': 'No clear speech detected',
                            'partial': False,
                            'confidence': confidence,
                            'speech_ended': True,
                            'is_complete': False
                        })
                else:
                    result = json.loads(rec.PartialResult())
                    text = result.get('partial', '')
                    
                    # Check if partial text is complete
                    is_complete = is_complete_sentence(text)
                    
                    if text.strip():
                        return jsonify({
                            'success': True,
                            'text': text,
                            'partial': True,
                            'speech_ended': False,
                            'is_complete': is_complete
                        })
                    else:
                        return jsonify({
                            'success': True,
                            'text': 'Listening...',
                            'partial': True,
                            'speech_ended': False,
                            'is_complete': False
                        })
            else:
                return jsonify({
                    'success': True,
                    'text': 'Not enough audio data',
                    'partial': False,
                    'is_complete': False
                })
        except Exception as e:
            return jsonify({
                'success': True,
                'text': 'Processing error',
                'partial': False,
                'is_complete': False
            })
            
    except Exception as e:
        return jsonify({'error': 'Processing error'}), 500

if __name__ == '__main__':
    print("Starting Vosk STT Server...")
    print("Server will be available at: http://localhost:5000")
    print("Endpoints:")
    print("  - GET  /health - Health check")
    print("  - POST /transcribe - Transcribe audio file")
    print("  - POST /transcribe_raw - Transcribe raw audio data")
    app.run(host='0.0.0.0', port=5000, debug=True) 