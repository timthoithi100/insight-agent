"""
Test script for Insight-Agent application
"""

import pytest
from fastapi.testclient import TestClient
from main import app, analyze_text

client = TestClient(app)

def test_root_endpoint():
    """Test the root endpoint"""
    response = client.get("/")
    assert response.status_code == 200
    assert "Insight-Agent is running!" in response.json()["message"]

def test_health_endpoint():
    """Test the health check endpoint"""
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json()["status"] == "healthy"

def test_analyze_endpoint_basic():
    """Test the analyze endpoint with basic input"""
    test_data = {"text": "Hello world!"}
    response = client.post("/analyze", json=test_data)
    
    assert response.status_code == 200
    data = response.json()
    
    assert data["original_text"] == "Hello world!"
    assert data["word_count"] == 2
    assert data["character_count"] == 12
    assert data["character_count_no_spaces"] == 11

def test_analyze_endpoint_complex():
    """Test the analyze endpoint with complex input"""
    test_data = {"text": "This is a great product! I love it. Amazing quality."}
    response = client.post("/analyze", json=test_data)
    
    assert response.status_code == 200
    data = response.json()
    
    assert data["word_count"] == 10
    assert data["sentence_count"] == 3
    assert data["sentiment_score"] == "positive"

def test_analyze_endpoint_empty_text():
    """Test the analyze endpoint with empty text"""
    test_data = {"text": ""}
    response = client.post("/analyze", json=test_data)
    
    assert response.status_code == 400

def test_analyze_endpoint_whitespace_only():
    """Test the analyze endpoint with whitespace only"""
    test_data = {"text": "   "}
    response = client.post("/analyze", json=test_data)
    
    assert response.status_code == 400

def test_analyze_endpoint_too_long():
    """Test the analyze endpoint with text that's too long"""
    test_data = {"text": "a" * 10001}  # Over the 10,000 character limit
    response = client.post("/analyze", json=test_data)
    
    assert response.status_code == 400
    assert "Text too long" in response.json()["detail"]

def test_analyze_text_function():
    """Test the analyze_text function directly"""
    result = analyze_text("This is a test sentence.")
    
    assert result["original_text"] == "This is a test sentence."
    assert result["word_count"] == 5
    assert result["character_count"] == 24
    assert result["sentence_count"] == 1
    assert result["sentiment_score"] == "neutral"

def test_sentiment_analysis():
    """Test sentiment analysis functionality"""
    # Positive sentiment
    positive_result = analyze_text("This is absolutely wonderful and amazing!")
    assert positive_result["sentiment_score"] == "positive"
    
    # Negative sentiment
    negative_result = analyze_text("This is terrible and awful!")
    assert negative_result["sentiment_score"] == "negative"
    
    # Neutral sentiment
    neutral_result = analyze_text("This is a normal sentence.")
    assert neutral_result["sentiment_score"] == "neutral"

if __name__ == "__main__":
    pytest.main([__file__])