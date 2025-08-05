import requests
import json

def test_vosk_server():
    base_url = "http://localhost:5000"
    print("Testing Vosk STT Server...")
    print("=" * 40)
    
    try:
        # Test health endpoint
        print("1. Testing health endpoint...")
        response = requests.get(f"{base_url}/health")
        if response.status_code == 200:
            data = response.json()
            print(f"✅ Health check passed!")
            print(f"   Status: {data.get('status')}")
            print(f"   Model loaded: {data.get('model_loaded')}")
        else:
            print(f"❌ Health check failed: {response.status_code}")
            return False
            
        # Test transcribe endpoint with dummy audio data
        print("\n2. Testing transcribe endpoint...")
        dummy_audio = b'\x00' * 1000  # 1KB of silence
        response = requests.post(
            f"{base_url}/transcribe_raw",
            data=dummy_audio,
            headers={'Content-Type': 'application/octet-stream'}
        )
        
        if response.status_code == 200:
            data = response.json()
            print(f"✅ Transcribe test passed!")
            print(f"   Response: {data.get('text', 'No text')}")
            print(f"   Success: {data.get('success', False)}")
        else:
            print(f"❌ Transcribe test failed: {response.status_code}")
            print(f"   Response: {response.text}")
            
    except Exception as e:
        print(f"❌ Error: {e}")
        return False
        
    print("\n" + "=" * 40)
    print("✅ Vosk server is working!")
    return True

if __name__ == "__main__":
    test_vosk_server() 