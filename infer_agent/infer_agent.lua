local json = require("json")

Tasks = Tasks or {}                      -- Process state where results are stored
TaskCounter = TaskCounter or 0           -- Simple counter for total tasks

-- Load the APUS AI library
ApusAI = require('@apus/ai')
print("DEBUG: APUS AI library loaded successfully")

print("DEBUG: Initial state - Tasks count: " .. tostring(TaskCounter))

local function constructPrompt(text)
    if not text then
        return "Invalid or missing tweet data"
    end
    
    -- Remove newlines from the tweet text and replace with spaces
    local cleanText = text:gsub("\n", " ")
    
    local basePrompt = "For this twit: '' "
    local endPrompt = " '' try to understand IQ level for the user and score it from min=60 to max=140. Give a short, 1-2 sentences explanation for your mark. Provide answer as json: {\"score\": 65, \"reasoning\": \"Nonsensical, inside joke\"}"
    
    return basePrompt .. cleanText .. endPrompt
end

-- Helper function to extract tweet data
local function extractTweetData(data)
    if not data then
        return nil
    end
    
    local success, parsed = pcall(json.decode, data)
    if success and parsed then
        return {
            user_name = parsed.user_name,
            tweet_id = parsed.tweet_id,
            user_id = parsed.user_id,
            text = parsed.text
        }
    end
    
    return nil
end

local function prepareOptions(msg, reference)
    local options = {}
    
    if msg["X-Session"] then
        options.session = msg["X-Session"]
    end
    
    if msg["X-Options"] then
        local table_options = json.decode(msg["X-Options"])
        for k, v in pairs(table_options) do
            options[k] = v
        end
    end
    
    -- Set default max_tokens if not provided
    if not options.max_tokens then
        options.max_tokens = 5000
    end
    
    options.reference = reference
    
    return options
end

local function createTask(reference, options, twit)
    local task = {
        options = options,
        session = options.session,
        reference = reference,
        status = "processing",
        starttime = os.time(),
    }
    
    -- Add twit data if available
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
    
    print("DEBUG: Total tasks in memory: " .. tostring(TaskCounter))
    
    return task
end

local function updatePatchDevice(tasks)
    print("DEBUG: Sending patch update...")
    Send({
        device = 'patch@1.0',
        cache = {
            tasks = tasks
        }
    })
end

local function handleSuccessResponse(reference, res)
    print("DEBUG: ApusAI.infer success response: " .. json.encode(res))
    
    if Tasks[reference] then
        -- Extract JSON from markdown code blocks if present
        local jsonData = res.data
        if res.data:match("```json") then
            -- Extract content between ```json and ```
            jsonData = res.data:match("```json\n?(.-)\n?```")
        end
        
        -- Parse the JSON response to extract score and reasoning
        local success, parsed = pcall(json.decode, jsonData)
        if success and parsed then
            Tasks[reference].response = {
                score = parsed.score,
                reasoning = parsed.reasoning
            }
        else
            -- Fallback: store raw response if parsing fails
            Tasks[reference].response = {
                score = nil,
                reasoning = res.data
            }
        end
        
        Tasks[reference].status = "success"
        Tasks[reference].session = res.session
        --Tasks[reference].attestation = res.attestation
        Tasks[reference].endtime = os.time()
        
        print("DEBUG: Twit: " .. Tasks[reference].twit.txt)
        print("DEBUG: Score: " .. tostring(Tasks[reference].response.score))
        print("DEBUG: Reasoning: " .. tostring(Tasks[reference].response.reasoning))
        
        updatePatchDevice({
            [reference] = Tasks[reference]
        })
    end
end

local function handleErrorResponse(reference, err)
    print("DEBUG: ApusAI.infer error: " .. json.encode(err))
    
    if Tasks[reference] then
        Tasks[reference].status = "failed"
        Tasks[reference].error_message = err.message or "Unknown error"
        Tasks[reference].endtime = os.time()
        
        print("DEBUG: Task updated with error")
        
        updatePatchDevice({
            [reference] = Tasks[reference]
        })
    end
end

