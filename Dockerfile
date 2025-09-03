# ---- Stage 1: CUDA Ubuntu, amd64 ----
FROM --platform=linux/amd64 nvidia/cuda:12.4.1-cudnn-runtime-ubuntu22.04 AS builder

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates wget bzip2 && rm -rf /var/lib/apt/lists/*

# Install Miniforge (x86_64)
ENV CONDA_DIR=/opt/conda
RUN wget -q https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-x86_64.sh -O /tmp/miniforge.sh \
 && bash /tmp/miniforge.sh -b -p "$CONDA_DIR" \
 && rm -f /tmp/miniforge.sh
ENV PATH="$CONDA_DIR/bin:$PATH"

# Use conda-forge only
RUN conda config --system --add channels conda-forge \
 && conda config --system --set channel_priority strict

# Target environment prefix
ENV ENV_PREFIX=/opt/conda-pytorch

# Create the environment with Python + PyTorch
RUN mkdir -p "$ENV_PREFIX" \
 && conda create -y -p "$ENV_PREFIX" python=3.11 pytorch \
 && conda clean -afy

# Optional: quick sanity check
# RUN "$ENV_PREFIX/bin/python" -c "import torch; print(torch.__version__)"

# ---- Stage 2: scratch carrier image ----
FROM scratch

# Copy only the environment directory to the same absolute path
COPY --from=builder /opt/conda-pytorch /opt/conda-pytorch

# Expose env on PATH (optional, useful if a later stage uses it)
# ENV PATH="/opt/conda-pytorch/bin:${PATH}"

# scratch cannot run Python, so no CMD here.
