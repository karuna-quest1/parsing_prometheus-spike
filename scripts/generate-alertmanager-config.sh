#!/bin/bash

set -e

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

ENV_FILE="$REPO_ROOT/.env"
TEMPLATE_PATH="$REPO_ROOT/alertmanager/alertmanager.yml"
OUTPUT_PATH="$REPO_ROOT/alertmanager/alertmanager.generated.yml"

# Function to print errors
print_error() {
    echo "ERROR: $1" >&2
    exit 1
}

# Function to print info
print_info() {
    echo "[INFO] $1"
}

# Check if .env file exists
if [ ! -f "$ENV_FILE" ]; then
    print_error "Missing .env file at $ENV_FILE"
fi

# Check if template file exists
if [ ! -f "$TEMPLATE_PATH" ]; then
    print_error "Missing Alertmanager template at $TEMPLATE_PATH"
fi

# Create output directory if it doesn't exist
OUTPUT_DIR="$(dirname "$OUTPUT_PATH")"
if [ ! -d "$OUTPUT_DIR" ]; then
    mkdir -p "$OUTPUT_DIR"
fi

# Remove the file if it exists (in case it was created as a directory)
if [ -d "$OUTPUT_PATH" ]; then
    print_error "Found a directory at $OUTPUT_PATH but expected a file. Please remove it and try again."
fi

if [ -f "$OUTPUT_PATH" ]; then
    rm "$OUTPUT_PATH"
fi

# Function to parse .env file and return a value for a given key
# This handles spaces around the = sign and quoted values
get_env_value() {
    local key="$1"
    local line
    local value
    
    # Find the line with the key
    line=$(grep "^[[:space:]]*${key}[[:space:]]*=" "$ENV_FILE" | head -1)
    
    if [ -z "$line" ]; then
        echo ""
        return
    fi
    
    # Extract value (everything after the first =)
    value="${line#*=}"
    
    # Remove leading spaces
    value="${value#"${value%%[![:space:]]*}"}"
    
    # Remove surrounding quotes (handles both single and double quotes)
    if [[ "$value" == \"* ]]; then
        value="${value#\"}"
        value="${value%\"}"
    elif [[ "$value" == \'* ]]; then
        value="${value#\'}"
        value="${value%\'}"
    fi
    
    echo "$value"
}

# Read the template file
TEMPLATE=$(cat "$TEMPLATE_PATH")

# Extract all ${VAR_NAME} patterns and check if they exist in .env
MISSING_VARS=()
while IFS= read -r line; do
    # Find all ${VAR_NAME} patterns
    while [[ $line =~ \$\{([A-Za-z_][A-Za-z0-9_]*)\} ]]; do
        var_name="${BASH_REMATCH[1]}"
        # Check if variable exists in .env file
        if ! grep -q "^[[:space:]]*${var_name}[[:space:]]*=" "$ENV_FILE"; then
            # Only add if not already in array
            if [[ ! " ${MISSING_VARS[@]} " =~ " ${var_name} " ]]; then
                MISSING_VARS+=("$var_name")
            fi
        fi
        # Remove the matched variable from line to find the next one
        line="${line#*${BASH_REMATCH[0]}}"
    done
done < "$TEMPLATE_PATH"

# Report missing variables
if [ ${#MISSING_VARS[@]} -gt 0 ]; then
    MISSING_LIST=$(IFS=', '; echo "${MISSING_VARS[*]}")
    print_error "Missing required .env values for Alertmanager config: $MISSING_LIST"
fi

# Function to replace environment variables in a string
replace_env_vars() {
    local content="$1"
    
    # Use a more robust method to replace variables
    # This finds all ${VAR_NAME} patterns and replaces them with their values from .env
    while [[ $content =~ \$\{([A-Za-z_][A-Za-z0-9_]*)\} ]]; do
        var_name="${BASH_REMATCH[1]}"
        var_value=$(get_env_value "$var_name")
        
        # Use bash parameter expansion for substitution (no sed escaping needed)
        # This safely replaces the first occurrence of ${var_name} with its value
        content="${content/\$\{$var_name\}/$var_value}"
    done
    
    echo "$content"
}

# Generate the config by replacing all environment variables
GENERATED=$(replace_env_vars "$TEMPLATE")

# Write the generated config to the output file
echo "$GENERATED" > "$OUTPUT_PATH"

print_info "Generated Alertmanager config at $OUTPUT_PATH"
