# Building tiny-cuda-nn for PyTorch in Docker

[
![Docker Image Version (latest semver)](https://img.shields.io/docker/pulls/fnndsc/tinycudann)
](https://hub.docker.com/r/fnndsc/tinycudann)

[tiny-cuda-nn](https://github.com/NVlabs/tiny-cuda-nn) must be compiled from source.
The binaries target specific NVIDIA cards by their **compute capability** numbers.

Compute capability numbers can be manually specified to the compilation scripts for
`tiny-cuda-nn` by the environment variable `TCNN_CUDA_ARCHITECTURES`.
This feature was implemented in [PR #142](https://github.com/NVlabs/tiny-cuda-nn/pull/142).

This repository provides a `Dockerfile` used to build the PyTorch binaries for `tiny-cuda-nn`.
It is useful for:

- building `tiny-cuda-nn` targeting multiple NVIDIA card models
- reusing `tiny-cuda-nn` binaries to improve the build time of depending projects

## Building

### Identifying `TCNN_CUDA_ARCHITECTURES`

`TCNN_CUDA_ARCHITECTURES` should be set to the target GPU(s) **compute capability** multiplied by 10.
For example, my _NVIDIA GeForce RTX 3080 Ti_ graphics card has a compute capability of 8.6, so I
should set `TCNN_CUDA_ARCHITECTURES=86`.

A list of all CUDA-compatible hardware and their compute capabilities are found here: https://developer.nvidia.com/cuda-gpus

With recent-ish NVIDIA drivers installed, you are able to query your GPU(s)'s compute capability using `nvidia-smi`

```shell
nvidia-smi --query-gpu name,compute_cap --format=csv
```

Reference: https://docs.nerf.studio/en/latest/quickstart/installation.html#note

### Docker Build

```shell
PYTHON_VERSION=3.10.6
PYTORCH_VERSION=1.13.1
TCNN_CUDA_ARCHITECTURES=90;89;86;80;75;70;61;52;37

docker build -t fnndsc/tinycudacnn:isolate-python$PYTHON_VERSION-pytorch$PYTORCH_VERSION-cuda11.7 .
```

The above build with 9 values for `TCNN_CUDA_ARCHITECTURES` takes 30 minutes to run.
(Sadly, idk how to speed this up. `CMAKE_BUILD_PARALLEL_LEVEL=20` does not help.)

## Usage

In a depending project's `Dockerfile`, copy the files from this image.

```Dockerfile
COPY --from=fnndsc/tinycudacnn:isolate-python3.10.6-pytorch1.13.1-cuda11.7 /usr/local/lib/python3.10/site-packages/ /usr/local/lib/python3.10/site-packages/
```
