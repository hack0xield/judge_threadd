# Twitter AI Analysis System

A decentralized AI-powered Twitter analysis system that automatically processes mentions, evaluates content through AI, and displays results in a web interface.

## System Architecture

The system consists of three main components working together:

```
Twitter Mentions → AO Process → Frontend Display
```

## Core Components

### 1. Twitter Agent (`main.js`)
**Purpose**: Monitors Twitter mentions and triggers AI analysis

**Key Features**:
- Continuously monitors Twitter for mentions of `@judge_thrdd`
- Extracts tweet data and user information
- Sends processing requests to AO process
- Posts AI-generated responses back to Twitter
- Implements rate limiting (10s GET, 120s POST delays)

**Dependencies**:
- Node.js v22+ (required for `node:sqlite`)
- Twitter API authentication tokens
- AO network connectivity

### 2. AO Process (`infer_agent.lua`)
**Process ID**: `MMs2Ycxq46Pz3mC2bhz--4XFbPQjiDvR-9g-qKaxg2s`

**Purpose**: AI inference and data storage

**Key Features**:
- Receives tweet data from Twitter agent
- Processes content through APUS AI (on-chain LLM)
- Generates IQ scores (60-140 scale) with reasoning
- Stores all processed data persistently
- Provides paginated data access via `GetTasks` endpoint

**API Endpoints**:
- `Infer`: Process new tweet for AI analysis
- `GetTasks`: Retrieve paginated results with sorting
- `GetTaskByTid`: Get specific task by tweet ID

### 3. Frontend Interface
**URL**: https://judge-threadd_arlink.arweave.net/

**Purpose**: Display processed tweets and AI analysis

**Key Features**:
- Real-time table of processed tweets
- Sorted by creation time (newest first)
- Shows tweet content, username, status, and AI scores
- Pagination support for large datasets
- Built with React + TypeScript + Vite

## Quick Start

### Prerequisites
- Node.js v22.0.0 or higher
- Twitter API credentials
- Arweave wallet for AO process

### Installation
```bash
# Clone repository
git clone <repository-url>
cd judge_threadd

# Install dependencies
npm install

# Configure Twitter API credentials
cp config.example.json config.json
# Edit config.json with your Twitter API tokens

# Start Twitter agent
node main.js
```

### Configuration
Create `config.json` with required tokens:
```json
{
  "tautht0": "your_twitter_bearer_token",
  "tcsrft0": "your_twitter_csrf_token", 
  "tautht1": "your_twitter_auth_token",
  "openait": "your_openai_api_key",
  "arweave-keyfile": "path/to/arweave-wallet.json"
}
```

## Usage

### Triggering Analysis
1. Tweet a message mentioning `@judge_thrdd`
2. The system automatically:
   - Detects the mention
   - Extracts tweet content
   - Sends to AO process for AI analysis
   - Posts response with IQ score and reasoning

### Viewing Results
- Visit: https://judge-threadd_arlink.arweave.net/
- Browse processed tweets in real-time
- View AI scores and reasoning for each analysis

## Technical Details

### AI Processing
- **Primary**: APUS AI (on-chain inference)
- **Fallback**: OpenAI GPT-4o for reliability
- **Output**: JSON with score (60-140) and reasoning
- **Processing Time**: ~30-60 seconds per tweet

### Data Storage
- **AO Process**: Persistent on-chain storage
- **Local Cache**: SQLite database for processed tweets
- **Frontend**: Real-time data fetching from AO process

### Rate Limiting
- **Twitter API**: 10s between GET requests, 120s between POST
- **AO Network**: Minimal rate limits, 1s delays for stability
- **OpenAI**: 1s delay between requests

## API Reference

### AO Process Endpoints

#### GetTasks (Paginated Results)
```javascript
// Request
{
  "Action": "GetTasks",
  "Start": "1",
  "Limit": "10"
}

// Response
{
  "start": 1,
  "limit": 10,
  "total": 25,
  "count": 10,
  "has_more": true,
  "tasks": [
    {
      "reference": "tweet_id_timestamp",
      "task": {
        "status": "success",
        "twit": {
          "username": "user",
          "txt": "tweet content"
        },
        "response": {
          "score": 110,
          "reasoning": "AI analysis..."
        }
      }
    }
  ]
}
```

## Troubleshooting

### Common Issues
1. **Node.js Version**: Ensure Node.js v22+ for `node:sqlite` support
2. **Twitter API**: Verify authentication tokens in `config.json`
3. **AO Process**: Check network connectivity to Arweave
4. **Rate Limits**: System implements automatic delays

### Error Handling
- Twitter API failures: Automatic retry with exponential backoff
- AO process errors: Fallback to OpenAI processing
- Network issues: Graceful degradation and logging

## Development

### Project Structure
```
judge_threadd/
├── main.js                 # Twitter agent
├── infer_agent/           # AO process code
│   └── infer_agent.lua
├── vite/                  # Frontend application
│   └── src/
├── docs/                  # Documentation
└── package.json
```

### Key Dependencies
- `@permaweb/aoconnect`: AO network communication
- `axios`: HTTP client for API calls
- `sqlite`: Local database for caching
- `twitter-api-v2`: Twitter API integration

## License

MIT License - see LICENSE file for details.
