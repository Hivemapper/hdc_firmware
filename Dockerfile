FROM ubuntu:20.04

RUN mkdir /dashcam
WORKDIR /dashcam

COPY buildroot buildroot
COPY dashcam dashcam
COPY scripts scripts

RUN scripts/host_setup.sh

CMD ["/bin/bash"]