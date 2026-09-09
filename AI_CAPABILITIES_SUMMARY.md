# Fixly AI/ML Capabilities Summary

## Current AI/ML Features

### 1. Service Discovery (AI-Powered Classification)
- **Location**: `./ai_ml/service_discovery/`
- **Technology**: FastAPI + scikit-learn
- **Model**: Trained classifier (`service_classifier.pkl`) + TF-IDF vectorizer
- **Endpoint**: `POST http://127.0.0.1:8002/discover`
- **Function**: Takes text description and returns suggested service categories with confidence scores
- **Usage**: Called by backend `/service-discovery` route when user says "Don't know what you're looking for?"

### 2. AI Issue Analyzer (Text + Image)
- **Location**: `./backend/controllers/aiController.js` (`analyzeIssue` function)
- **Technology**: Node.js + keyword matching + Cloudinary for image upload
- **Function**: Analyzes problem description (and optional image) to detect:
  - Electrical issues (wire, spark, switch, light)
  - Plumbing issues (pipe, leak, tap, water)
  - Cleaning issues (clean, dust, sofa)
  - Defaults to Plumbing if no match
- **Returns**: Suggested category, estimated hours, AI note
- **Used by**: Customer AI Helper page (`customer_ai_helper_page.dart`)

### 3. Worker Matching
- **Location**: `./backend/controllers/aiController.js` (`matchWorkers` function)
- **Technology**: MongoDB geospatial query + scoring algorithm
- **Function**: Finds nearby workers based on:
  - Location (within 15km)
  - Rating (0-5 scale)
  - Availability (isOnline)
  - Experience (totalJobs)
  - Verification status (isVerified)
- **Scoring**: Rating*40 + Availability*25 + Jobs*20 + Verified*15
- **Used by**: Service detail page to show worker carousel

### 4. Support Chatbot
- **Location**: `./ai_ml/support_chatbot/`
- **Technology**: Custom rule-based engine with intent matching
- **Features**:
  - Multi-language support (English/Hindi)
  - Ticket raising system
  - Booking status lookup
  - FAQ system with quick replies
  - Session management
  - Human agent escalation
- **Components**:
  - Engine: State machine for conversation flow
  - Matcher: Intent matching using keyword patterns
  - Session: User conversation tracking
  - Data layers: Tickets, bookings, offers, knowledge base
- **Port**: Runs on 8080 (separate from main API)

## Current Integration Points

1. **Customer Service Detail Page** (`customer_service_detail_page.dart`):
   - Shows "Fixly AI" action chip in header (navigates to AI Helper)
   - Uses AI for worker matching based on service category
   - Displays estimated time from service data

2. **Customer AI Helper Page** (`customer_ai_helper_page.dart`):
   - Chat interface for describing problems
   - Calls `/analyze-issue` endpoint for text analysis
   - Shows "Discover Services" button (navigates to discovery page)

3. **Backend Routes**:
   - `/analyze-issue`: Text + optional image analysis
   - `/service-discovery`: Pure text classification via Python ML service
   - `/match-workers`: Geospatial worker matching
   - `/demand-forecast`: Demand forecasting (separate controller)

## Missing Frontier Model Integrations

Based on the code review, the system currently does NOT have integrated support for:

### 1. Groq
- No references to Groq API or Llama models
- No API keys or configuration for Groq found

### 2. NVIDIA NIM
- No references to NVIDIA Inference Microservices
- No Triton inference server configurations
- No NVIDIA API endpoints called

### 3. Google Gemini
- No references to Gemini API or Google AI services
- No API keys or configuration for Gemini found

### 4. Live Talking Support / Voice Chat
- No speech-to-text or text-to-speech implementations
- No voice chat interfaces or WebRTC integrations
- No real-time voice conversation capabilities

## Current Limitations

1. **Service Discovery Dependency**: 
   - Requires Python service running on port 8002
   - If service unavailable, falls back to Node.js keyword matcher
   - No indication of service monitoring or auto-restart

2. **AI Issue Analyzer**:
   - Uses simple keyword matching (not ML-based)
   - Limited to 3 predefined categories
   - No image analysis beyond URL storage (no actual image understanding)

3. **Support Chatbot**:
   - Rule-based, not LLM-powered
   - Intent matching via regex/keywords
   - No conversational AI or context understanding beyond state machine

4. **Worker Matching**:
   - Uses heuristic scoring, not ML-based ranking
   - No consideration of worker skills matching service requirements
   - Pure geographic + reputation based

## Enhancement Opportunities

### 1. Replace Keyword Matching with LLMs
- Use Groq/Llama3 for intent classification in `analyzeIssue`
- Use Gemini for service discovery with better semantic understanding
- Replace support chatbot with LLM-powered conversational agent

### 2. Add Image Understanding
- Integrate vision models (Gemini Pro Vision, GPT-4V) for actual image analysis
- Allow users to upload photos of problems for better diagnosis

### 3. Implement Vector Search
- Use embeddings for service discovery instead of TF-IDF
- Enable semantic search for similar past issues/solutions

### 4. Add Live Voice Support
- Integrate speech-to-text for hands-free problem description
- Add text-to-speech for auditory responses
- Implement real-time voice chat with human agents when needed

### 5. Improve Worker Matching with ML
- Train model to predict best worker-service match
- Consider skills, past performance, location, and availability
- Add reinforcement learning for continuous improvement

### 6. Add Demand Forecasting Integration
- Actually use the `/demand-forecast` endpoint for pricing optimization
- Implement dynamic pricing based on predicted demand

## Files to Modify for Enhancements

1. **Backend AI Controller** (`backend/controllers/aiController.js`):
   - Replace keyword matching with LLM API calls
   - Add image analysis with vision models
   - Enhance worker matching with ML scoring

2. **Frontend AI Helper** (`frontend/lib/features/customer/presentation/pages/customer_ai_helper_page.dart`):
   - Add voice input/output capabilities
   - Show confidence scores and alternative suggestions
   - Add follow-up question capability

3. **Support Chatbot** (`ai_ml/support_chatbot/gig_support_chatbot/core/engine.py`):
   - Replace rule engine with LLM + function calling
   - Add conversation summarization
   - Implement context-aware responses

4. **Service Discovery** (`ai_ml/service_discovery/`):
   - Upgrade to use LLM embeddings or fine-tuned models
   - Add confidence calibration
   - Handle edge cases better

## Recommendation

For immediate enhancement with free tier options:
1. **Groq** - Fast Llama3 inference, good for text classification
2. **Google Gemini Free Tier** - Good for text and image understanding
3. **Open-source alternatives** - Deploy Llama3 or Mistral via HuggingFace TGI

Start with replacing the service discovery and issue analyzer with LLM-based solutions, then enhance the chatbot, and finally add voice capabilities.