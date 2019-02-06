FROM ikeyasu/opengl:ubuntu16.04
MAINTAINER ikeyasu <ikeyasu@gmail.com>

ENV DEBIAN_FRONTEND oninteractive

############################################
# Basic dependencies
############################################
RUN apt-get update --fix-missing && apt-get install -y \
      python3-numpy python3-matplotlib python3-dev \
      python3-opengl python3-pip \
      cmake zlib1g-dev libjpeg-dev xvfb libav-tools \
      xorg-dev libboost-all-dev libsdl2-dev swig \
      git wget openjdk-8-jdk ffmpeg unzip\
    && apt-get clean && rm -rf /var/cache/apt/archives/* /var/lib/apt/lists/*

############################################
# Change the working directory
############################################
WORKDIR /opt

############################################
# OpenAI Gym and Keras
# It seems that keras always use the module installed last. 
# https://github.com/fchollet/keras/issues/6997
############################################
RUN pip3 install --upgrade pip
RUN pip3 install h5py keras future pyvirtualdisplay 'gym[atari]' 'gym[box2d]' 'gym[classic_control]'

############################################
# Roboschool
############################################
RUN apt-get update && apt-get install -y \
      git cmake ffmpeg pkg-config \
      qtbase5-dev libqt5opengl5-dev libassimp-dev \
      libpython3.5-dev libboost-python-dev libtinyxml-dev \
    && apt-get clean && rm -rf /var/cache/apt/archives/* /var/lib/apt/lists/* \
    && git clone --depth 1 https://github.com/olegklimov/bullet3 -b roboschool_self_collision \
    && git clone --depth 1 https://github.com/openai/roboschool

ENV ROBOSCHOOL_PATH /opt/roboschool

RUN mkdir -p /opt/bullet3/build \
    && cd /opt/bullet3/build \
    && cmake -DBUILD_SHARED_LIBS=ON -DUSE_DOUBLE_PRECISION=1 \
       -DCMAKE_INSTALL_PREFIX:PATH=${ROBOSCHOOL_PATH}/roboschool/cpp-household/bullet_local_install \
       -DBUILD_CPU_DEMOS=OFF -DBUILD_BULLET2_DEMOS=OFF \
       -DBUILD_EXTRAS=OFF  -DBUILD_UNIT_TESTS=OFF \
       -DBUILD_CLSOCKET=OFF -DBUILD_ENET=OFF \
       -DBUILD_OPENGL3_DEMOS=OFF .. \
    && make \
    && make install \
    && pip3 install -e ${ROBOSCHOOL_PATH} \
    && ldconfig \
    && make clean

############################################
# marlo
############################################

RUN pip3 install -U malmo
RUN pip3 install -U marlo

RUN cd /opt \
    && python3 -c 'import malmo.minecraftbootstrap; malmo.minecraftbootstrap.download()' \
    && chown -R user:user MalmoPlatform/

ENV MALMO_MINECRAFT_ROOT /opt/MalmoPlatform/Minecraft

############################################
# Deep Reinforcement Learning
#    OpenAI Baselines
#    Keras-RL
#    ChainerRL
############################################
RUN pip3 install keras-rl opencv-python
RUN pip3 install chainer==5.1.0 chainerrl==0.5.0

# Need to remove mujoco dependency from baselines
RUN git clone --depth 1 https://github.com/openai/baselines.git \
    && sed --in-place 's/mujoco,//' baselines/setup.py \
    && pip3 install mpi4py cloudpickle

############################################
# Tensorflow (CPU)
############################################
RUN pip3 install tensorflow==1.8

############################################
# locate, less, lxterminal, and vim
############################################
RUN apt-get update && apt-get install -y mlocate less vim lxterminal mesa-utils\
    && updatedb\
    && apt-get clean && rm -rf /var/cache/apt/archives/* /var/lib/apt/lists/*

ENV APP "lxterminal -e bash"
