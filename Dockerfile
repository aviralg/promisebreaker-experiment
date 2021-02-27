################################################################################
## https://hub.docker.com/_/debian/
################################################################################
FROM debian:buster

################################################################################
## Upgrade
################################################################################
RUN apt-get update
RUN apt-get -y dist-upgrade

################################################################################
## Basic packages
################################################################################
RUN DEBIAN_FRONTEND=noninteractive apt-get -qy install \
    sudo                                               \
    apt-utils                                          \
    debian-keyring

################################################################################
## Locale
## https://hub.docker.com/_/debian/
## https://github.com/docker-library/postgres/blob/69bc540ecfffecce72d49fa7e4a46680350037f9/9.6/Dockerfile#L21-L24
## http://jaredmarkell.com/docker-and-locales/
################################################################################
RUN DEBIAN_FRONTEND=noninteractive apt-get -qy install locales
RUN echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
RUN locale-gen en_US.UTF-8
RUN /usr/sbin/update-locale LANG=en_US.UTF-8 LANGUAGE=en_US:en LC_ALL=en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

################################################################################
## R
################################################################################
RUN DEBIAN_FRONTEND=noninteractive apt-get -qy install r-base r-base-dev

################################################################################
## Shell
################################################################################
RUN DEBIAN_FRONTEND=noninteractive apt-get -qy install fish bash zsh

################################################################################
## Editor
################################################################################
RUN DEBIAN_FRONTEND=noninteractive apt-get -qy install vim emacs

################################################################################
## Version Control
################################################################################
RUN DEBIAN_FRONTEND=noninteractive apt-get -qy install git subversion

################################################################################
## Data Transfer
################################################################################
RUN DEBIAN_FRONTEND=noninteractive apt-get -qy install curl wget rsync

################################################################################
## Process Monitoring
################################################################################
RUN DEBIAN_FRONTEND=noninteractive apt-get -qy install procps htop

################################################################################
## Latex
################################################################################
RUN DEBIAN_FRONTEND=noninteractive apt-get -qy install texlive-full libcairo2-dev libtiff-dev

################################################################################
## Development
################################################################################
RUN DEBIAN_FRONTEND=noninteractive apt-get -qy install \
    build-essential                                    \
    gdb                                                \
    cmake                                              \
    clang-format                                       \
    clang-tidy                                         \
    clang-tools                                        \
    clang                                              \
    libc++-dev                                         \
    libc++1                                            \
    libc++abi-dev                                      \
    libc++abi1                                         \
    libclang-dev                                       \
    libclang1                                          \
    liblldb-dev                                        \
    libllvm-ocaml-dev                                  \
    libomp-dev                                         \
    libomp5                                            \
    lld                                                \
    lldb                                               \
    llvm-dev                                           \
    llvm-runtime                                       \
    llvm                                               \
    python-clang

################################################################################
## Tracing Dependencies
################################################################################
# latest version of GNU parallel
RUN curl -L https://bit.ly/install-gnu-parallel | sh -x
RUN DEBIAN_FRONTEND=noninteractive apt-get -qy install xvfb expect libzstd-dev time tree pandoc xfonts-100dpi xfonts-75dpi

################################################################################
## Tracing Dependencies
################################################################################
RUN DEBIAN_FRONTEND=noninteractive apt-get -qy install \
    python                                             \
    python3-dev                                        \
    ipython3                                           \
    python-mechanize                                   \
    python3-numpy                                      \
    python3-pygments                                   \
    python3-pkg-resources

