# ComfyUI Vast.ai Template 🚀

This is a template for running ComfyUI on vast.ai. It comes with a number of custom nodes and models pre-installed, and can be easily customized to add your own.

## Features

* **Pre-installed custom nodes:** A number of popular custom nodes are pre-installed, so you can get started right away.
* **Pre-installed models:** A selection of models are pre-installed, including Stable Diffusion 1.5 and various VAEs.
* **Automatic updates:** Custom nodes are automatically updated to the latest version on startup.
* **Hugging Face and Civitai support:** You can use your Hugging Face and Civitai tokens to download private models.
* **Easy to customize:** You can easily add your own custom nodes and models by editing the `provision.sh` script.

## How to use

1. Create a new instance on [vast.ai](https://vast.ai/).
2. When creating the instance, select the "Run a container image" option and enter `vastai/pytorch` as the image name.
3. In the "On-start script" field, enter the following:

   ```bash
   curl -sSL https://raw.githubusercontent.com/your-username/your-repo/main/onstart.sh | bash
   ```

   (Replace `your-username` and `your-repo` with your GitHub username and repository name.)

4. In the "Environment variables" section, add the following variables:

   * `PROVISIONING_SCRIPT`: The URL to your `provision.sh` script. For example: `https://raw.githubusercontent.com/your-username/your-repo/main/provision.sh`
   * `HF_TOKEN` (optional): Your Hugging Face token.
   * `CIVITAI_TOKEN` (optional): Your Civitai token.

5. Start the instance. The `onstart.sh` script will be executed, which will in turn execute the `provision.sh` script. The provisioning script will download and install all the custom nodes and models.

## Models

### Checkpoint Models

* https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/diffusion_models/wan2.1_i2v_480p_14B_bf16.safetensors

### Clip Models

* https://huggingface.co/comfyanonymous/flux_text_encoders/resolve/main/clip_l.safetensors
* https://huggingface.co/comfyanonymous/flux_text_encoders/resolve/main/t5xxl_fp16.safetensors

### VAE Models

* https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/vae/wan_2.1_vae.safetensors
* https://huggingface.co/black-forest-labs/FLUX.1-dev/resolve/main/ae.safetensors (if you have a valid Hugging Face token)
* https://huggingface.co/black-forest-labs/FLUX.1-schnell/resolve/main/ae.safetensors (if you don't have a valid Hugging Face token)

### LoRA Models

* https://civitai.com/api/download/models/1517164 (bouncing boots i2v-14b)
* https://civitai.com/api/download/models/1590896 (easy nsfw wan21)
* https://civitai.com/api/download/models/1475095 (wan general nsfw)
* https://civitai.com/api/download/models/1539326 (wan furry titfuck)
* https://civitai.com/api/download/models/1734893 (Taker POV)
* https://civitai.com/api/download/models/1807318 (penis masturbation)
* https://civitai.com/api/download/models/1728992 (expansion)

### UNET Models

* https://huggingface.co/black-forest-labs/FLUX.1-dev/resolve/main/flux1-dev.safetensors (if you have a valid Hugging Face token)
* https://huggingface.co/black-forest-labs/FLUX.1-schnell/resolve/main/flux1-schnell.safetensors (if you don't have a valid Hugging Face token)

### Clip Vision Models

* https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/clip_vision/clip_vision_h.safetensors

### Text Encoder Models

* https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors

## Custom Nodes

* https://github.com/MushroomFleet/DJZ-Nodes
* https://github.com/city96/ComfyUI-GGUF
* https://github.com/kijai/ComfyUI-WanVideoWrapper
* https://github.com/pythongosssss/ComfyUI-Custom-Scripts
* https://github.com/rgthree/rgthree-comfy
* https://github.com/WASasquatch/was-node-suite-comfyui
* https://github.com/yolain/ComfyUI-Easy-Use
* https://github.com/kijai/ComfyUI-KJNodes
* https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite
* https://github.com/melMass/comfy_mtb
* https://github.com/Derfuu/Derfuu_ComfyUI_ModdedNodes
* https://github.com/jamesWalker55/comfyui-various
* https://github.com/chibiace/ComfyUI-Chibi-Nodes
* https://github.com/lgldlk/ComfyUI-PC-ding-dong
