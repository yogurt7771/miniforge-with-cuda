ARG CUDA_TAG=11.8.0
FROM nvidia/cuda:${CUDA_TAG}

ARG LINUX_VER
ARG PYTHON_VER=3.11
ARG DEBIAN_FRONTEND=noninteractive
ENV PATH=/opt/conda/bin:$PATH
ENV PYTHON_VERSION=${PYTHON_VER}

# Create a conda group and assign it as root's primary group
RUN groupadd conda; \
    usermod -g conda root

# Download and install the latest Miniforge
RUN wget -qO- "https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-x86_64.sh" -O /tmp/miniforge.sh \
    && /bin/bash /tmp/miniforge.sh -b -p /opt/conda \
    && rm /tmp/miniforge.sh \
    && chmod 770 /opt/conda -R \
    && chown root:conda /opt/conda -R

# Ensure new files are created with group write access & setgid. See https://unix.stackexchange.com/a/12845
RUN chmod g+ws /opt/conda

RUN \
    # Ensure new files/dirs have group write/setgid permissions
    umask g+ws; \
    # install expected Python version
    mamba install -y -n base python="${PYTHON_VERSION}"; \
    mamba update --all -y -n base; \
    find /opt/conda -follow -type f -name '*.a' -delete; \
    find /opt/conda -follow -type f -name '*.pyc' -delete; \
    conda clean -afy;

# Reassign root's primary group to root
RUN usermod -g root root

RUN \
    # ensure conda environment is always activated
    ln -s /opt/conda/etc/profile.d/conda.sh /etc/profile.d/conda.sh; \
    echo ". /opt/conda/etc/profile.d/conda.sh; conda activate base" >> /etc/skel/.bashrc; \
    echo ". /opt/conda/etc/profile.d/conda.sh; conda activate base" >> ~/.bashrc;

RUN apt-get update \
    && apt-get upgrade -y \
    && apt-get install -y --no-install-recommends \
    build-essential \
    cmake \
    git \
    curl \
    wget \
    psmisc \
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
    libnuma1 libnuma-dev \
    # install github cli
    && curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
    && chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
    && apt-get update \
    && apt-get install gh -y \
    && gh extension install github/gh-copilot \
    # cleanup
    && apt-get clean \
    && rm -rf "/var/lib/apt/lists/*"