-- Main Handler for making infer calls
Handlers.add(
    "Input",
    Handlers.utils.hasMatchingTag("Action", "Infer"),
    function(msg)
        print("DEBUG: === Input Handler Triggered ===")
        
        local twit = extractTweetData(msg.Data)
        
        local tweet_id = twit and twit.tweet_id or ""
        local reference = msg["X-Reference"] or (tweet_id .. "_" .. os.time())
        
        local prompt = constructPrompt(twit.text)
        local options = prepareOptions(msg, reference)
        
        createTask(reference, options, twit)
        updatePatchDevice({
            [reference] = Tasks[reference]
        })
        
        print("DEBUG: Calling ApusAI.infer with prompt and options")
        print("DEBUG: Prompt: " .. prompt)
        print("DEBUG: Options: " .. json.encode(options))
        
        ApusAI.infer(prompt, options, function(err, res)
            if err then
                handleErrorResponse(reference, err)
                return
            end
            
            handleSuccessResponse(reference, res)
        end)
        
        print("DEBUG: === Input Handler Completed ===")
    end
)

-- Handler to get Tasks data with pagination
Handlers.add(
    "GetTasks",
    Handlers.utils.hasMatchingTag("Action", "GetTasks"),
    function(msg)        
        -- Get pagination parameters from Tags array
        local start = 1
        local limit = 10
        
        if msg.Tags then
            if msg.Tags["Start"] then
                start = tonumber(msg.Tags["Start"]) or 1
            end
            if msg.Tags["Limit"] then
                limit = tonumber(msg.Tags["Limit"]) or 10
            end
        end
        
        -- Ensure valid parameters
        if start < 1 then start = 1 end
        if limit < 1 or limit > 100 then limit = 10 end  -- Max 100 per page
        
        -- Use the global TaskCounter instead of counting every time
        local total = TaskCounter
        
        -- Early exit if start is beyond total
        if start > total then
            local response = {
                start = start,
                limit = limit,
                total = total,
                count = 0,
                has_more = false,
                tasks = {}
            }
            msg.reply({Data = json.encode(response)})
            return
        end
        
        -- Convert tasks to array and sort by starttime (newest first)
        local taskArray = {}
        for reference, task in pairs(Tasks) do
            table.insert(taskArray, {reference = reference, task = task})
        end
        
        -- Sort by starttime (newest first)
        table.sort(taskArray, function(a, b)
            return a.task.starttime > b.task.starttime
        end)
        
        -- Get paginated tasks from sorted array
        local paginatedTasks = {}
        local count = 0
        
        for i = start, math.min(start + limit - 1, #taskArray) do
            if i <= #taskArray then
                local item = taskArray[i]
                paginatedTasks[item.reference] = item.task
                count = count + 1
            end
        end
        
        -- Prepare response
        local response = {
            start = start,
            limit = limit,
            total = total,
            count = count,
            has_more = (start + count - 1) < total,
            tasks = paginatedTasks
        }
        
        -- Send response
        msg.reply({Data = json.encode(response)})
    end
)

-- Handler to get a specific Task by tweet ID (tid)
Handlers.add(
    "GetTaskByTid",
    Handlers.utils.hasMatchingTag("Action", "GetTaskByTid"),
    function(msg)
        -- Get tweet ID from Tags
        local tweetId = nil
        if msg.Tags then
            tweetId = msg.Tags["Tid"] or msg.Tags["tid"]
        end
        
        if not tweetId then
            local response = {
                success = false,
                error = "Missing tweet ID parameter. Use Tags: { name = 'Tid', value = 'your_tweet_id' }"
            }
            msg.reply({Data = json.encode(response)})
            return
        end
        
        -- Search through all tasks to find the most recent matching tweet ID
        local foundTask = nil
        local foundReference = nil
        local latestTime = 0
        
        for reference, task in pairs(Tasks) do
            if task.twit and task.twit.tid == tweetId then
                -- Check if this task is more recent than what we've found so far
                if task.starttime > latestTime then
                    foundTask = task
                    foundReference = reference
                    latestTime = task.starttime
                end
            end
        end
        
        if foundTask then
            local response = {
                success = true,
                tweet_id = tweetId,
                reference = foundReference,
                task = foundTask,
                timestamp = latestTime
            }
            msg.reply({Data = json.encode(response)})
        else
            local response = {
                success = false,
                error = "No task found for tweet ID: " .. tweetId,
                tweet_id = tweetId
            }
            msg.reply({Data = json.encode(response)})
        end
    end
)


print("DEBUG: Infer Agent AO Process initialization completed - All handlers registered")
print("DEBUG: Available handlers: Input, GetTasks, GetTaskByTid")

-- Frontend workflow:
-- 1. User sends data to the Input handler with Action "Infer"
-- 2. Handler creates a task and calls ApusAI.infer with callback
-- 3. Response is handled directly in the callback and task is updated
-- 4. Tasks are stored in patch device for frontend access
-- 5. Frontend can query task status via Patch API
