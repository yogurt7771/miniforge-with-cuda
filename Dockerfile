ARG CUDA_TAG=11.8.0
ARG PYTHON_VER=3.11
ARG TZ=Asia/Shanghai
FROM nvidia/cuda:${CUDA_TAG}


ARG DEBIAN_FRONTEND=noninteractive
ENV PATH=/opt/conda/bin:$PATH
ENV PYTHON_VERSION=${PYTHON_VER}
ENV TZ=${TZ}

# install base tools
RUN apt-get update \
    && apt-get upgrade -y \
    && apt-get install -y --no-install-recommends \
    build-essential \
    cmake \
    git \
    curl \
    wget \
    psmisc \
    coreutils \
    iproute2 \
    ca-certificates \
    libjpeg-dev \
    libpng-dev \
    tmux \
    libgl1-mesa-glx \
    x11-apps \
    xorg \
    xterm \
    tzdata \
    libnuma1 libnuma-dev
# install github cli
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
    && chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
    && apt-get update \
    && apt-get install gh -y
RUN gh extension install github/gh-copilot \
# cleanup & update
RUN apt-get clean \
    && rm -rf "/var/lib/apt/lists/*" \
    && apt-get update

# Download and install the latest Miniforge
RUN wget -qO- "https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-x86_64.sh" -O /tmp/miniforge.sh \
    && /bin/bash /tmp/miniforge.sh -b -p /opt/conda \
    && rm /tmp/miniforge.sh

RUN \
    # ensure conda environment is always activated
    ln -s /opt/conda/etc/profile.d/conda.sh /etc/profile.d/conda.sh; \
    echo ". /opt/conda/etc/profile.d/conda.sh; conda activate base" >> /etc/skel/.bashrc; \
    echo ". /opt/conda/etc/profile.d/conda.sh; conda activate base" >> ~/.bashrc;

# enable color
RUN sed -i 's/#force_color_prompt=yes/force_color_prompt=yes/g' /root/.bashrc
