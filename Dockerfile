FROM ubuntu:18.04
LABEL maintainer “t.kaku <jyaou_shingan@yahoo.co.jp>”

RUN apt update && apt install -y --no-install-recommends \
    build-essential \
    cmake \
    git \
    wget \
    openssl \
    vim \
    htop \
    ca-certificates \
    python3.6 \
    python3.6-dev \
    python3-pip \
    python3-setuptools \
    # libgflags-dev \
    # liblmdb-dev \
    # libsnappy-dev \
    # libssl-dev \
    # libncurses5-dev \
    # libreadline-dev \
    # libgdm-dev \
    # libdb4o-cil-dev \
    # libpcap-dev \
    && rm -rf /var/lib/apt/lists/*

# Python 3.6 source build
# RUN mkdir /tmp/Python36
# WORKDIR /tmp/Python36

# RUN openssl s_client -connect www.python.org:443 -debug
# RUN wget https://www.python.org/ftp/python/3.6.0/Python-3.6.0.tar.xz
# RUN tar xvf Python-3.6.0.tar.xz
# WORKDIR /tmp/Python36/Python-3.6.0
# RUN ./configure
# RUN make altinstall

# alias
# RUN echo 'alias python3=python3.6' >> ~/.bash_aliases
# RUN echo 'alias pip3=pip3.6' >> ~/.bash_aliases

# mecab
RUN apt update && apt install -y --no-install-recommends \
    mecab \
    libmecab-dev \
    file \
    curl \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /opt/modules

RUN git clone --depth 1 https://github.com/neologd/mecab-ipadic-neologd.git mecab-ipadic-neologd
WORKDIR /opt/modules/mecab-ipadic-neologd
RUN ./bin/install-mecab-ipadic-neologd -y -n -p "$(dirname $(mecab -D | awk 'NR==1 {print $2}'))"


# #install fasttext
WORKDIR /opt/modules
RUN git clone https://github.com/facebookresearch/fastText.git fasttext
WORKDIR /opt/modules/fasttext
RUN pip3 install .

# python modules
RUN pip3 install --upgrade pip
WORKDIR /opt/modules/build
COPY requirements.txt /opt/modules/build/requirements.txt
RUN pip3 install -r requirements.txt
RUN python3.6 -m ipykernel.kernelspec

RUN echo "export MECAB_TAGGER_DIR=/opt/modules/mecab-ipadic-neologd/build/$(echo -n `ls /opt/modules/mecab-ipadic-neologd/build | grep neologd`)" >> ~/.bashrc

RUN apt update && apt install language-pack-ja -y && rm -rf /var/lib/apt/lists/*

# Install nodejs
# ENV NODE_VERSION v10.10.0
# RUN curl -L git.io/nodebrew | perl - setup && \
#     echo 'export PATH=/root/.nodebrew/current/bin:$PATH' >> ~/.bashrc
# ENV PATH /root/.nodebrew/current/bin:$PATH
#RUN source $HOME/.bashrc && \
#    nodebrew install-binary $NODE_VERSION && \
#    nodebrew use $NODE_VERSION

#RUN . $HOME/.bashrc && nodebrew install-binary $NODE_VERSION && \
#    . $HOME/.bashrc && nodebrew use $NODE_VERSION

# RUN nodebrew install-binary $NODE_VERSION && nodebrew use $NODE_VERSION

# Set up Jupyter Notebook config
ENV CONFIG /root/.jupyter/jupyter_notebook_config.py
ENV CONFIG_IPYTHON /root/.ipython/profile_default/ipython_config.py

RUN jupyter notebook --generate-config --allow-root && \
    ipython profile create
# for tqdm
# RUN jupyter nbextension enable --py --sys-prefix widgetsnbextension && \
#     jupyter labextension install ipyvolume && \
#     jupyter labextension install @jupyter-widgets/jupyterlab-manager@0.37.3


RUN echo "c.NotebookApp.ip = '0.0.0.0'" >>${CONFIG} && \
    echo "c.NotebookApp.open_browser = False" >>${CONFIG} && \
    echo "c.NotebookApp.iopub_data_rate_limit=10000000000" >>${CONFIG} && \
    echo "c.MultiKernelManager.default_kernel_name = 'python3'" >>${CONFIG} && \
    echo "c.NotebookApp.token = ''" >>${CONFIG}

RUN echo "c.InteractiveShellApp.exec_lines = ['%matplotlib inline']" >>${CONFIG_IPYTHON}

EXPOSE 8888 6006

VOLUME /vol
VOLUME /logs
VOLUME /workdir

ENV UP_SCRIPT /root/up_script.sh

RUN touch ${UP_SCRIPT} && \
    chmod 777 ${UP_SCRIPT} && \
    echo "jupyter lab --allow-root &" >>${UP_SCRIPT} && \
    echo "tensorboard --logdir=logs --port 6006 &">>${UP_SCRIPT} && \
    echo "tail -f /dev/null">>${UP_SCRIPT}

# Add files
# ADD ./fasttext /workdir/

# Run Jupyter Notebook
WORKDIR "/workdir"

ENV LANG='ja_JP.UTF-8'
CMD ${UP_SCRIPT}