FROM ubuntu:16.04

ADD l_openvino_toolkit* /openvino/

ARG INSTALL_DIR=/opt/intel/openvino

RUN apt-get update && apt-get -y upgrade && apt-get autoremove

#Install needed dependences
RUN apt-get install -y --no-install-recommends \
        build-essential \
        cpio \
        curl \
        git \
        lsb-release \
        pciutils \
        python3.5 \
        python3.5-dev \
        python3-pip \
        python3-setuptools \
        udev \
        sudo

# installing OpenVINO dependencies
RUN cd /openvino/l_openvino_toolkit* && \
    ./install_openvino_dependencies.sh

RUN pip3 install numpy

# installing OpenVINO itself
RUN cd /openvino/l_openvino_toolkit* && \
    sed -i 's/decline/accept/g' silent.cfg && \
    ./install.sh --silent silent.cfg

# Model Optimizer
RUN cd $INSTALL_DIR/deployment_tools/model_optimizer/install_prerequisites && \
    ./install_prerequisites.sh

# Install OpenCL Driver
RUN sudo usermod -a -G video "$(whoami)" && \
    cd $INSTALL_DIR/install_dependencies && \
    ./install_NEO_OCL_driver.sh

# Step for Movidius Neural Compute Stick
RUN sudo usermod -a -G users "$(whoami)" && \
    sudo cp /opt/intel/openvino/inference_engine/external/97-myriad-usbboot.rules /etc/udev/rules.d/ && \
    sudo udevadm control --reload-rules && \
    sudo udevadm trigger && \
    sudo ldconfig; exit 0

# clean up
RUN apt autoremove -y && \
    rm -rf /openvino /var/lib/apt/lists/*

RUN /bin/bash -c "source $INSTALL_DIR/bin/setupvars.sh"

RUN echo "source $INSTALL_DIR/bin/setupvars.sh" >> /root/.bashrc

CMD ["/bin/bash"]
