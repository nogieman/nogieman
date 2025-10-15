#!/bin/bash

# Create directory if it doesn't exist
mkdir -p static/images/projects

# Download placeholder images for projects
curl -o static/images/projects/ai-assistant.jpg https://source.unsplash.com/random/800x450/?ai,technology
curl -o static/images/projects/search-engine.jpg https://source.unsplash.com/random/800x450/?search,data
curl -o static/images/projects/collab-tool.jpg https://source.unsplash.com/random/800x450/?collaboration,teamwork
curl -o static/images/projects/blockchain-voting.jpg https://source.unsplash.com/random/800x450/?blockchain,security

echo "Images downloaded successfully!" 