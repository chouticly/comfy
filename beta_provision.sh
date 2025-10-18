#!/bin/bash

source /venv/main/bin/activate
COMFYUI_DIR=${WORKSPACE}/ComfyUI

# Packages are installed after nodes so we can fix them...

APT_PACKAGES=(
    #"package-1"
    #"package-2"
)

PIP_PACKAGES=(
    "gguf"
    #"package-2"
)

NODES=(
    #"https://github.com/kijai/ComfyUI-MochiWrapper"
    #"https://github.com/ltdrdata/ComfyUI-Manager"
    #"https://github.com/cubiq/ComfyUI_essentials"
    "https://github.com/MushroomFleet/DJZ-Nodes"
    "https://github.com/city96/ComfyUI-GGUF"
    "https://github.com/kijai/ComfyUI-WanVideoWrapper"
    "https://github.com/pythongosssss/ComfyUI-Custom-Scripts"
    "https://github.com/rgthree/rgthree-comfy"
    "https://github.com/WASasquatch/was-node-suite-comfyui"
    "https://github.com/yolain/ComfyUI-Easy-Use"
    "https://github.com/kijai/ComfyUI-KJNodes"
    "https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite"
    "https://github.com/melMass/comfy_mtb"
    "https://github.com/Derfuu/Derfuu_ComfyUI_ModdedNodes"
    "https://github.com/jamesWalker55/comfyui-various"
    "https://github.com/chibiace/ComfyUI-Chibi-Nodes"
    "https://github.com/lgldlk/ComfyUI-PC-ding-dong"
)

# --- ZIP Configuration ---
# 1. Define the URL for your main assets ZIP file
ASSETS_ZIP_URL="https://example.com/path/to/your/main_assets.zip" # **<- REPLACE THIS WITH YOUR ZIP URL**
# 2. Define the directory where the ZIP will be downloaded and extracted (a temporary staging area)
ASSETS_STAGING_DIR="${COMFYUI_DIR}/tmp_assets"

# 3. Define the mapping of folders INSIDE the ZIP to their final ComfyUI destination.
# Format: "ZIP_FOLDER_NAME:DESTINATION_PATH"
# NOTE: The keys must match the top-level directories within your ZIP file.
# The values are relative to $COMFYUI_DIR.
declare -A ASSETS_MAPPING
ASSETS_MAPPING=(
    ["workflows"]="user/default/workflows"
    ["loras"]="models/loras"
    ["unet"]="models/unet"
    ["vae"]="models/vae"
    ["clip"]="models/clip"
    ["diffusion_models"]="models/diffusion_models"
    ["clip_vision"]="models/clip_vision"
    ["text_encoders"]="models/text_encoders"
    ["gguf"]="models/gguf"
    # Add any other folders in your ZIP file here (e.g., "esrgan", "controlnet")
)

# --- Original model arrays are commented out as they're now in the ZIP ---
# WORKFLOWS=(
# 	"https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/example%20workflows_Wan2.1/text_to_video_wan.json"
# 	"https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/example%20workflows_Wan2.1/image_to_video_wan_480p_example.json"
# )
# ... all other model arrays (CLIP_MODELS, CHECKPOINT_MODELS, etc.) are removed/commented out

### DO NOT EDIT BELOW HERE UNLESS YOU KNOW WHAT YOU ARE DOING ###

function provisioning_start() {
    provisioning_print_header
    provisioning_get_apt_packages
    provisioning_get_nodes
    provisioning_get_pip_packages

    # --- ZIP Provisioning Steps ---
    provisioning_download_and_extract_zip
    provisioning_move_assets
    # --- End ZIP Provisioning Steps ---

    # The following block handles conditional HF models, so we'll keep it.
    # Note: These are still downloaded individually, as they are conditional.
    local workflows_dir="${COMFYUI_DIR}/user/default/workflows"
    local UNET_MODELS=()
    local VAE_MODELS=()
    if provisioning_has_valid_hf_token; then
        UNET_MODELS+=("https://huggingface.co/black-forest-labs/FLUX.1-dev/resolve/main/flux1-dev.safetensors")
        VAE_MODELS+=("https://huggingface.co/black-forest-labs/FLUX.1-dev/resolve/main/ae.safetensors")
    else
        UNET_MODELS+=("https://huggingface.co/black-forest-labs/FLUX.1-schnell/resolve/main/flux1-schnell.safetensors")
        VAE_MODELS+=("https://huggingface.co/black-forest-labs/FLUX.1-schnell/resolve/main/ae.safetensors")
        # Ensure the workflow file exists before modifying
        if [[ -f "${workflows_dir}/flux_dev_example.json" ]]; then
            sed -i 's/flux1-dev\.safetensors/flux1-schnell.safetensors/g' "${workflows_dir}/flux_dev_example.json"
        fi
    fi

    # Download the conditional models individually
    provisioning_get_files \
        "${COMFYUI_DIR}/models/unet" \
        "${UNET_MODELS[@]}"
    provisioning_get_files \
        "${COMFYUI_DIR}/models/vae" \
        "${VAE_MODELS[@]}"
    
    # All the original provisioning_get_files calls for the arrays (LORA_MODELS, etc.) 
    # are now replaced by the zip logic above.

    provisioning_print_end
}

