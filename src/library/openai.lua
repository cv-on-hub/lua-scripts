--[[
$module OpenAI

Provides access to the OpenAI apis. To use them successfully, you need an
OpenAI account with an API Key. The safest and easiest place to put your API Key is
in the RGP Lua prefix for the script or the System Prefix in RGP Lua. Whichever
you choose, add this line to your script:

```
openai_api_key = "<your secure api key>"
```

This library assumes that there is a global string variable `openai_api_key` that contains
your API key.

This code sends an https post message to OpenAI, so your `plugindef()` function must include

```
finaleplugin.ExecuteHttpsCalls = true
```

The `callback_or_timeout` parameters in each function determine if the call is synchronous or
asynchronous. If it is a function, then this is the callback for an asynchronous call.
If it is a number, it is the timout in seconds for a synchronous call.
For synchronous calls, the function returns a session variable you should keep
as long as the call is running. The callback function should have the following signature

```
function my_callback(success, response)
```

- success (boolean) indicates if the function succeeded
- response (string) the table representing the json response from OpenAI on success or an error message on fail

For asynchronous calls, the function returns the same two values directly.

If you are calling this from a running dialog box, it is recommended to use async
calls for better user responsiveness. If there is no dialog box, synchronous calls are
okay as long as the timeout is reasonably short.
]]

local utils = require("library.utils")

local json = utils.require_embedded("cjson.safe")
local osutils = utils.require_embedded("luaosutils")
local https = osutils.internet

local ORIGIN = 'https://api.openai.com'
local API_VERSION = 'v1'
local OPEN_AI_URL = ORIGIN .. "/" ..API_VERSION
local COMPLETION_URL = OPEN_AI_URL .. "/chat/completions"
local CHAT_URL = OPEN_AI_URL .. "/chat"

openai_api_key = openai_api_key or "invalid key"

local openai = {}

local function call_openai(url, body, callback_or_timeout)

    local headers = {
        ["Content-Type"] = "application/json",
        ["Authorization"] = "Bearer " .. openai_api_key
    }

    local function internal_callback(success, result)
        local jsresult = json.decode(result)
        if not success then
            if  type(jsresult) == "table" then
                jsresult = jsresult.error.message
            else
                jsresult = result
            end
        end
        print("openai returned: "..result)
        if type(callback_or_timeout) == "function" then
            callback_or_timeout(success, jsresult)
        else
            return success, jsresult
        end
    end

    local body_str = json.encode(body)
    if type(callback_or_timeout) == "function" then
        return https.post(url, body_str, internal_callback, headers)
    elseif type(callback_or_timeout) == "number" then
        local success, result = https.post_sync(url, body_str, callback_or_timeout, headers)
        return internal_callback(success, result)
    else
        error("callback_or_timeout parameter must be function or number", 2)
    end

    return false, "should not get here"
end

--[[
% create_completion

Sends a request to the OpenAI API to generate a completion for a given prompt.

@ model (string) The model to use, e.g., "gpt-3.5-turbo"
@ prompt (string) The prompt to send
@ temperature (number) See the OpenAI documentation for information about this value. A reasonable value is between 1.0 and 2.0.
@ [callback_or_timeout] (function or number) Defaults to 5.0.
: (boolean) if synchronous call. See above for asynchronous.
: (string) if synchronous call. See above for asynchronous.
]]
function openai.create_completion(model, prompt, temperature, callback_or_timeout)
    callback_or_timeout = callback_or_timeout or 5.0

    local body = {
        model = model,
        messages = {{role = "user", content = prompt}},
        temperature = temperature
    }

    return call_openai(COMPLETION_URL, body, callback_or_timeout)
end

--[[
% create_chat

Sends a request to the OpenAI API to generate a completion for a given prompt.

@ model (string) The model to use, e.g., "gpt-3.5-turbo"
@ prompt (string) The prompt to send
@ temperature (number) A value between 0.0 and 1.0. See the OpenAI documentation for information.
@ max_tokens (number) The maximum number of tokens to generate
@ [callback_or_timeout] (function or number) Defaults to 5.0.
: (boolean) if synchronous call. See above for asynchronous.
: (string) if synchronous call. See above for asynchronous.
]]
function openai.create_chat(model, prompt, temperature, max_tokens, callback_or_timeout)
    callback_or_timeout = callback_or_timeout or 5.0

    local body = {
        model = model,
        prompt = prompt,
        temperature = temperature,
        max_tokens = max_tokens
    }

    return call_openai(CHAT_URL, body, callback_or_timeout)
end

return openai

