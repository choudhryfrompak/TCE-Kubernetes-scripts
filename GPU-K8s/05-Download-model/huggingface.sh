#!/bin/bash

echo "🤗 HuggingFace Setup and Model Download Script"
echo "============================================="

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to install Python packages
install_package() {
    echo "📦 Installing $1..."
    pip install "$1" --break-system-packages
}

# Check and install required packages
echo "🔍 Checking and installing required packages..."

# Install python3-pip if not present
if ! command_exists pip3; then
    echo "Installing pip3..."
    apt-get update
    apt-get install -y python3-pip
fi

# Install required packages
REQUIRED_PACKAGES=("huggingface_hub")

for package in "${REQUIRED_PACKAGES[@]}"; do
    install_package "$package"
done

# Setup HuggingFace credentials
echo -e "\n🔑 HuggingFace Token Setup"
echo "------------------------"
echo "Please enter your HuggingFace token (from https://huggingface.co/settings/tokens):"
read -s HUGGING_FACE_TOKEN

if [ -z "$HUGGING_FACE_TOKEN" ]; then
    echo "❌ Token cannot be empty"
    exit 1
fi

# Configure huggingface-cli
echo -e "\n⚙️ Configuring HuggingFace CLI..."
huggingface-cli login --token $HUGGING_FACE_TOKEN

# Get model name from user
echo -e "\n📥 Model Download"
echo "---------------"
echo "Please enter the model name (e.g., 'mistralai/Ministral-8B-Instruct-2410'):"
read MODEL_NAME

if [ -z "$MODEL_NAME" ]; then
    echo "❌ Model name cannot be empty"
    exit 1
fi

# Create Python script for downloading the model
cat << EOF > download_model.py
from huggingface_hub import snapshot_download
import os

def download_model(model_id):
    try:
        print(f"📥 Downloading model: {model_id}")
        path = snapshot_download(
            repo_id=model_id,
            token=os.environ.get('HUGGING_FACE_TOKEN'),
            ignore_patterns=["*.md", "*.txt"],
            local_dir=f"root/.cache/huggingface/hub/{model_id.split('/')[-1].lower()}",
            local_dir_use_symlinks=False
        )
        print(f"✅ Model downloaded successfully to: {path}")
        return path
    except Exception as e:
        print(f"❌ Error downloading model: {str(e)}")
        raise

if __name__ == "__main__":
    import sys
    model_id = sys.argv[1]
    download_model(model_id)
EOF

# Export token for the Python script
export HUGGING_FACE_TOKEN=$HUGGING_FACE_TOKEN

# Run the download script
echo -e "\n📥 Starting model download..."
python3 download_model.py "$MODEL_NAME"

# Cleanup
rm download_model.py

echo -e "\n✅ Setup complete!"
echo "You can find your downloaded model in the '/root/.cache/huggingface/hub/' directory"
echo "The HuggingFace token has been configured globally"