# --- New Function: Download and Extract ZIP ---
function provisioning_download_and_extract_zip() {
    if [[ -z "$ASSETS_ZIP_URL" ]]; then
        printf "Asset ZIP URL is not set. Skipping ZIP provisioning.\n"
        return 0
    fi
    printf "Downloading asset ZIP from: %s\n" "${ASSETS_ZIP_URL}"
    mkdir -p "${ASSETS_STAGING_DIR}"
    
    # Use provisioning_download logic to download the ZIP file to the staging directory
    # We'll save it as 'assets.zip' in the staging dir
    local zip_file_path="${ASSETS_STAGING_DIR}/assets.zip"
    
    # Use the existing provisioning_download function (slightly modified for single file)
    # The existing provisioning_download is designed for wget, we'll leverage it.
    provisioning_download "${ASSETS_ZIP_URL}" "${ASSETS_STAGING_DIR}"
    
    # Check if the download was successful
    if [[ ! -f "$zip_file_path" ]]; then
        # The provisioning_download function uses --content-disposition, so the filename might be different.
        # Let's find the downloaded file in the staging directory.
        local downloaded_file=$(find "${ASSETS_STAGING_DIR}" -maxdepth 1 -type f -print -quit)
        if [[ -z "$downloaded_file" ]]; then
            printf "Error: Failed to download asset ZIP.\n"
            return 1
        fi
        zip_file_path="$downloaded_file"
    fi
    
    printf "Extracting %s to %s...\n" "${zip_file_path##*/}" "${ASSETS_STAGING_DIR}"
    # The 'unzip' command is required here. Assuming it's available in the environment.
    if ! command -v unzip &> /dev/null; then
        printf "Warning: 'unzip' command not found. Cannot extract assets ZIP. Trying to install...\n"
        sudo apt-get update && sudo apt-get install -y unzip
        if ! command -v unzip &> /dev/null; then
             printf "Error: 'unzip' installation failed. Cannot proceed with ZIP extraction.\n"
             return 1
        fi
    fi
    
    unzip -o -q "$zip_file_path" -d "${ASSETS_STAGING_DIR}"
    
    # Clean up the ZIP file
    rm -f "$zip_file_path"
    printf "Extraction complete.\n\n"
}

# --- New Function: Move Extracted Assets ---
function provisioning_move_assets() {
    printf "Moving extracted assets to final ComfyUI directories...\n"
    
    local success=true
    for zip_folder in "${!ASSETS_MAPPING[@]}"; do
        local relative_dest="${ASSETS_MAPPING[$zip_folder]}"
        local source_dir="${ASSETS_STAGING_DIR}/${zip_folder}"
        local dest_dir="${COMFYUI_DIR}/${relative_dest}"
        
        if [[ -d "$source_dir" ]]; then
            mkdir -p "$dest_dir"
            printf "Moving contents of '%s' to '%s'...\n" "${zip_folder}" "${relative_dest}"
            # Use 'mv' to move all contents (not the folder itself) to the destination
            mv -f "${source_dir}"/* "$dest_dir"/ 2>/dev/null
            if [ $? -ne 0 ]; then
                printf "Warning: Failed to move some contents from %s. May be empty.\n" "${zip_folder}"
            fi
        else
            printf "Warning: Folder '%s' not found in extracted ZIP. Skipping.\n" "${zip_folder}"
        fi
    done
    
    # Clean up the temporary staging directory
    rm -rf "${ASSETS_STAGING_DIR}"
    printf "\nAsset movement complete. Temporary files removed.\n"
}


function provisioning_get_apt_packages() {
    if [[ -n $APT_PACKAGES ]]; then
        sudo $APT_INSTALL ${APT_PACKAGES[@]}
    fi
}

function provisioning_get_pip_packages() {
    if [[ -n $PIP_PACKAGES ]]; then
        pip install --no-cache-dir ${PIP_PACKAGES[@]}
    fi
}

function provisioning_get_nodes() {
    for repo in "${NODES[@]}"; do
        dir="${repo##*/}"
        path="${COMFYUI_DIR}/custom_nodes/${dir}"
        requirements="${path}/requirements.txt"
        if [[ -d $path ]]; then
            if [[ ${AUTO_UPDATE,,} != "false" ]]; then
                printf "Updating node: %s...\n" "${repo}"
                ( cd "$path" && git pull )
                if [[ -e $requirements ]]; then
                   pip install --no-cache-dir -r "$requirements"
                fi
            fi
        else
            printf "Downloading node: %s...\n" "${repo}"
            git clone "${repo}" "${path}" --recursive
            if [[ -e $requirements ]]; then
                pip install --no-cache-dir -r "${requirements}"
            fi
        fi
    done
}

