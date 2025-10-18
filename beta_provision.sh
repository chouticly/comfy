#!/bin/bash

source /venv/main/bin/activate
COMFYUI_DIR=${WORKSPACE}/ComfyUI

# Set this environment variable to 'false' (e.g., export USE_ZIP_PROVISIONING=false)
# if you want to skip the ZIP download and fall back to individual file downloads.
USE_ZIP_PROVISIONING=${USE_ZIP_PROVISIONING:-true}

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
# REPLACE THIS WITH YOUR DIRECT GOOGLE DRIVE DOWNLOAD LINK
ASSETS_ZIP_URL="https://drive.google.com/uc?export=download&id=YOUR_FOLDER_ID_HERE&confirm=t"
ASSETS_STAGING_DIR="${COMFYUI_DIR}/tmp_assets"

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
)
# --- End ZIP Configuration ---


# --- Individual File Configuration (Will run after ZIP or as fallback) ---
WORKFLOWS=(
    "https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/example%20workflows_Wan2.1/text_to_video_wan.json"
    "https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/example%20workflows_Wan2.1/image_to_video_wan_480p_example.json"
)

CLIP_MODELS=(
    "https://huggingface.co/comfyanonymous/flux_text_encoders/resolve/main/clip_l.safetensors"
    "https://huggingface.co/comfyanonymous/flux_text_encoders/resolve/main/t5xxl_fp16.safetensors"
)

CHECKPOINT_MODELS=(
    "https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/diffusion_models/wan2.1_i2v_480p_14B_bf16.safetensors"
    #"https://huggingface.co/Comfy-Org/stable-diffusion-v1-5-archive/resolve/main/v1-5-pruned-emaonly-fp16.safetensors"
)

UNET_MODELS=(
)

LORA_MODELS=(
    "https://civitai.com/api/download/models/1517164" #bouncing boots i2v-14b
    "https://civitai.com/api/download/models/1590896" #easy nsfw wan21
    "https://civitai.com/api/download/models/1475095" #wan general nsfw
    "https://civitai.com/api/download/models/1539326" #wan furry titfuck
    "https://civitai.com/api/download/models/1734893" #Taker POV
    "https://civitai.com/api/download/models/1807318" #penis masturbation
    "https://civitai.com/api/download/models/1728992" #expansion
)

VAE_MODELS=(
    "https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/vae/wan_2.1_vae.safetensors"
)

ESRGAN_MODELS=(
)

CONTROLNET_MODELS=(
)

CLIPVISION_MODELS=(
    "https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/clip_vision/clip_vision_h.safetensors"
)

TEXT_ENCODERS=(
    "https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors"
)
# --- End Individual File Configuration ---

### DO NOT EDIT BELOW HERE UNLESS YOU KNOW WHAT YOU ARE DOING ###

function provisioning_start() {
    provisioning_print_header
    provisioning_get_apt_packages
    provisioning_get_nodes
    provisioning_get_pip_packages

    workflows_dir="${COMFYUI_DIR}/user/default/workflows"
    mkdir -p "${workflows_dir}"
    
    local zip_success=false
    local run_individual_downloads=true

    # --- 1. ZIP PROVISIONING ATTEMPT ---
    if [[ "${USE_ZIP_PROVISIONING,,}" == "true" ]]; then
        printf "\n✅ Attempting ZIP Provisioning for core assets...\n"
        if provisioning_download_and_extract_zip && provisioning_move_assets; then
            zip_success=true
            printf "\nZIP Provisioning **SUCCESSFUL**. Proceeding to supplementary downloads.\n"
        else
            printf "\nZIP Provisioning **FAILED**. Falling back to running all individual file downloads.\n"
        fi
    else
        printf "\n⚠️ ZIP Provisioning explicitly disabled. Running all individual file downloads.\n"
    fi
    # --- END ZIP PROVISIONING ATTEMPT ---

    # --- 2. INDIVIDUAL FILE PROVISIONING (Always runs unless explicitly disabled or error) ---
    # This block now runs ALL individual downloads regardless of zip_success, 
    # ensuring all models in the arrays are eventually downloaded.

    printf "\nStarting supplementary/fallback individual file downloads...\n"
    
    provisioning_get_files \
        "${workflows_dir}" \
        "${WORKFLOWS[@]}"
    
    provisioning_get_files \
        "${COMFYUI_DIR}/models/loras" \
        "${LORA_MODELS[@]}"
    
    provisioning_get_files \
        "${COMFYUI_DIR}/models/vae" \
        "${VAE_MODELS[@]}"
    
    provisioning_get_files \
        "${COMFYUI_DIR}/models/clip" \
        "${CLIP_MODELS[@]}"
    
    provisioning_get_files \
        "${COMFYUI_DIR}/models/diffusion_models" \
        "${CHECKPOINT_MODELS[@]}"
    
    provisioning_get_files \
        "${COMFYUI_DIR}/models/clip_vision" \
        "${CLIPVISION_MODELS[@]}"
    
    provisioning_get_files \
        "${COMFYUI_DIR}/models/text_encoders" \
        "${TEXT_ENCODERS[@]}"

    # --- 3. CONDITIONAL HF TOKEN DOWNLOADS (Always runs) ---
    # This block handles conditional models and always runs, as per the original script.
    local UNET_MODELS_CONDITIONAL=()
    local VAE_MODELS_CONDITIONAL=()
    local flux_workflow_present=false
    
    # Check if the flux workflow was downloaded either by ZIP or individually
    if [[ -f "${workflows_dir}/flux_dev_example.json" ]]; then
        flux_workflow_present=true
    fi

    if provisioning_has_valid_hf_token; then
        UNET_MODELS_CONDITIONAL+=("https://huggingface.co/black-forest-labs/FLUX.1-dev/resolve/main/flux1-dev.safetensors")
        VAE_MODELS_CONDITIONAL+=("https://huggingface.co/black-forest-labs/FLUX.1-dev/resolve/main/ae.safetensors")
    else
        UNET_MODELS_CONDITIONAL+=("https://huggingface.co/black-forest-labs/FLUX.1-schnell/resolve/main/flux1-schnell.safetensors")
        VAE_MODELS_CONDITIONAL+=("https://huggingface.co/black-forest-labs/FLUX.1-schnell/resolve/main/ae.safetensors")
        # Update workflow name if present
        if [[ "${flux_workflow_present}" == "true" ]]; then
            sed -i 's/flux1-dev\.safetensors/flux1-schnell.safetensors/g' "${workflows_dir}/flux_dev_example.json"
        fi
    fi
    
    provisioning_get_files \
        "${COMFYUI_DIR}/models/unet" \
        "${UNET_MODELS_CONDITIONAL[@]}"
    provisioning_get_files \
        "${COMFYUI_DIR}/models/vae" \
        "${VAE_MODELS_CONDITIONAL[@]}"

    provisioning_print_end
}
---
## 💡 Key Functions (Unchanged from Previous Response)
---