################################################################################
## CRAN dependencies
## https://github.com/jeroen/rcheckserver/
################################################################################
RUN DEBIAN_FRONTEND=noninteractive apt-get -qy install \
    anacron                                            \
    ant                                                \
    aspell                                             \
    aspell-en                                          \
    auctex                                             \
    biber                                              \
    bindfs                                             \
    bison                                              \
    bsd-mailx                                          \
    bwidget                                            \
    calibre                                            \
    cargo                                              \
    coinor-libcgl-dev                                  \
    coinor-libclp-dev                                  \
    coinor-libosi-dev                                  \
    coinor-libsymphony-dev                             \
    curl                                               \
    default-jdk                                        \
    default-libmysqlclient-dev                         \
    devscripts                                         \
    dieharder                                          \
    elpa-ess                                           \
    ess                                                \
    ffmpeg                                             \
    fftw-dev                                           \
    flex                                               \
    gdal-bin                                           \
    gfortran                                           \
    ggobi                                              \
    gretl                                              \
    highlight                                          \
    hunspell                                           \
    hunspell-en-gb                                     \
    hunspell-en-us                                     \
    imagemagick                                        \
    libnode-dev                                        \
    iwidgets4                                          \
    jags                                               \
    jupyter-client                                     \
    jupyter-core                                       \
    jupyter-nbconvert                                  \
    lam-runtime                                        \
    lam4-dev                                           \
    libapparmor-dev                                    \
    libapt-pkg-dev                                     \
    libarchive-dev                                     \
    libarmadillo-dev                                   \
    libavfilter-dev                                    \
    libboost-dev                                       \
    libboost-iostreams-dev                             \
    libboost-locale-dev                                \
    libboost-program-options-dev                       \
    libboost-regex-dev                                 \
    libboost-system-dev                                \
    libbsd-dev                                         \
    libc6-dev-i386                                     \
    libdb-dev                                          \
    libdieharder-dev                                   \
    libev-dev                                          \
    libfftw3-dev                                       \
    libgd-dev                                          \
    libgdal-dev                                        \
    libgeos-dev                                        \
    libgeos++-dev                                      \
    libglade2-dev                                      \
    libglpk-dev                                        \
    libglu1-mesa-dev                                   \
    libgmp3-dev                                        \
    libgpgme-dev                                       \
    libgraphviz-dev                                    \
    libgsl-dev                                         \
    libgtk2.0-dev                                      \
    libhdf5-serial-dev                                 \
    libhiredis-dev                                     \
    libhunspell-dev                                    \
    libicu-dev                                         \
    libimage-exiftool-perl                             \
    libitpp-dev                                        \
    libjpeg-dev                                        \
    libjq-dev                                          \
    libleptonica-dev                                   \
    liblua5.2-dev                                      \
    libmagic-dev                                       \
    libmagick++-dev                                    \
    libmagickwand-dev                                  \
    libmecab-dev                                       \
    libmpc-dev                                         \
    libmpfr-dev                                        \
    libmpich-dev                                       \
    libnetcdf-dev                                      \
    libnlopt-dev                                       \
    liboctave-dev                                      \
    libopencv-dev                                      \
    libopenmpi-dev                                     \
    libperl-dev                                        \
    libpoppler-cpp-dev                                 \
    libpoppler-glib-dev                                \
    libproj-dev                                        \
    libprotobuf-dev                                    \
    libprotoc-dev                                      \
    libquantlib0-dev                                   \
    librabbitmq-dev                                    \
    libraptor2-dev                                     \
    librdf-dev                                         \
    libreadline-dev                                    \
    librrd-dev                                         \
    libsasl2-dev                                       \
    libsbml-dev                                        \
    libscalapack-mpi-dev                               \
    libsecret-1-dev                                    \
    libsndfile-dev                                     \
    libsodium-dev                                      \
    libspreadsheet-parseexcel-perl                     \
    libsprng2-dev                                      \
    libssh-dev                                         \
    libssl-dev                                         \
    libtesseract-dev                                   \
    libtext-csv-xs-perl                                \
    libtiff5-dev                                       \
    libudunits2-dev                                    \
    libv8-dev                                          \
    libxml2-dev                                        \
    libxslt1-dev                                       \
    libzmq3-dev                                        \
    locate                                             \
    lua5.1                                             \
    netcdf-bin                                         \
    noweb                                              \
    openmpi-bin                                        \
    pandoc                                             \
    pandoc-citeproc                                    \
    pari-gp                                            \
    poppler-utils                                      \
    portaudio19-dev                                    \
    protobuf-compiler                                  \
    pvm-dev                                            \
    qpdf                                               \
    rrdtool                                            \
    rsync                                              \
    s-nail                                             \
    saga                                               \
    scala                                              \
    subversion                                         \
    tcl-dev                                            \
    tesseract-ocr-eng                                  \
    time                                               \
    tk-dev                                             \
    tk-table                                           \
    tmux                                               \
    ttf-sjfonts                                        \
    wordnet-dev                                        \
    xclip                                              \
    xkb-data                                           \
    xorg-dev                                           \
    xserver-xorg                                       \
    xvfb                                               \
    4ti2                                               \
    libgit2-dev                                        \
    libopenblas-dev                                    \
    liblapacke-dev                                     \
    libpcre2-dev

