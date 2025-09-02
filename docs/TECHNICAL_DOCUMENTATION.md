# Technical Documentation: SocialFi NFT-Pill System

## Table of Contents
1. [Project Overview & Architecture](#1-project-overview--architecture)
2. [Core Components Documentation](#2-core-components-documentation)
3. [Technical Specifications](#3-technical-specifications)

---

## 1. Project Overview & Architecture

### 1.1 System Overview
The **SocialFi NFT-Pill System** is a decentralized, AI-powered social media engagement platform that combines blockchain technology, artificial intelligence, and social media APIs to create a gamified NFT ecosystem. The system automatically processes Twitter mentions, evaluates content through AI, and manages NFT-Pill lifecycle on the AO (Arweave) network.

### 1.2 High-Level Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Twitter API   │    │   OpenAI API    │    │   AO Network    │
│                 │    │                 │    │                 │
│ • Mentions      │    │ • GPT-4 Scoring │    │ • Smart         │
│ • Tweet Data    │    │ • Fallback AI   │    │   Contracts     │
│ • Reply System  │    │ • JSON Schema   │    │ • NFT-Pill      │
└─────────────────┘    └─────────────────┘    │   Management    │
         │                       │            └─────────────────┘
         │                       │                     │
         ▼                       ▼                     ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Core System (Node.js)                       │
│                                                                 │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐ │
│  │  Twitter Bot    │  │  AI Processor   │  │  State Manager  │ │
│  │                 │  │                 │  │                 │ │
│  │ • Mention       │  │ • APUS AI       │  │ • SQLite DB     │ │
│  │   Streaming     │  │ • OpenAI        │  │ • Tweet Cache   │ │
│  │ • Rate Limiting │  │ • Task Queue    │  │ • Process State │ │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
         │                       │                     │
         ▼                       ▼                     ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Frontend      │    │   Smart         │    │   NFT-Pill      │
│   (React/TS)    │    │   Contracts     │    │   Marketplace   │
│                 │    │                 │    │                 │
│ • User Dashboard│    │ • MintFacet     │    │ • Trading       │
│ • NFT Gallery   │    │ • Revenue Split │    │ • Queue Mgmt    │
│ • Analytics     │    │ • Cooldown      │    │ • Burn System   │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

### 1.3 Data Flow Architecture

#### 1.3.1 Twitter Mention Processing Flow
```
Twitter Mention → Rate Limiting → Content Extraction → AI Processing → Response Generation → Tweet Reply
```

#### 1.3.2 NFT-Pill Lifecycle Flow
```
Mint → Pair → Match → Revenue Generation → Sale Queue → Burn (after 5 uses)
```

#### 1.3.3 AI Processing Flow
```
Tweet Content → APUS AI (Primary) → OpenAI (Fallback) → Score + Reasoning → Response
```

### 1.4 Technology Stack

| Layer | Technology | Purpose |
|-------|------------|---------|
| **Frontend** | React + TypeScript + Vite | User interface and NFT management |
| **Backend** | Node.js + SQLite | Core business logic and data persistence |
| **Blockchain** | AO Network (Arweave) | Decentralized storage and smart contracts |
| **AI Processing** | APUS AI + (OpenAI fallback) | Content analysis and scoring |
| **APIs** | Twitter GraphQL + OpenAI REST | External service integration |
| **Database** | SQLite | Local state management and caching |

---

## 2. Core Components Documentation

### 2.1 Twitter Bot (`main.js`)

#### 2.1.1 Purpose & Responsibilities
The Twitter Bot serves as the primary interface between the social media ecosystem and the AI-powered NFT system. It continuously monitors Twitter mentions, processes incoming content, and generates automated responses based on AI analysis.

#### 2.1.2 Key Functions

##### `twitterMentions()` - Async Generator Function
```javascript
async function* twitterMentions() {
  // Streams Twitter mentions in real-time
  // Implements cursor-based pagination for efficient data retrieval
  // Yields mention objects with root tweet and mention tweet IDs
}
```

**Parameters**: None  
**Returns**: Async generator yielding `{root, mention}` objects  
**Rate Limiting**: 10-second delay between requests  
**Error Handling**: Graceful continuation on API failures  

##### `getTweet(tweetId)` - Tweet Data Extraction
```javascript
const getTweet = async (tweetId) => {
  // Extracts comprehensive tweet data including user info and content
  // Handles Twitter GraphQL API complexity
  // Returns structured tweet object
}
```

**Parameters**: `tweetId` (string) - Twitter tweet ID  
**Returns**: `{user_name, tweet_id, user_id, text}` object  
**API Endpoint**: Twitter GraphQL TweetDetail  
**Data Processing**: Filters and extracts relevant tweet information  

##### `judgeOffChain(tweet)` - AI Content Analysis
```javascript
const judgeOffChain = async (tweet) => {
  // OpenAI GPT-4 integration for content scoring
  // Structured JSON response with IQ score and reasoning
  // Fallback mechanism for when on-chain AI fails
}
```

**Parameters**: `tweet` (object) - Tweet data object  
**Returns**: `{score, reasoning}` object with IQ score (60-140)  
**AI Model**: GPT-4o-2024-08-06  
**Response Format**: Structured JSON schema validation  

##### `replyToTweet(tweetId, replyText)` - Automated Response
```javascript
const replyToTweet = async (tweetId, replyText) => {
  // Posts automated replies to Twitter mentions
  // Implements comprehensive Twitter API features
  // Rate limited to prevent API abuse
}
```

**Parameters**: 
- `tweetId` (string) - Target tweet ID for reply
- `replyText` (string) - AI-generated response content

**Rate Limiting**: 120-second delay between posts  
**API Features**: Full Twitter GraphQL feature set enabled  

#### 2.1.3 Rate Limiting Strategy
- **GET Requests**: 10-second delay between Twitter API calls
- **POST Requests**: 120-second delay between tweet replies
- **Purpose**: Prevents Twitter API rate limit violations
- **Implementation**: `sleep()` function with exponential backoff

#### 2.1.4 Authentication & Security
```javascript
const config = JSON.parse(fs.readFileSync("config.json"));
const headers = {
  Authorization: `Bearer ${config.tautht0}`,
  "X-Csrf-Token": config.tcsrft0,
  Cookie: `auth_token=${config.tautht1}; ct0=${config.tcsrft0}`
};
```

**Security Features**:
- Externalized configuration management
- Secure token storage
- CSRF protection
- Cookie-based authentication

### 2.2 AO Network Integration

#### 2.2.1 Process Configuration
```javascript
const aosig = ao.createSigner(config["arweave-keyfile"]);
const aopid = "MMs2Ycxq46Pz3mC2bhz--4XFbPQjiDvR-9g-qKaxg2s";
```

**Key Components**:
- **Signer**: Arweave wallet-based authentication
- **Process ID**: Unique identifier for the AO process
- **Network**: Arweave-based decentralized computing

#### 2.2.2 Message Handling
```javascript
const aoSendMessage = async (to, action, message) =>
  await ao.message({
    process: to,
    signer: aosig,
    data: message,
    tags: [{ name: "Action", value: action }]
  });
```

**Message Structure**:
- **Process**: Target AO process identifier
- **Action**: Operation type (e.g., "Infer", "GetTaskByTid")
- **Data**: JSON payload with tweet information
- **Tags**: Metadata for message routing

#### 2.2.3 Task Management
```javascript
const getTask = async (tweetId) => {
  const res = JSON.parse(
    (await ao.dryrun({
      process: aopid,
      data: "",
      tags: [
        { name: "Action", value: "GetTaskByTid" },
        { name: "Tid", value: tweetId }
      ],
      anchor: "1234"
    })).Messages[0].Data
  );
  return res.task;
};
```

**Task Operations**:
- **Dry Run**: Simulates message execution without state changes
- **Status Checking**: Monitors task completion status
- **Retry Logic**: Implements exponential backoff for failed tasks

### 2.4 AI Inference Agent (`infer_agent.lua`)

#### 2.4.1 Purpose & Architecture
The AI Inference Agent processes tweet content through on-chain AI using the APUS library, with fallback to OpenAI for reliability and accuracy.

#### 2.4.2 Core Functions

##### `constructPrompt(text)`
```lua
local function constructPrompt(text)
    if not text then
        return "Invalid or missing tweet data"
    end
    
    local cleanText = text:gsub("\n", " ")
    local basePrompt = "For this twit: '' "
    local endPrompt = " '' try to understand IQ level for the user and score it from min=60 to max=140. Give a short, 1-2 sentences explanation for your mark. Provide answer as json: {\"score\": 65, \"reasoning\": \"Nonsensical, inside joke\"}"
    
    return basePrompt .. cleanText .. endPrompt
end
```

**Purpose**: Constructs AI prompts for tweet analysis  
**Input Processing**: Cleans tweet text and removes newlines  
**Output Format**: Structured JSON response with score and reasoning  
**Score Range**: 60-140 IQ scale  

##### `createTask(reference, options, twit)`
```lua
local function createTask(reference, options, twit)
    local task = {
        options = options,
        session = options.session,
        reference = reference,
        status = "processing",
        starttime = os.time(),
    }
    
    if twit then
        task.twit = {
            username = twit.user_name,
            tid = twit.tweet_id,
            uid = twit.user_id,
            txt = twit.text
        }
    end
    
    Tasks[reference] = task
    TaskCounter = TaskCounter + 1
    
    return task
end
```

**Purpose**: Creates and manages AI processing tasks  
**Task Structure**: Comprehensive metadata for task tracking  
**State Management**: Maintains task count and status  
**Tweet Integration**: Embeds tweet data for AI processing  

#### 2.4.3 APUS AI Integration
```lua
-- Load the APUS AI library
ApusAI = require('@apus/ai')
print("DEBUG: APUS AI library loaded successfully")
```

**AI Library**: APUS AI for on-chain inference  
**Loading**: Dynamic library loading with error handling  
**Debug**: Comprehensive logging for troubleshooting  

#### 2.4.4 Task Management System
```lua
Tasks = Tasks or {}                      -- Process state where results are stored
TaskCounter = TaskCounter or 0           -- Simple counter for total tasks
```

**State Persistence**: Maintains task state across executions  
**Task Counter**: Tracks total number of processed tasks  
**Memory Management**: Efficient task storage and retrieval  

#### 2.4.5 Fallback Mechanism
```lua
-- OpenAI integration for when on-chain AI fails
-- Ensures system reliability and consistent response quality
```

**Fallback Strategy**: OpenAI GPT-4 when APUS AI unavailable  
**Quality Assurance**: Maintains consistent AI response quality  
**System Reliability**: Prevents complete system failure  

---

## 3. Technical Specifications

### 3.1 Dependencies & Versions

#### 3.1.1 Core Dependencies
```json
{
  "dependencies": {
    "@permaweb/aoconnect": "^0.0.90",
    "arweave": "^1.15.7",
    "axios": "^1.11.0"
  }
}
```

**Dependency Analysis**:
- **@permaweb/aoconnect**: AO network communication library
- **arweave**: Arweave blockchain integration
- **axios**: HTTP client for API communication

#### 3.1.2 Development Dependencies
```json
{
  "devDependencies": {
    "typescript": "^5.0.0",
    "vite": "^5.0.0",
    "react": "^18.0.0",
    "@types/react": "^18.0.0"
  }
}
```

**Frontend Stack**: Modern React development with TypeScript  
**Build Tool**: Vite for fast development and building  
**Type Safety**: Comprehensive TypeScript support  

### 3.2 Database Schema

#### 3.2.1 SQLite Database Structure
```sql
-- Main tweets table for caching and state management
CREATE TABLE IF NOT EXISTS tweets (
    tweet_id TEXT PRIMARY KEY,    -- Unique Twitter tweet identifier
    tweet TEXT                    -- JSON serialized tweet data
);
```

**Table Purpose**: Caches processed tweets to prevent reprocessing  
**Primary Key**: Twitter tweet ID for unique identification  
**Data Storage**: JSON serialization for flexible data structure  

#### 3.2.2 Database Operations
```javascript
// Tweet storage with upsert logic
const storePutTweet = (tweet) =>
  store
    .prepare(`INSERT OR REPLACE INTO tweets (tweet_id, tweet) VALUES (?, ?)`)
    .run(tweet.tweet_id, JSON.stringify(tweet));

// Tweet existence checking
const storeTweetExists = (tweetId) =>
  store
    .prepare(`SELECT EXISTS(SELECT * FROM tweets WHERE tweet_id = ?) AS result`)
    .get(tweetId).result == 1;
```

**Upsert Logic**: INSERT OR REPLACE prevents duplicate entries  
**Existence Checking**: Efficient boolean queries for tweet status  
**JSON Serialization**: Flexible data storage format  

### 3.3 API Endpoints & Integration

#### 3.3.1 Twitter GraphQL APIs

##### Mentions Timeline API
```javascript
const murl = `https://x.com/i/api/graphql/l6ovGrjBwVobgU4puBCycg/NotificationsTimeline?variables=${encodeURIComponent(JSON.stringify(reqv))}&features=${reqf}`;
```

**Endpoint**: Twitter notifications timeline  
**Purpose**: Retrieves user mentions and notifications  
**Parameters**: Timeline type, count, cursor for pagination  
**Features**: Comprehensive Twitter feature set enabled  

##### Tweet Detail API
```javascript
const turl = `https://x.com/i/api/graphql/oEUIqhz9YZjZVpE5i68Sfg/TweetDetail?variables=${reqv}&features=${reqf}&fieldToggles=${reqt}`;
```

**Endpoint**: Individual tweet data retrieval  
**Purpose**: Extracts comprehensive tweet information  
**Data Extraction**: User info, tweet content, metadata  
**Response Processing**: Filters and structures tweet data  

##### Create Tweet API
```javascript
const res = await twPost(
  "https://x.com/i/api/graphql/mGOM24dT4fPg08ByvrpP2A/CreateTweet",
  {
    variables: {
      tweet_text: replyText,
      reply: { in_reply_to_tweet_id: tweetId, exclude_reply_user_ids: [] },
      // ... additional parameters
    }
  }
);
```

**Endpoint**: Tweet creation and replies  
**Purpose**: Posts AI-generated responses to mentions  
**Reply Support**: In-reply-to functionality for conversations  
**Feature Set**: Full Twitter API feature compatibility  

#### 3.3.2 OpenAI API Integration
```javascript
const openaires = await axios.post(
  "https://api.openai.com/v1/chat/completions",
  {
    model: "gpt-4o-2024-08-06",
    messages: [
      {
        role: "user",
        content: `For this tweet "${tweet.text.replace(/\s+/g, " ")}" try to estimate IQ level of the author and score it from min=60 to max=140. Give a short, 1-2 sentences, explanation for your estimate`
      }
    ],
    response_format: {
      type: "json_schema",
      schema: {
        type: "object",
        properties: {
          score: { type: "integer" },
          reasoning: { type: "string" }
        },
        required: ["score", "reasoning"],
        additionalProperties: false
      }
    }
  },
  {
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${config.openait}`
    }
  }
);
```

**Model**: GPT-4o-2024-08-06 for advanced content analysis  
**Structured Output**: JSON schema validation for consistent responses  
**Content Analysis**: IQ scoring with reasoning explanation  
**Error Handling**: Comprehensive error handling and validation  

#### 3.3.3 AO Network APIs
```javascript
// Message sending to AO processes
const aoSendMessage = async (to, action, message) =>
  await ao.message({
    process: to,
    signer: aosig,
    data: message,
    tags: [{ name: "Action", value: action }]
  });

// Dry run for task status checking
const getTask = async (tweetId) => {
  const res = JSON.parse(
    (await ao.dryrun({
      process: aopid,
      data: "",
      tags: [
        { name: "Action", value: "GetTaskByTid" },
        { name: "Tid", value: tweetId }
      ],
      anchor: "1234"
    })).Messages[0].Data
  );
  return res.task;
};
```

**Message Passing**: Asynchronous communication between processes  
**Dry Run**: Simulates execution without state changes  
**Tag System**: Metadata for message routing and processing  
**Signer Authentication**: Secure message signing and verification  

### 3.4 Data Structures & Models

#### 3.4.1 Tweet Data Model
```javascript
const tweet = {
  user_name: "string",      // Twitter username
  tweet_id: "string",       // Unique tweet identifier
  user_id: "string",        // Twitter user ID
  text: "string",           // Tweet content
  estimate: {               // AI analysis results
    score: number,          // IQ score (60-140)
    reasoning: "string",    // AI explanation
    source: "string"        // AI source (apus/openai)
  }
};
```

**Data Structure**: Comprehensive tweet representation  
**AI Integration**: Embedded AI analysis results  
**Source Tracking**: Identifies AI processing method  

#### 3.4.2 Task Data Model
```lua
local task = {
  options = {},             -- AI processing options
  session = "string",       -- Processing session identifier
  reference = "string",     -- Unique task reference
  status = "string",        -- Task status (processing/success/failed)
  starttime = number,       -- Task start timestamp
  twit = {                  -- Tweet data for processing
    username = "string",    -- Twitter username
    tid = "string",         -- Tweet ID
    uid = "string",         -- User ID
    txt = "string"          -- Tweet text content
  }
}
```

**Task Management**: Comprehensive task tracking  
**State Persistence**: Maintains task state across executions  
**Tweet Integration**: Embeds tweet data for AI processing  

#### 3.4.3 NFT-Pill Data Model
```solidity
struct NftPill {
  uint256 id;               // Unique NFT identifier
  address[2] revenues;      // Revenue distribution addresses
  uint256 useCount;         // Current usage count
  uint256 lastUsedTime;     // Last usage timestamp
  uint256 maxUseCount;      // Maximum allowed uses
  bool isActive;            // Active status flag
}
```

**Blockchain Storage**: On-chain NFT data representation  
**Revenue Tracking**: Address pairs for profit distribution  
**Usage Management**: Cooldown and limit enforcement  
