FROM nvidia/cuda:8.0-cudnn5-devel

MAINTAINER jiandong <jjdblast@gmail.com>

ARG THEANO_VERSION=rel-0.8.2
ARG TENSORFLOW_VERSION=0.8.0
ARG TENSORFLOW_ARCH=gpu
ARG KERAS_VERSION=1.0.3

#RUN echo -e "\n**********************\nNVIDIA Driver Version\n**********************\n" && \
#   cat /proc/driver/nvidia/version && \
#   echo -e "\n**********************\nCUDA Version\n**********************\n" && \
#   nvcc -V && \
#   echo -e "\n\nBuilding your Deep Learning Docker Image...\n"

# Necessary packages and FFmpeg
RUN apt-get update && apt-get install -y \
    apt-utils \
    autoconf \
    automake \
        bc \
    bzip2 \
        build-essential \
    ca-certificates \
        cmake \
        curl \
    ffmpeg \
        g++ \
        gfortran \
        git \
    libass-dev \
    libatlas-base-dev \
    libavcodec-dev \
    libavformat-dev \
    libavresample-dev \
    libav-tools \
    libdc1394-22-dev \
        libffi-dev \
        libfreetype6-dev \
    libglib2.0-0 \
        libhdf5-dev \
    libjasper-dev \
        libjpeg-dev \
        liblapack-dev \
        liblcms2-dev \
        libopenblas-dev \
    libopencv-dev \
        libopenjpeg5 \
        libpng12-dev \
        libsdl1.2-dev \
    libsm6 \
        libssl-dev \
    libtheora-dev \
        libtiff5-dev \
    libtool \
    libva-dev \
    libvdpau-dev \
    libvorbis-dev \
    libvtk6-dev \
        libwebp-dev \
    libxcb1-dev \
    libxcb-shm0-dev \
    libxcb-xfixes0-dev \
    libxext6 \
    libxrender1 \
        libzmq3-dev \
        nano \
        pkg-config \
        python-dev \
    python-pycurl \
        software-properties-common \
    texinfo \
        unzip \
        vim \
    webp \
        wget \
        zlib1g-dev \
        && \
    apt-get clean && \
    apt-get autoremove && \
    rm -rf /var/lib/apt/lists/* && \
# Link BLAS library to use OpenBLAS using the alternatives mechanism (https://www.scipy.org/scipylib/building/linux.html#debian-ubuntu)
    update-alternatives --set libblas.so.3 /usr/lib/openblas-base/libblas.so.3

# Install pip
RUN curl -O https://bootstrap.pypa.io/get-pip.py && \
    python get-pip.py && \
    rm get-pip.py

# Add SNI support to Python
RUN pip --no-cache-dir install \
        pyopenssl \
        ndg-httpsclient \
        pyasn1



#############################################
# OpenCV 3 w/ Python 2.7 from Anaconda
#############################################

RUN cd ~/ &&\
    git clone https://github.com/opencv/opencv.git &&\
    git clone https://github.com/opencv/opencv_contrib.git &&\
    cd opencv && mkdir build && cd build && \
    cmake -D CMAKE_BUILD_TYPE=RELEASE \
          -D CUDA_CUDA_LIBRARY=/usr/local/cuda-8.0/targets/x86_64-linux/lib/stubs/libcuda.so \
          -D CMAKE_INSTALL_PREFIX=/opt/opencv \
          -D INSTALL_C_EXAMPLES=ON \
          -D INSTALL_PYTHON_EXAMPLES=ON \
          -D OPENCV_EXTRA_MODULES_PATH=~/opencv_contrib/modules \
          -D BUILD_EXAMPLES=ON \
          -D PYTHON_DEFAULT_EXECUTABLE=/opt/conda/bin/python2.7  BUILD_opencv_python2=True \
          -D PYTHON_LIBRARY=/opt/conda/lib/libpython2.7.so \
          -D PYTHON_INCLUDE_DIR=/opt/conda/include/python2.7 \
          -D PYTHON2_NUMPY_INCLUDE_DIRS=/opt/conda/lib/python2.7/site-packages/numpy/core/include \
          -D PYTHON_EXECUTABLE=/opt/conda/bin/python2.7 -DWITH_FFMPEG=ON \
          -D BUILD_SHARED_LIBS=ON .. &&\
    make -j4 && make install && ldconfig

ENV PYTHONPATH /opt/opencv/lib/python2.7/site-packages:$PYTHONPATH






# Install TensorFlow
RUN pip --no-cache-dir install \
    https://storage.googleapis.com/tensorflow/linux/${TENSORFLOW_ARCH}/tensorflow-${TENSORFLOW_VERSION}-cp27-none-linux_x86_64.whl


# Install Theano and set up Theano config (.theanorc) for CUDA and OpenBLAS
RUN pip --no-cache-dir install git+git://github.com/Theano/Theano.git@${THEANO_VERSION} && \
    \
    echo "[global]\ndevice=gpu\nfloatX=float32\noptimizer_including=cudnn\nmode=FAST_RUN \
        \n[lib]\ncnmem=0.95 \
        \n[nvcc]\nfastmath=True \
        \n[blas]\nldflag = -L/usr/lib/openblas-base -lopenblas \
        \n[DebugMode]\ncheck_finite=1" \
    > /root/.theanorc


# Install Keras
RUN pip --no-cache-dir install git+git://github.com/fchollet/keras.git@${KERAS_VERSION}

# Set up notebook config
COPY jupyter_notebook_config.py /root/.jupyter/

# Jupyter has issues with being run directly: https://github.com/ipython/ipython/issues/7062
COPY run_jupyter.sh /root/

# Expose Ports for TensorBoard (6006), Ipython (8888)
EXPOSE 6006 8888

WORKDIR "/root"
CMD ["/bin/bash"]