# This function is now only used for conditional/individual downloads
function provisioning_get_files() {
    if [[ -z $2 ]]; then return 1; fi
    
    dir="$1"
    mkdir -p "$dir"
    shift
    arr=("$@")
    printf "Downloading %s model(s) to %s...\n" "${#arr[@]}" "$dir"
    for url in "${arr[@]}"; do
        printf "Downloading: %s\n" "${url}"
        provisioning_download "${url}" "${dir}"
        printf "\n"
    done
}

function provisioning_print_header() {
    printf "\n##############################################\n#             Provisioning container           #\n#           This will take some time           #\n# Your container will be ready on completion #\n##############################################\n\n"
}

function provisioning_print_end() {
    printf "\nProvisioning complete: Application will start now\n\n"
}

function provisioning_has_valid_hf_token() {
    [[ -n "$HF_TOKEN" ]] || return 1
    url="https://huggingface.co/api/whoami-v2"

    response=$(curl -o /dev/null -s -w "%{http_code}" -X GET "$url" \
        -H "Authorization: Bearer $HF_TOKEN" \
        -H "Content-Type: application/json")

    # Check if the token is valid
    if [ "$response" -eq 200 ]; then
        return 0
    else
        return 1
    fi
}

function provisioning_has_valid_civitai_token() {
    [[ -n "$CIVITAI_TOKEN" ]] || return 1
    url="https://civitai.com/api/v1/models?hidden=1&limit=1"

    response=$(curl -o /dev/null -s -w "%{http_code}" -X GET "$url" \
        -H "Authorization: Bearer $CIVITAI_TOKEN" \
        -H "Content-Type: application/json")

    # Check if the token is valid
    if [ "$response" -eq 200 ]; then
        return 0
    else
        return 1
    fi
}

# Download from $1 URL to $2 directory path
function provisioning_download() {
    local auth_token=""
    local url="$1"
    local dir="$2"

    if [[ -n $HF_TOKEN && $url =~ ^https://([a-zA-Z0-9_-]+\.)?huggingface\.co(/|$|\?) ]]; then
        auth_token="$HF_TOKEN"
    elif [[ -n $CIVITAI_TOKEN && $url == https://civitai.com* ]]; then
        echo "Match found for Civitai, setting auth_token..."
        auth_token="$CIVITAI_TOKEN"
    fi
    
    local download_url="$url"
    local log_prefix="Doing Lame Download/No Match Found"

    if [[ -n $auth_token ]]; then
        log_prefix="Doing Cool Download"
        # Add token to URL for Civitai/HF (this is a common pattern for authentication)
        download_url="${url}?token=$auth_token"
    fi
    
    echo "$log_prefix"
    # The --content-disposition flag tells wget to use the filename suggested by the server
    # This is important for the ZIP to have the correct name or for the single files.
    # We remove -nc (no-clobber) for the ZIP download to ensure we always get the latest.
    if [[ "$url" == *".zip"* ]]; then
        wget -q --content-disposition --show-progress -e dotbytes="${3:-4M}" -P "$dir" "$download_url"
    else
        wget -qnc --content-disposition --show-progress -e dotbytes="${3:-4M}" -P "$dir" "$download_url"
    fi
}

# Allow user to disable provisioning if they started with a script they didn't want
if [[ ! -f /.noprovisioning ]]; then
    provisioning_start
fi
