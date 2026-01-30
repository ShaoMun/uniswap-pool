#!/bin/bash

echo "🚀 Starting SimplePool Frontend..."
echo ""
echo "Opening http://localhost:8000"
echo ""
echo "Press Ctrl+C to stop the server"
echo ""

# Check if Python 3 is available
if command -v python3 &> /dev/null; then
    cd frontend && python3 -m http.server 8000
elif command -v python &> /dev/null; then
    cd frontend && python -m SimpleHTTPServer 8000
else
    echo "❌ Python not found. Please install Python or use a different server."
    echo ""
    echo "Alternative: Just open frontend/index.html directly in your browser."
    exit 1
fi
