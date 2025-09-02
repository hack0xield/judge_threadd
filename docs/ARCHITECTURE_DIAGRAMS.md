# Architecture Diagrams & System Flows

## Table of Contents
1. [System Architecture Overview](#1-system-architecture-overview)
2. [Data Flow Diagrams](#2-data-flow-diagrams)
3. [Component Interaction Diagrams](#3-component-interaction-diagrams)
4. [Deployment Architecture](#4-deployment-architecture)

---

## 1. System Architecture Overview

### 1.1 High-Level System Architecture

```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                                EXTERNAL SERVICES                                   │
├─────────────────┬─────────────────┬─────────────────┬─────────────────────────────┤
│   Twitter API   │   OpenAI API    │   AO Network    │      Frontend (React)      │
│                 │                 │                 │                             │
│ • Mentions      │ • GPT-4 Scoring │ • Smart         │ • User Dashboard           │
│ • Tweet Data    │ • Fallback AI   │   Contracts     │ • NFT Gallery              │
│ • Reply System  │ • JSON Schema   │ • NFT-Pill      │ • Analytics                │
│ • Rate Limits   │ • Error Handling│   Management    │ • Trading Interface        │
└─────────────────┴─────────────────┴─────────────────┴─────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                              CORE SYSTEM (Node.js)                                │
├─────────────────┬─────────────────┬─────────────────┬─────────────────────────────┤
│   Twitter Bot   │   AI Processor  │  State Manager  │    API Gateway             │
│                 │                 │                 │                             │
│ • Mention       │ • APUS AI       │ • SQLite DB     │ • REST Endpoints           │
│   Streaming     │ • OpenAI        │ • Tweet Cache   │ • WebSocket Support        │
│ • Rate Limiting │ • Task Queue    │ • Process State │ • Rate Limiting            │
│ • Auth Mgmt     │ • Fallback      │ • Backup        │ • CORS & Security          │
└─────────────────┴─────────────────┴─────────────────┴─────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                              BLOCKCHAIN LAYER                                     │
├─────────────────┬─────────────────┬─────────────────┬─────────────────────────────┤
│   Smart        │   NFT-Pill      │   Revenue       │      Queue                 │
│   Contracts    │   Management    │   Distribution  │      Management            │
│                 │                 │                 │                             │
│ • MintFacet    │ • Lifecycle     │ • 40-40-20      │ • Sale Queue               │
│ • Pairing      │ • Cooldown      │   Split         │ • Burn System               │
│ • Validation   │ • Usage Count   │ • Automatic     │ • Priority Handling        │
│ • Access Ctrl  │ • Burn Logic    │   Execution     │ • Queue Optimization       │
└─────────────────┴─────────────────┴─────────────────┴─────────────────────────────┘
```

### 1.2 Technology Stack Architecture

```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                                    PRESENTATION LAYER                              │
├─────────────────────────────────────────────────────────────────────────────────────┤
│  React 18 + TypeScript + Vite                                                     │
│  • Component-based architecture                                                   │
│  • Type-safe development                                                          │
│  • Hot module replacement                                                        │
│  • Optimized build process                                                       │
└─────────────────────────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                                    APPLICATION LAYER                              │
├─────────────────────────────────────────────────────────────────────────────────────┤
│  Node.js + Express                                                               │
│  • RESTful API endpoints                                                          │
│  • WebSocket support for real-time updates                                       │
│  • Middleware for authentication & rate limiting                                  │
│  • Error handling & logging                                                       │
└─────────────────────────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                                    BUSINESS LOGIC LAYER                           │
├─────────────────────────────────────────────────────────────────────────────────────┤
│  Core Business Logic                                                              │
│  • Twitter bot logic                                                              │
│  • AI processing pipeline                                                         │
│  • NFT-Pill lifecycle management                                                 │
│  • Revenue distribution algorithms                                                │
└─────────────────────────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                                    DATA ACCESS LAYER                              │
├─────────────────────────────────────────────────────────────────────────────────────┤
│  SQLite + AO Network                                                              │
│  • Local state management                                                         │
│  • Decentralized storage                                                          │
│  • Smart contract execution                                                       │
│  • Data persistence & caching                                                     │
└─────────────────────────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                                    INFRASTRUCTURE LAYER                           │
├─────────────────────────────────────────────────────────────────────────────────────┤
│  System Services                                                                  │
│  • Process management (PM2/Systemd)                                              │
│  • Logging & monitoring                                                           │
│  • Backup & recovery                                                              │
│  • Security & firewall                                                            │
└─────────────────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Data Flow Diagrams

### 2.1 Twitter Mention Processing Flow

```
┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│   Twitter   │    │   Rate      │    │  Content    │    │   AI        │
│   Mention   │───▶│  Limiting   │───▶│ Extraction │───▶│ Processing  │
└─────────────┘    └─────────────┘    └─────────────┘    └─────────────┘
                                                              │
                                                              ▼
┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│   Tweet     │    │   Response  │    │   Rate      │    │   Twitter   │
│   Storage   │◀───│ Generation  │◀───│ Limiting   │◀───│   Reply     │
└─────────────┘    └─────────────┘    └─────────────┘    └─────────────┘
```

**Detailed Flow Description:**
1. **Twitter Mention**: System detects new mention via Twitter API
2. **Rate Limiting**: Applies 10-second delay to prevent API abuse
3. **Content Extraction**: Extracts tweet data, user info, and content
4. **AI Processing**: Sends content to APUS AI (primary) or OpenAI (fallback)
5. **Response Generation**: Creates AI-generated response with IQ score
6. **Rate Limiting**: Applies 120-second delay for tweet replies
7. **Twitter Reply**: Posts automated response to the mention
8. **Tweet Storage**: Caches processed tweet in SQLite database

### 2.2 NFT-Pill Lifecycle Flow

```
┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│   Mint      │    │   Pair      │    │   Match     │    │   Revenue   │
│   NFT-Pill  │───▶│   Users     │───▶│   Event    │───▶│ Generation  │
└─────────────┘    └─────────────┘    └─────────────┘    └─────────────┘
                                                              │
                                                              ▼
┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│   Burn      │    │   Sale      │    │   Queue     │    │   Revenue   │
│   (5 uses)  │◀───│   Queue     │◀───│ Management │◀───│ Distribution│
└─────────────┘    └─────────────┘    └─────────────┘    └─────────────┘
```

**Detailed Flow Description:**
1. **Mint NFT-Pill**: Creates new NFT-Pill with unique identifier
2. **Pair Users**: Matches two NFT-Pill holders randomly
3. **Match Event**: Triggers new NFT-Pill creation and pairing
4. **Revenue Generation**: Creates potential for profit through sales
5. **Revenue Distribution**: Splits profits (40-40-20) automatically
6. **Queue Management**: Adds new NFT-Pill to sale queue
7. **Sale Queue**: Manages NFT-Pill availability for purchase
8. **Burn (5 uses)**: Removes NFT-Pill after maximum usage limit

### 2.3 AI Processing Flow

```
┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│   Tweet     │    │   APUS AI   │    │   Task      │    │   Success   │
│   Content   │───▶│   (Primary) │───▶│   Queue    │───▶│   Response  │
└─────────────┘    └─────────────┘    └─────────────┘    └─────────────┘
       │                   │                   │                   │
       │                   ▼                   ▼                   │
       │            ┌─────────────┐    ┌─────────────┐             │
       │            │   Failure   │    │   Retry     │             │
       │            │   Detection │───▶│   Logic     │             │
       │            └─────────────┘    └─────────────┘             │
       │                   │                   │                   │
       ▼                   ▼                   ▼                   ▼
┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│   OpenAI    │    │   Fallback  │    │   Max       │    │   Final     │
│   (GPT-4)   │    │   Response  │    │   Retries   │    │   Response  │
└─────────────┘    └─────────────┘    └─────────────┘    └─────────────┘
```

**Detailed Flow Description:**
1. **Tweet Content**: Extracted tweet text for AI analysis
2. **APUS AI (Primary)**: On-chain AI processing attempt
3. **Task Queue**: Manages AI processing tasks and status
4. **Success Response**: Returns AI-generated score and reasoning
5. **Failure Detection**: Identifies when APUS AI processing fails
6. **Retry Logic**: Implements exponential backoff for retries
7. **Max Retries**: Limits retry attempts to prevent infinite loops
8. **OpenAI (GPT-4)**: Fallback AI processing for reliability
9. **Fallback Response**: Provides consistent AI analysis quality
10. **Final Response**: Returns processed result regardless of source

---

## 3. Component Interaction Diagrams

### 3.1 Twitter Bot Component Interactions

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Twitter       │    │   Rate          │    │   Content       │
│   API Client    │    │   Limiter       │    │   Processor     │
│                 │    │                 │    │                 │
│ • getTweet()    │◀───│ • sleep()       │◀───│ • extractData() │
│ • replyToTweet()│    │ • delay()       │    │ • validate()    │
│ • mentions()    │    │ • backoff()     │    │ • clean()       │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Database      │    │   Config        │    │   Error         │
│   Manager       │    │   Manager       │    │   Handler       │
│                 │    │                 │    │                 │
│ • storeTweet()  │    │ • loadConfig()  │    │ • handleError() │
│ • getTweet()    │    │ • validate()    │    • • logError()   │
│ • exists()      │    │ • reload()      │    • • retry()      │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

**Interaction Patterns:**
- **Synchronous**: Direct function calls for immediate operations
- **Asynchronous**: Promise-based operations for API calls
- **Event-driven**: Stream-based processing for Twitter mentions
- **Error handling**: Graceful degradation and fallback mechanisms

### 3.2 AI Processing Component Interactions

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Tweet         │    │   APUS AI       │    │   Task          │
│   Processor     │    │   Manager       │    │   Manager       │
│                 │    │                 │    │                 │
│ • process()     │───▶│ • analyze()     │───▶│ • create()      │
│ • validate()    │    │ • prompt()      │    │ • track()       │
│ • clean()       │    │ • response()    │    │ • status()      │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   OpenAI        │    │   Response      │    │   State         │
│   Manager       │    │   Processor     │    │   Manager       │
│                 │    │                 │    │                 │
│ • fallback()    │    │ • validate()    │    │ • persist()     │
│ • analyze()     │    │ • format()      │    │ • retrieve()    │
│ • error()       │    │ • structure()   │    │ • update()      │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

**Interaction Patterns:**
- **Primary/Fallback**: APUS AI first, OpenAI as backup
- **Task Management**: Asynchronous task tracking and status updates
- **State Persistence**: Maintains processing state across executions
- **Response Validation**: Ensures consistent output format

