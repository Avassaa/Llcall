llcall() {
    local api_url="https://api.groq.com/openai/v1/chat/completions"
    local api_key="<API_KEY>"
    local chat_log_file="$HOME/groq_chat_log.txt"

    if [[ ! -f "$chat_log_file" ]]; then
        touch "$chat_log_file"
    fi

    flush_chat_log() {
        > "$chat_log_file"
        echo "Chat log flushed. Exiting."
        exit 0
    }

    trap flush_chat_log SIGINT

    local messages=(
        '{"role": "system", "content": "You are a helpful assistant asked to interact based on the conversation’s context."}'
    )

    while true; do
        echo -n "Avassa: "
        read -r user_input
        user_input=$(echo "$user_input" | tr -d '\000-\031')
        local escaped_user_input
        escaped_user_input=$(jq -Rn --arg user_input "$user_input" '$user_input')
        messages+=("{\"role\": \"user\", \"content\": $escaped_user_input}")
        local payload=$(jq -n --argjson messages "$(printf '%s\n' "${messages[@]}" | jq -s .)" '{messages: $messages, model: "llama3-8b-8192"}')
        #echo "Payload being sent to API: $payload"
        local response
        response=$(curl -s -X POST "$api_url" \
            -H "Content-Type: application/json" \
            -H "Authorization: Bearer $api_key" \
            -d "$payload")
        local assistant_message
        assistant_message=$(echo "$response" | jq -r '.choices[0].message.content')
        assistant_message=$(echo "$assistant_message" | tr -d '\000-\031')
        echo "Groq: $assistant_message" | tee -a "$chat_log_file"
        local escaped_assistant_message
        escaped_assistant_message=$(jq -Rn --arg assistant_message "$assistant_message" '$assistant_message')
  messages+=("{\"role\": \"assistant\", \"content\": $escaped_assistant_message}")
        if [[ ${#messages[@]} -gt 12 ]]; then
            messages=("${messages[@]: -12}")
        fi
    done
}
