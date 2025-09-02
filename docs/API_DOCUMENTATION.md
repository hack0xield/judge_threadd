# API Documentation: SocialFi NFT-Pill System

## Table of Contents
1. [Overview](#1-overview)
2. [Authentication](#2-authentication)
3. [Twitter API Integration](#3-twitter-api-integration)
4. [OpenAI API Integration](#4-openai-api-integration)
5. [AO Network API](#5-ao-network-api)
6. [Error Handling](#6-error-handling)
7. [Rate Limiting](#7-rate-limiting)

---

## 1. Overview

The SocialFi NFT-Pill System provides comprehensive APIs for integrating with Twitter, OpenAI, and the AO blockchain network. This documentation covers all external API integrations and internal endpoints.

### 1.1 Base URLs
- **Twitter API**: `https://x.com/i/api/graphql/`
- **OpenAI API**: `https://api.openai.com/v1/`
- **AO Network**: Arweave-based decentralized computing
- **Local API**: `http://localhost:3000/api/`

### 1.2 API Versioning
- **Twitter API**: GraphQL endpoints (latest version)
- **OpenAI API**: v1 (latest stable)
- **AO Network**: Latest Arweave protocol version
- **Local API**: v1

---

## 2. Authentication

### 2.1 Twitter API Authentication

#### 2.1.1 Required Headers
```javascript
const headers = {
  Authorization: `Bearer ${config.tautht0}`,
  "X-Csrf-Token": config.tcsrft0,
  Cookie: `auth_token=${config.tautht1}; ct0=${config.tcsrft0}`
};
```

**Header Components**:
- **Authorization**: Bearer token for API access
- **X-Csrf-Token**: CSRF protection token
- **Cookie**: Session authentication cookies

#### 2.1.2 Token Management
```javascript
// Load configuration from file
const config = JSON.parse(fs.readFileSync("config.json"));

// Required tokens
const requiredTokens = {
  tautht0: "Twitter Bearer Token",
  tcsrft0: "Twitter CSRF Token", 
  tautht1: "Twitter Auth Token"
};
```

### 2.2 OpenAI API Authentication

#### 2.2.1 API Key Authentication
```javascript
const openaiHeaders = {
  "Content-Type": "application/json",
  Authorization: `Bearer ${config.openait}`
};
```

**Authentication Method**: Bearer token in Authorization header  
**Token Type**: OpenAI API key  
**Security**: HTTPS required for all requests  

### 2.3 AO Network Authentication

#### 2.3.1 Arweave Wallet Authentication
```javascript
const aosig = ao.createSigner(config["arweave-keyfile"]);
```

**Authentication Method**: Arweave wallet keyfile  
**Key Format**: JSON wallet file  
**Network**: Arweave mainnet/testnet  

---

## 3. Twitter API Integration

### 3.1 Mentions Timeline API

#### 3.1.1 Endpoint
```
GET https://x.com/i/api/graphql/l6ovGrjBwVobgU4puBCycg/NotificationsTimeline
```

#### 3.1.2 Request Parameters
```javascript
const reqv = {
  timeline_type: "Mentions",
  count: 20
};

const reqf = {
  rweb_video_screen_enabled: false,
  payments_enabled: false,
  rweb_xchat_enabled: false,
  profile_label_improvements_pcf_label_in_post_enabled: true,
  rweb_tipjar_consumption_enabled: true,
  verified_phone_label_enabled: false,
  creator_subscriptions_tweet_preview_api_enabled: true,
  responsive_web_graphql_timeline_navigation_enabled: true,
  responsive_web_graphql_skip_user_profile_image_extensions_enabled: false,
  premium_content_api_read_enabled: false,
  communities_web_enable_tweet_community_results_fetch: true,
  c9s_tweet_anatomy_moderator_badge_enabled: true,
  responsive_web_grok_analyze_button_fetch_trends_enabled: false,
  responsive_web_grok_analyze_post_followups_enabled: true,
  responsive_web_jetfuel_frame: true,
  responsive_web_grok_share_attachment_enabled: true,
  articles_preview_enabled: true,
  responsive_web_edit_tweet_api_enabled: true,
  graphql_is_translatable_rweb_tweet_is_translatable_enabled: true,
  view_counts_everywhere_api_enabled: true,
  longform_notetweets_consumption_enabled: true,
  responsive_web_twitter_article_tweet_consumption_enabled: true,
  tweet_awards_web_tipping_enabled: false,
  responsive_web_grok_show_grok_translated_post: false,
  responsive_web_grok_analysis_button_from_backend: true,
  creator_subscriptions_quote_tweet_preview_enabled: false,
  freedom_of_speech_not_reach_fetch_enabled: true,
  standardized_nudges_misinfo: true,
  tweet_with_visibility_results_prefer_gql_limited_actions_policy_enabled: true,
  longform_notetweets_rich_text_read_enabled: true,
  longform_notetweets_inline_media_enabled: true,
  responsive_web_grok_image_annotation_enabled: true,
  responsive_web_grok_imagine_annotation_enabled: true,
  responsive_web_grok_community_note_auto_translation_is_enabled: false,
  responsive_web_enhance_cards_enabled: false
};
```

#### 3.1.3 Response Structure
```javascript
const response = {
  data: {
    viewer_v2: {
      user_results: {
        result: {
          notification_timeline: {
            timeline: {
              instructions: [
                {
                  type: "TimelineAddEntries",
                  entries: [
                    {
                      entryId: "notification-123",
                      content: {
                        itemContent: {
                          tweet_results: {
                            result: {
                              legacy: {
                                id_str: "123456789",
                                in_reply_to_status_id_str: "987654321",
                                full_text: "Tweet content here"
                              }
                            }
                          }
                        }
                      }
                    }
                  ]
                }
              ]
            }
          }
        }
      }
    }
  }
};
```

#### 3.1.4 Rate Limiting
- **Delay**: 10 seconds between requests
- **Implementation**: Built-in sleep function
- **Purpose**: Prevent Twitter API rate limit violations

### 3.2 Tweet Detail API

#### 3.2.1 Endpoint
```
GET https://x.com/i/api/graphql/oEUIqhz9YZjZVpE5i68Sfg/TweetDetail
```

#### 3.2.2 Request Parameters
```javascript
const reqv = {
  focalTweetId: tweetId,
  referrer: "tweet",
  with_rux_injections: false,
  rankingMode: "Relevance",
  includePromotedContent: true,
  withCommunity: true,
  withQuickPromoteEligibilityTweetFields: true,
  withBirdwatchNotes: true,
  withVoice: true
};

const reqf = {
  // Same features object as Mentions API
};

const reqt = {
  withArticleRichContentState: true,
  withArticlePlainText: false,
  withGrokAnalyze: false,
  withDisallowedReplyControls: false
};
```

#### 3.2.3 Response Processing
```javascript
const tweetData = response.data.threaded_conversation_with_injections_v2.instructions
  .find((i) => i.type == "TimelineAddEntries")
  .entries.filter((e) => e.entryId.startsWith("tweet-"))
  .slice(-1)[0].content.itemContent.tweet_results.result;

const processedTweet = {
  user_name: tweetData.core.user_results.result.core.screen_name,
  tweet_id: tweetData.legacy.id_str,
  user_id: tweetData.legacy.user_id_str,
  text: tweetData.legacy.full_text
};
```

### 3.3 Create Tweet API

#### 3.3.1 Endpoint
```
POST https://x.com/i/api/graphql/mGOM24dT4fPg08ByvrpP2A/CreateTweet
```

#### 3.3.2 Request Body
```javascript
const requestBody = {
  variables: {
    tweet_text: replyText,
    reply: { 
      in_reply_to_tweet_id: tweetId, 
      exclude_reply_user_ids: [] 
    },
    dark_request: false,
    media: { 
      media_entities: [], 
      possibly_sensitive: false 
    },
    semantic_annotation_ids: [],
    disallowed_reply_options: null
  },
  features: {
    // Comprehensive feature set for full API compatibility
    premium_content_api_read_enabled: false,
    communities_web_enable_tweet_community_results_fetch: true,
    c9s_tweet_anatomy_moderator_badge_enabled: true,
    responsive_web_grok_analyze_button_fetch_trends_enabled: false,
    responsive_web_grok_analyze_post_followups_enabled: true,
    responsive_web_jetfuel_frame: true,
    responsive_web_grok_share_attachment_enabled: true,
    responsive_web_grok_edit_tweet_api_enabled: true,
    graphql_is_translatable_rweb_tweet_is_translatable_enabled: true,
    view_counts_everywhere_api_enabled: true,
    longform_notetweets_consumption_enabled: true,
    responsive_web_twitter_article_tweet_consumption_enabled: true,
    tweet_awards_web_tipping_enabled: false,
    responsive_web_grok_show_grok_translated_post: false,
    responsive_web_grok_analysis_button_from_backend: true,
    creator_subscriptions_quote_tweet_preview_enabled: false,
    longform_notetweets_rich_text_read_enabled: true,
    longform_notetweets_inline_media_enabled: true,
    payments_enabled: false,
    rweb_xchat_enabled: false,
    profile_label_improvements_pcf_label_in_post_enabled: true,
    rweb_tipjar_consumption_enabled: true,
    verified_phone_label_enabled: false,
    articles_preview_enabled: true,
    responsive_web_grok_community_note_auto_translation_is_enabled: false,
    responsive_web_graphql_skip_user_profile_image_extensions_enabled: false,
    freedom_of_speech_not_reach_fetch_enabled: true,
    standardized_nudges_misinfo: true,
    tweet_with_visibility_results_prefer_gql_limited_actions_policy_enabled: true,
    responsive_web_grok_image_annotation_enabled: true,
    responsive_web_grok_imagine_annotation_enabled: true,
    responsive_web_graphql_timeline_navigation_enabled: true,
    responsive_web_enhance_cards_enabled: false
  },
  queryId: "mGOM24dT4fPg08ByvrpP2A"
};
```

#### 3.3.3 Rate Limiting
- **Delay**: 120 seconds between requests
- **Implementation**: Built-in sleep function
- **Purpose**: Prevent Twitter API abuse and rate limiting

---

## 4. OpenAI API Integration

### 4.1 Chat Completions API

#### 4.1.1 Endpoint
```
POST https://api.openai.com/v1/chat/completions
```

#### 4.1.2 Request Body
```javascript
const requestBody = {
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
};
```

#### 4.1.3 Response Structure
```javascript
const response = {
  data: {
    output: [
      {
        content: [
          {
            text: '{"score": 85, "reasoning": "Clear communication with some logical reasoning, but limited depth of analysis."}'
          }
        ]
      }
    ]
  }
};

// Parse JSON response
const aiResult = JSON.parse(response.data.output[0].content[0].text);
```

#### 4.1.4 Error Handling
```javascript
try {
  const openaiResponse = await axios.post(
    "https://api.openai.com/v1/chat/completions",
    requestBody,
    { headers: openaiHeaders }
  );
  return JSON.parse(openaiResponse.data.output[0].content[0].text);
} catch (error) {
  console.error("OpenAI API Error:", error.message);
  throw new Error(`OpenAI API failed: ${error.message}`);
}
```

---

## 5. AO Network API

### 5.1 Message Sending

#### 5.1.1 Send Message
```javascript
const aoSendMessage = async (to, action, message) =>
  await ao.message({
    process: to,
    signer: aosig,
    data: message,
    tags: [{ name: "Action", value: action }]
  });
```

**Parameters**:
- **to**: Target AO process ID
- **action**: Action type (e.g., "Infer", "GetTaskByTid")
- **message**: JSON payload data

**Response**: Message ID for tracking

#### 5.1.2 Process Configuration
```javascript
const aosig = ao.createSigner(config["arweave-keyfile"]);
const aopid = "MMs2Ycxq46Pz3mC2bhz--4XFbPQjiDvR-9g-qKaxg2s";
```

### 5.2 Dry Run Operations

#### 5.2.1 Task Status Check
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
  
  if (!res.success) {
    throw new Error("failed to get task: " + tweetId);
  }
  
  return res.task;
};
```

**Purpose**: Simulate message execution without state changes  
**Use Case**: Check task completion status  
**Return Value**: Task object with status and response  

### 5.3 Message Tags

#### 5.3.1 Standard Tags
```javascript
const standardTags = [
  { name: "Action", value: "Infer" },           // Primary action
  { name: "Tid", value: tweetId },              // Tweet ID
  { name: "Timestamp", value: Date.now() },     // Timestamp
  { name: "Source", value: "twitter-bot" }      // Source identifier
];
```

**Tag Structure**: Key-value pairs for message routing  
**Required Tags**: Action and Tweet ID  
**Optional Tags**: Timestamp, source, metadata  

---

## 6. Error Handling

### 6.1 Twitter API Errors

#### 6.1.1 Rate Limit Errors
```javascript
try {
  const response = await twGet(url);
  return response.data;
} catch (error) {
  if (error.response?.status === 429) {
    // Rate limit exceeded
    await sleep(60); // Wait 1 minute
    return await twGet(url); // Retry
  }
  throw error;
}
```

#### 6.1.2 Authentication Errors
```javascript
if (error.response?.status === 401) {
  console.error("Twitter authentication failed");
  // Reload configuration or refresh tokens
  await refreshTwitterTokens();
}
```

### 6.2 OpenAI API Errors

#### 6.2.1 API Key Errors
```javascript
if (error.response?.status === 401) {
  throw new Error("Invalid OpenAI API key");
}
```

#### 6.2.2 Rate Limit Errors
```javascript
if (error.response?.status === 429) {
  const retryAfter = error.response.headers['retry-after'];
  await sleep(parseInt(retryAfter) || 60);
  return await judgeOffChain(tweet);
}
```

### 6.3 AO Network Errors

#### 6.3.1 Process Errors
```javascript
try {
  const task = await getTask(tweetId);
  return task;
} catch (error) {
  console.error("AO process error:", error.message);
  // Fallback to OpenAI
  return await judgeOffChain(tweet);
}
```

#### 6.3.2 Network Errors
```javascript
if (error.code === 'NETWORK_ERROR') {
  console.error("AO network connection failed");
  // Implement exponential backoff
  await sleep(wait);
  wait *= 2;
  retries -= 1;
}
```

### 6.4 General Error Handling

#### 6.4.1 Error Logging
```javascript
const logger = {
  error: (message, error) => {
    console.error(`[ERROR] ${message}:`, error);
    // Log to file or external service
  },
  
  warn: (message) => {
    console.warn(`[WARN] ${message}`);
  },
  
  info: (message) => {
    console.info(`[INFO] ${message}`);
  }
};
```

#### 6.4.2 Retry Logic
```javascript
const retryWithBackoff = async (fn, maxRetries = 3, baseDelay = 1000) => {
  for (let i = 0; i < maxRetries; i++) {
    try {
      return await fn();
    } catch (error) {
      if (i === maxRetries - 1) throw error;
      
      const delay = baseDelay * Math.pow(2, i);
      await sleep(delay / 1000);
    }
  }
};
```

---

## 7. Rate Limiting

### 7.1 Twitter API Rate Limits

#### 7.1.1 GET Requests
```javascript
const twGet = async (url) => {
  await sleep(10); // 10-second delay
  const res = await axios.get(url, { headers });
  return res.data;
};
```

**Rate Limit**: 10 seconds between requests  
**Purpose**: Prevent API rate limit violations  
**Implementation**: Built-in sleep function  

#### 7.1.2 POST Requests
```javascript
const twPost = async (url, data) => {
  await sleep(120); // 120-second delay
  const res = await axios.post(url, data, { headers });
  return res.data;
};
```

**Rate Limit**: 120 seconds between requests  
**Purpose**: Prevent tweet posting abuse  
**Implementation**: Built-in sleep function  

### 7.2 OpenAI API Rate Limits

#### 7.2.1 Request Throttling
```javascript
// OpenAI doesn't have strict rate limits like Twitter
// But we implement reasonable delays for good API citizenship
const openaiRequest = async (data) => {
  // Small delay between requests
  await sleep(1);
  return await axios.post(openaiEndpoint, data, { headers: openaiHeaders });
};
```

### 7.3 AO Network Rate Limits

#### 7.3.1 Message Rate Limiting
```javascript
// AO network has minimal rate limits
// But we implement delays for system stability
const aoMessage = async (to, action, message) => {
  await sleep(1); // 1-second delay
  return await ao.message({ process: to, signer: aosig, data: message, tags: [{ name: "Action", value: action }] });
};
```

### 7.4 Adaptive Rate Limiting

#### 7.4.1 Exponential Backoff
```javascript
const adaptiveDelay = async (baseDelay, multiplier = 2, maxDelay = 300) => {
  let currentDelay = baseDelay;
  
  return {
    delay: async () => {
      await sleep(currentDelay);
      currentDelay = Math.min(currentDelay * multiplier, maxDelay);
    },
    
    reset: () => {
      currentDelay = baseDelay;
    }
  };
};
```

#### 7.4.2 Dynamic Rate Limiting
```javascript
const rateLimiter = {
  delays: {
    twitter: { get: 10, post: 120 },
    openai: { request: 1 },
    ao: { message: 1 }
  },
  
  async delay(service, operation) {
    const delay = this.delays[service]?.[operation] || 1;
    await sleep(delay);
  }
};
```
