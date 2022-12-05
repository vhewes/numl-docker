ARG PYTORCH="1.12.1"
ARG CUDA="11.6"

FROM nvidia/cuda:${CUDA}.0-devel-ubuntu20.04

ARG PYTORCH
ARG CUDA

# install basic packages
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y ack curl net-tools build-essential && \
    apt-get clean

# environment vars
ENV CONDA_DIR=/usr/local/mambaforge
ENV PATH=$CONDA_DIR/bin:$PATH
ENV CUDA_HOME=/usr/local/cuda
ENV OMP_NUM_THREADS=16
ENV TORCH_CUDA_ARCH_LIST="6.0 6.1 7.0+PTX 8.6"
ENV TORCH_NVCC_FLAGS="-Xfatbin -compress-all"

# install mambaforge conda and dependencies
RUN curl -L -O "https://github.com/conda-forge/miniforge/releases/latest/download/Mambaforge-$(uname)-$(uname -m).sh" && \
    bash Mambaforge-$(uname)-$(uname -m).sh -b -p $CONDA_DIR && \
    rm Mambaforge-$(uname)-$(uname -m).sh && \
    conda config --set changeps1 False && \
    conda init
RUN conda install -y git vim htop ncdu build compilers automake ninja openblas
RUN conda install -y PyYAML ipywidgets jupyterlab seaborn plotly numba particle \
                     mpi4py h5py=*=*mpich* uproot
RUN conda install pytorch=$PYTORCH=*cuda${CUDA}* -c pytorch
RUN conda install tensorboard torchmetrics pytorch-lightning

# install ph5concat
RUN cd /usr/local && \
    git clone https://github.com/NU-CUCIS/ph5concat && \
    cd ph5concat && \
    autoreconf -i && \
    ./configure CFLAGS="-O2 -DNDEBUG" CXXFLAGS="-O2 -DNDEBUG" \
                LIBS="-ldl -lz" PREFIX=/usr/local --enable-profiling && \
    make install

# install MinkowskiEngine
RUN pip install -U git+https://github.com/StanfordVL/MinkowskiEngine -v --no-deps \
  --install-option="--force_cuda" --install-option="--blas=openblas" \
  --install-option="--blas_include_dirs=${CONDA_DIR}/include"

# install PyTorch Geometric
RUN cugeo=$(echo $CUDA | tr -d .) && \
    pip install torch-scatter -f https://pytorch-geometric.com/whl/torch-${PYTORCH}+cu${cugeo}.html && \
    pip install torch-sparse -f https://pytorch-geometric.com/whl/torch-${PYTORCH}+cu${cugeo}.html && \
    pip install torch-geometric

# install numl packages
RUN pip install pynuml

