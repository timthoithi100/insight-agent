"""
Insight-Agent: AI-powered text analysis service
A simple FastAPI application for analyzing customer feedback
"""

from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import uvicorn
import os
import logging
import re
from typing import Dict, Any

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(
    title="Insight-Agent",
    description="AI-powered text analysis service for customer feedback",
    version="1.0.0"
)

class TextInput(BaseModel):
    text: str

class AnalysisResponse(BaseModel):
    original_text: str
    word_count: int
    character_count: int
    character_count_no_spaces: int
    sentence_count: int
    paragraph_count: int
    avg_word_length: float
    sentiment_score: str  # Simple sentiment analysis

def analyze_text(text: str) -> Dict[str, Any]:
    """
    Perform comprehensive text analysis
    """
    if not text or not text.strip():
        raise ValueError("Text cannot be empty")
    
    # Basic counts
    word_count = len(text.split())
    character_count = len(text)
    character_count_no_spaces = len(text.replace(' ', ''))
    
    # Sentence count (simple regex)
    sentences = re.split(r'[.!?]+', text.strip())
    sentence_count = len([s for s in sentences if s.strip()])
    
    # Paragraph count
    paragraph_count = len([p for p in text.split('\n\n') if p.strip()])
    if paragraph_count == 0:
        paragraph_count = 1
    
    # Average word length
    words = text.split()
    avg_word_length = sum(len(word.strip('.,!?;:')) for word in words) / len(words) if words else 0
    
    # Simple sentiment analysis (basic keyword-based)
    positive_words = ['good', 'great', 'excellent', 'amazing', 'love', 'wonderful', 'fantastic']
    negative_words = ['bad', 'terrible', 'awful', 'hate', 'horrible', 'disgusting']
    
    text_lower = text.lower()
    positive_count = sum(1 for word in positive_words if word in text_lower)
    negative_count = sum(1 for word in negative_words if word in text_lower)
    
    if positive_count > negative_count:
        sentiment_score = "positive"
    elif negative_count > positive_count:
        sentiment_score = "negative"
    else:
        sentiment_score = "neutral"
    
    return {
        "original_text": text,
        "word_count": word_count,
        "character_count": character_count,
        "character_count_no_spaces": character_count_no_spaces,
        "sentence_count": sentence_count,
        "paragraph_count": paragraph_count,
        "avg_word_length": round(avg_word_length, 2),
        "sentiment_score": sentiment_score
    }

@app.get("/")
async def root():
    """Health check endpoint"""
    return {"message": "Insight-Agent is running!", "status": "healthy"}

@app.get("/health")
async def health_check():
    """Detailed health check"""
    return {"status": "healthy", "service": "insight-agent", "version": "1.0.0"}

@app.post("/analyze", response_model=AnalysisResponse)
async def analyze_endpoint(input_data: TextInput):
    """
    Analyze text and return comprehensive analysis results
    """
    try:
        logger.info(f"Received analysis request for text length: {len(input_data.text)}")
        
        if len(input_data.text) > 10000:  # Limit text size
            raise HTTPException(status_code=400, detail="Text too long. Maximum 10,000 characters allowed.")
        
        analysis_result = analyze_text(input_data.text)
        
        logger.info("Analysis completed successfully")
        return AnalysisResponse(**analysis_result)
        
    except ValueError as e:
        logger.error(f"Validation error: {str(e)}")
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        logger.error(f"Analysis error: {str(e)}")
        raise HTTPException(status_code=500, detail="Internal server error during analysis")

if __name__ == "__main__":
    port = int(os.environ.get("PORT", 8080))
    uvicorn.run(app, host="0.0.0.0", port=port)