#!/bin/bash
# deploy.sh - Setup and deploy monitoring

# Install wrangler if not present
if ! command -v wrangler &> /dev/null; then
    npm install -g wrangler
fi

# Create KV namespace
echo "Creating KV namespace..."
wrangler kv:namespace create "STATS" --preview false

# Update wrangler.toml with the KV namespace ID from output above
echo "Update wrangler.toml with KV namespace ID"

# Deploy worker
echo "Deploying worker..."
wrangler publish

# Create monitoring dashboard page
cat > monitor.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
  <title>Alias Memorizer Stats</title>
  <meta http-equiv="refresh" content="0; url=/monitor">
</head>
<body>
  <p>Redirecting to monitor...</p>
</body>
</html>
EOF

echo "Setup complete!"
echo "Access monitoring at: https://alias.rotko.net/monitor"
echo "API stats at: https://alias.rotko.net/api/stats"
