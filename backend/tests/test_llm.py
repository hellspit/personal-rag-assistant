#!/usr/bin/env python3
"""
Test script for LLM integration with LangChain and Ollama
"""

import os
import sys
from dotenv import load_dotenv

# Add the parent directory to the path so we can import from app
sys.path.append(os.path.join(os.path.dirname(__file__), '..'))

# Load environment variables
load_dotenv()

def test_llm_integration():
    """Test the LLM integration"""
    try:
        from app.services import process_with_llm
        
        print("Testing LLM integration...")
        print("=" * 50)
        
        # Test 1: Simple question
        print("Test 1: Simple question")
        result1 = process_with_llm("Hello, how are you?")
        print(f"Success: {result1['success']}")
        print(f"Response: {result1['response']}")
        print(f"Processing time: {result1['processing_time']}s")
        print()
        
        # Test 2: Question with chat history
        print("Test 2: Question with chat history")
        chat_history = "user: What is Python?\nassistant: Python is a programming language."
        result2 = process_with_llm("Tell me more about Python", chat_history=chat_history)
        print(f"Success: {result2['success']}")
        print(f"Response: {result2['response']}")
        print(f"Processing time: {result2['processing_time']}s")
        print()
        
        # Test 3: Programming question
        print("Test 3: Programming question")
        result3 = process_with_llm("How do I create a function in Python?")
        print(f"Success: {result3['success']}")
        print(f"Response: {result3['response']}")
        print(f"Processing time: {result3['processing_time']}s")
        print()
        
        print("All tests completed!")
        
    except Exception as e:
        print(f"Error testing LLM integration: {e}")
        print("Make sure Ollama is running and the gemma3 model is installed.")
        print("You can install it with: ollama pull gemma3")

if __name__ == "__main__":
    test_llm_integration() 