#RUN curl "https://keyserver.ubuntu.com/pks/lookup?op=get&search=0xfe6b0f6d941769e0b8ee7c3c3b1c3b572302bcb1" | APT_KEY_DONT_WARN_ON_DANGEROUS_USAGE=1 apt-key add -
#
#RUN echo "deb http://statmath.wu.ac.at/AASC/debian stable main non-free" > /etc/apt/sources.list.d/rcheckserver.list && \
#    apt-get -y update && \
#    DEBIAN_FRONTEND=noninteractive apt-get -yq install rcheckserver

################################################################################
## Arguments
## (https://medium.com/faun/set-current-host-user-for-docker-container-4e521cef9ffc)
################################################################################
ARG USER=aviral
RUN echo "USER=${USER}"

ARG UID=1000
RUN echo "UID=${UID}"

ARG GID=1000
RUN echo "GID=${GID}"

ARG PASSWORD=aviral
RUN echo "PASSWORD=${PASSWORD}"

################################################################################
## Web Server
## https://www.linkedin.com/pulse/serve-static-files-from-docker-via-nginx-basic-example-arun-kumar
################################################################################
#RUN DEBIAN_FRONTEND=noninteractive apt-get -qy install nginx
#RUN rm -v /etc/nginx/nginx.conf
#ADD nginx.conf /etc/nginx/
#ADD paper.pdf /var/www/
#ADD small.html /var/www/
#COPY small_files /var/www/small_files
#ADD large.html /var/www/
#COPY large_files /var/www/large_files

################################################################################
## User
################################################################################
RUN groupadd --gid ${GID} ${USER}
RUN useradd --create-home --uid=${UID} --gid=${GID} --shell /bin/fish ${USER}
RUN echo "${USER}:${PASSWORD}" | chpasswd
RUN echo "${USER} ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
USER ${USER}
WORKDIR /home/${USER}
#RUN mkdir -p /home/aviral/library
ENV R_LIBS_USER /home/${USER}/library
ENV R_KEEP_PKG_SOURCE 1
ENV R_ENABLE_JIT 0
ENV R_COMPILE_PKGS 0
ENV R_DISABLE_BYTECODE 1
ENV OMP_NUM_THREADS 1

#################################################################################
### R-dyntrace
#################################################################################
#RUN git clone --branch oopsla-2019-study-of-laziness-v1 https://github.com/PRL-PRG/R-dyntrace.git
#RUN cd R-dyntrace && ./build
#
#################################################################################
### promisedyntracer
#################################################################################
#RUN git clone --branch oopsla-2019-study-of-laziness-v1 https://github.com/aviralg/promisedyntracer.git
#RUN cd promisedyntracer && make
#
#################################################################################
### promise-dyntracing-experiment
#################################################################################
#RUN git clone --branch r-3.5.0 https://github.com/PRL-PRG/promise-dyntracing-experiment.git
#RUN cd promise-dyntracing-experiment && xvfb-run make install-dependencies DEPENDENCIES_FILEPATH=scripts/package-dependencies.txt && rm -rf *.out
#
#ADD entrypoint.sh /entrypoint.sh
#ENTRYPOINT ["/entrypoint.sh"]
