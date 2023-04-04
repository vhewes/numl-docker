FROM ubuntu:20.04 AS base

# install basic packages
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y ack curl net-tools build-essential uuid-runtime && \
    apt-get clean

# environment vars
ENV CONDA_DIR=/usr/local/mambaforge
ENV PATH=$CONDA_DIR/bin:$PATH
ENV OMP_NUM_THREADS=16
ENV TORCH_CUDA_ARCH_LIST="6.0 6.1 7.0+PTX 8.6"
ENV TORCH_NVCC_FLAGS="-Xfatbin -compress-all"

# install mambaforge conda and dependencies
RUN curl -L -O "https://github.com/conda-forge/miniforge/releases/latest/download/Mambaforge-$(uname)-$(uname -m).sh" && \
    bash Mambaforge-$(uname)-$(uname -m).sh -b -p $CONDA_DIR && \
    rm Mambaforge-$(uname)-$(uname -m).sh && \
    conda config --set changeps1 False && \
    conda init
RUN conda install -y git vim htop ncdu build compilers automake ninja \
                     openblas openssh pyzmq zlib
RUN conda install -y PyYAML ipywidgets jupyterlab seaborn plotly numba \
                     particle mpi4py h5py=*=*mpich* uproot

# install ph5concat
RUN cd /usr/local && \
    git clone https://github.com/NU-CUCIS/ph5concat && \
    cd ph5concat && \
    autoreconf -i && \
    ./configure CFLAGS="-O2 -DNDEBUG" CXXFLAGS="-O2 -DNDEBUG" \
                LIBS="-ldl -lz" PREFIX=/usr/local --enable-profiling && \
    make install

# install pynuml
RUN pip install pynuml

FROM base AS pytorch

# install pytorch and related dependencies
ARG TORCH=1.13
ARG CUDA=11.7
RUN conda install -y pytorch::pytorch=$TORCH pytorch-cuda=$CUDA tensorboard torchmetrics \
                     pytorch-lightning pyg -c pytorch -c nvidia -c pyg
# manually install MinkowskiEngine
ENV CUDA_HOME=$CONDA_PREFIX
RUN conda install -y libcusolver-dev -c nvidia
RUN pip install -U git+https://github.com/NVIDIA/MinkowskiEngine -v --no-deps \
                --install-option="--blas_include_dirs=$CONDA_PREFIX/include" \
                --install-option="--blas=openblas" --install-option="--force_cuda"

# clone NOvA pandana into a temporary image
FROM pytorch AS pandana
ARG SSH_KEY
RUN mkdir /root/.ssh && \
    echo "$SSH_KEY" > /root/.ssh/id && \
    chmod 700 /root/.ssh/id && \
    eval $(ssh-agent) && \
    ssh-add /root/.ssh/id && \
    ssh-keyscan github.com >> ~/.ssh/known_hosts && \
    cd /usr/local && \
    git clone git@github.com:novaexperiment/NOvAPandAna

# install pandana and copy NOvA pandana from temporary image
FROM pytorch AS nova
RUN conda install -y boost-histogram
RUN cd /usr/local && \
    git clone https://github.com/HEPonHPC/pandana
COPY --from=pandana /usr/local/NOvAPandAna /usr/local/NOvAPandAna