function provisioning_download_and_extract_zip() {
    if [[ -z "$ASSETS_ZIP_URL" || "$ASSETS_ZIP_URL" == *YOUR_FOLDER_ID_HERE* ]]; then
        printf "Error: Asset ZIP URL is not properly set. ZIP provisioning aborted.\n"
        return 1
    fi
    printf "Downloading asset ZIP from: %s\n" "${ASSETS_ZIP_URL}"
    mkdir -p "${ASSETS_STAGING_DIR}"

    local zip_file_path="${ASSETS_STAGING_DIR}/assets.zip"
    provisioning_download "${ASSETS_ZIP_URL}" "${ASSETS_STAGING_DIR}"

    local downloaded_file=$(find "${ASSETS_STAGING_DIR}" -maxdepth 1 -type f -print -quit)
    if [[ -z "$downloaded_file" ]]; then
        printf "Error: Failed to download asset ZIP. Check the URL and permissions.\n"
        return 1
    fi
    zip_file_path="$downloaded_file"

    printf "Extracting %s to %s...\n" "${zip_file_path##*/}" "${ASSETS_STAGING_DIR}"
    if ! command -v unzip &> /dev/null; then
        printf "Warning: 'unzip' command not found. Installing now...\n"
        sudo apt-get update && sudo apt-get install -y unzip
        if ! command -v unzip &> /dev/null; then
             printf "Error: 'unzip' installation failed. Cannot proceed with ZIP extraction.\n"
             return 1
        fi
    fi

    unzip -o -q "$zip_file_path" -d "${ASSETS_STAGING_DIR}"

    rm -f "$zip_file_path"
    printf "Extraction complete.\n"
}

function provisioning_move_assets() {
    printf "Moving extracted assets to final ComfyUI directories...\n"

    for zip_folder in "${!ASSETS_MAPPING[@]}"; do
        local relative_dest="${ASSETS_MAPPING[$zip_folder]}"
        local source_dir="${ASSETS_STAGING_DIR}/${zip_folder}"
        local dest_dir="${COMFYUI_DIR}/${relative_dest}"

        if [[ -d "$source_dir" ]]; then
            mkdir -p "$dest_dir"
            printf "Moving contents of '%s' to '%s'...\n" "${zip_folder}" "${relative_dest}"
            mv -f "${source_dir}"/* "$dest_dir"/ 2>/dev/null
        else
            printf "Warning: Folder '%s' not found in extracted ZIP. Skipping.\n" "${zip_folder}"
        fi
    done

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

    if [ "$response" -eq 200 ]; then
        return 0
    else
        return 1
    fi
}

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
        download_url="${url}?token=$auth_token"
    fi

    echo "$log_prefix"
    # Use -q for quiet, --content-disposition to respect filename from server
    if [[ "$url" == *".zip"* || "$url" == *"/uc?export=download"* ]]; then
        # Remove -nc (no-clobber) for the ZIP/Folder download to ensure we get a fresh copy
        wget -q --content-disposition --show-progress -e dotbytes="${3:-4M}" -P "$dir" "$download_url"
    else
        # Use -nc (no-clobber) for individual files to skip re-downloading existing files
        wget -qnc --content-disposition --show-progress -e dotbytes="${3:-4M}" -P "$dir" "$download_url"
    fi
}

# Allow user to disable provisioning if they started with a script they didn't want
if [[ ! -f /.noprovisioning ]]; then
    provisioning_start
fi
