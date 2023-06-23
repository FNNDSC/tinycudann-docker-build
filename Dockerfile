FROM mambaorg/micromamba:1.4.4 as micromamba
FROM nvidia/cuda:11.7.1-cudnn8-devel-ubuntu22.04 as builder

#           +----------------------------------------+
#           |                                        |
#           |           INSTALL MICROMAMBA           |
#           |                                        |
#           +----------------------------------------+

# https://github.com/mamba-org/micromamba-docker#adding-micromamba-to-an-existing-docker-image
ARG MAMBA_USER=mamba
ARG MAMBA_USER_ID=1000
ARG MAMBA_USER_GID=1000
ENV MAMBA_USER=$MAMBA_USER
ENV MAMBA_ROOT_PREFIX="/opt/conda"
ENV MAMBA_EXE="/bin/micromamba"

COPY --from=micromamba "$MAMBA_EXE" "$MAMBA_EXE"
COPY --from=micromamba /usr/local/bin/_activate_current_env.sh /usr/local/bin/_activate_current_env.sh
COPY --from=micromamba /usr/local/bin/_dockerfile_shell.sh /usr/local/bin/_dockerfile_shell.sh
COPY --from=micromamba /usr/local/bin/_entrypoint.sh /usr/local/bin/_entrypoint.sh
COPY --from=micromamba /usr/local/bin/_activate_current_env.sh /usr/local/bin/_activate_current_env.sh
COPY --from=micromamba /usr/local/bin/_dockerfile_initialize_user_accounts.sh /usr/local/bin/_dockerfile_initialize_user_accounts.sh
COPY --from=micromamba /usr/local/bin/_dockerfile_setup_root_prefix.sh /usr/local/bin/_dockerfile_setup_root_prefix.sh

RUN /usr/local/bin/_dockerfile_initialize_user_accounts.sh && \
    /usr/local/bin/_dockerfile_setup_root_prefix.sh

USER $MAMBA_USER
SHELL ["/usr/local/bin/_dockerfile_shell.sh"]
ENTRYPOINT ["/usr/local/bin/_entrypoint.sh", "/opt/nvidia/nvidia_entrypoint.sh"]
ENV PATH=/opt/conda/bin:$PATH

#           +----------------------------------------+
#           |                                        |
#           |            INSTALL PYTORCH             |
#           |         and build dependencies         |
#           |                                        |
#           +----------------------------------------+

ARG PYTHON_VERSION=3.10.6
ARG PYTORCH_VERSION=1.13.1
RUN micromamba install -y -n base -c conda-forge python=$PYTHON_VERSION git
RUN micromamba install -y -n base -c pytorch -c nvidia -c conda-forge pytorch=$PYTORCH_VERSION pytorch-cuda=11.7 

#           +----------------------------------------+
#           |                                        |
#           |          INSTALL tiny-cuda-nn          |
#           |                                        |
#           +----------------------------------------+

ARG TCNN_CUDA_ARCHITECTURES=90;89;86;80;75;70;61;52
RUN pip install --verbose 'git+https://github.com/NVlabs/tiny-cuda-nn/#subdirectory=bindings/torch'

#           +----------------------------------------+
#           |                                        |
#           |          ISOLATE tiny-cuda-nn          |
#           |                                        |
#           +----------------------------------------+

USER root
RUN mkdir -v /dist
RUN cp -rv /opt/conda/lib/python3.10/site-packages/tinycudann*/ /dist

FROM scratch
WORKDIR /
COPY --from=builder /dist/ /usr/local/lib/python3.10/site-packages/
