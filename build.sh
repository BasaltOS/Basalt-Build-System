#!/bin/bash

OUTPUT="bbuild"

echo "Creating $OUTPUT..."

# Clear the output file
> "$OUTPUT"

# Add license at the top
if [[ -f license_template.txt ]]; then
    cat license_template.txt >> "$OUTPUT"
    echo "" >> "$OUTPUT"
else
    echo "Missing license_template.txt — skipping license"
fi

# Add shebang
echo "#!/bin/sh" >> "$OUTPUT"
echo "" >> "$OUTPUT"

# Function to process .sh file
process_file() {
    local file="$1"

    awk '
        BEGIN {build=0}
        /^# === BUILD AREA START ===/ {build=1; next}
        /^# === BUILD AREA END ===/   {build=0; next}
        build && !/^#/ && NF > 0 { print }
    ' "$file" >> "$OUTPUT"

    echo "" >> "$OUTPUT"
}

# Process all *.sh files except build.sh and final.sh
for file in sources/*.sh; do
    echo "Processing $file..."
    process_file "$file"
done

chmod +x "$OUTPUT"
echo "✅ Ready: $OUTPUT"
