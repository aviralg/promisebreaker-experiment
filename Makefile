################################################################################
## project base
## https://stackoverflow.com/questions/18136918/how-to-get-current-relative-directory-of-your-makefile
################################################################################
MAKEFILE_PATH := $(abspath $(lastword $(MAKEFILE_LIST)))
PROJECT_DIRPATH := $(dir $(MAKEFILE_PATH))

################################################################################
## docker build args
################################################################################
LIBRARY_DIRPATH := $(PROJECT_DIRPATH)library
PORT := 5000:80
USER := $(USER)
UID := $(shell id -u)
GID := $(shell id -g)
PASSWORD := $(USER)
R_DYNTRACE := $(PROJECT_DIRPATH)R-dyntrace/bin/R

################################################################################
## applications
################################################################################
TEE := tee
TEE_FLAGS := --ignore-interrupts

TIME := time --portability

XVFB_RUN := xvfb-run

MV := mv

RM := rm

################################################################################
## parallelism
################################################################################
CPU_COUNT := 72

################################################################################
## package setup options
################################################################################
CRAN_MIRROR_URL := "https://cran.r-project.org"
PACKAGE_SETUP_REPOSITORIES := --setup-cran --setup-bioc
PACKAGE_SETUP_NCPUS := 8
PACKAGE_SETUP_DIRPATH := $(PROJECT_DIRPATH)packages
PACKAGE_LIB_DIRPATH := $(PACKAGE_SETUP_DIRPATH)/lib
PACKAGE_MIRROR_DIRPATH := $(PACKAGE_SETUP_DIRPATH)/mirror
PACKAGE_SRC_DIRPATH := $(PACKAGE_SETUP_DIRPATH)/src
PACKAGE_TEST_DIRPATH := $(PACKAGE_SETUP_DIRPATH)/tests
PACKAGE_EXAMPLE_DIRPATH := $(PACKAGE_SETUP_DIRPATH)/examples
PACKAGE_VIGNETTE_DIRPATH := $(PACKAGE_SETUP_DIRPATH)/doc
PACKAGE_LOG_DIRPATH := $(PACKAGE_SETUP_DIRPATH)/log

initialize:
	mkdir library

docker-image:
	docker build                            \
	       --build-arg USER=$(USER)         \
	       --build-arg UID=$(UID)           \
	       --build-arg GID=$(GID)           \
	       --build-arg PASSWORD=$(PASSWORD) \
	       --tag strictr                    \
	       .

docker-container:
	docker run                                        \
	       -d                                         \
	       --interactive                              \
	       --tty                                      \
	       --env="DISPLAY"                            \
	       --volume="/tmp/.X11-unix:/tmp/.X11-unix"   \
	       -v $(PROJECT_DIRPATH):/home/aviral         \
	       --publish=$(PORT)                          \
	       strictr                                    \
	       fish

docker-shell:
	docker run                                        \
	       --interactive                              \
	       --tty                                      \
	       --env="DISPLAY"                            \
	       --volume="/tmp/.X11-unix:/tmp/.X11-unix"   \
	       -v $(PROJECT_DIRPATH):/home/aviral         \
	       --publish=$(PORT)                          \
	       strictr                                    \
	       fish

mirror-cran:
	@mkdir -p $(PACKAGE_MIRROR_DIRPATH)
	@mkdir -p $(PACKAGE_LIB_DIRPATH)
	@mkdir -p $(PACKAGE_SRC_DIRPATH)
	@mkdir -p $(PACKAGE_LOG_DIRPATH)
	@mkdir -p $(PACKAGE_MIRROR_DIRPATH)/cran

	rsync -zrtlv --delete \
	             --include '/src' \
	             --include '/src/contrib' \
	             --include '/src/contrib/*.tar.gz' \
	             --include '/src/contrib/PACKAGES' \
	             --include '/src/contrib/Symlink' \
	             --include '/src/contrib/Symlink/**' \
	             --exclude '**' \
	             cran.r-project.org::CRAN $(PACKAGE_MIRROR_DIRPATH)/cran \
	             2>&1 | $(TEE) $(TEE_FLAGS) $(PACKAGE_LOG_DIRPATH)/cran-mirror.log

mirror-bioc:
	@mkdir -p $(PACKAGE_MIRROR_DIRPATH)
	@mkdir -p $(PACKAGE_LIB_DIRPATH)
	@mkdir -p $(PACKAGE_SRC_DIRPATH)
	@mkdir -p $(PACKAGE_LOG_DIRPATH)
	@mkdir -p $(PACKAGE_MIRROR_DIRPATH)/bioconductor/release
	rsync -zrtlv --delete \
	             --include '/bioc/' \
	             --include '/bioc/REPOSITORY' \
	             --include '/bioc/SYMBOLS' \
	             --include '/bioc/VIEWS' \
	             --include '/bioc/src/' \
	             --include '/bioc/src/contrib/' \
	             --include '/bioc/src/contrib/**' \
	             --exclude '/bioc/src/contrib/Archive/**' \
	             --include '/data/' \
	             --include '/data/experiment/' \
	             --include '/bioc/experiment/REPOSITORY' \
	             --include '/bioc/experiment/SYMBOLS' \
	             --include '/bioc/experiment/VIEWS' \
	             --include '/data/experiment/src/' \
	             --include '/data/experiment/src/contrib/' \
	             --include '/data/experiment/src/contrib/**' \
	             --exclude '/data/experiment/src/contrib/Archive/**' \
	             --include '/data/annotation/' \
	             --include '/bioc/annotation/REPOSITORY' \
	             --include '/bioc/annotation/SYMBOLS' \
	             --include '/bioc/annotation/VIEWS' \
	             --include '/data/annotation/src/' \
	             --include '/data/annotation/src/contrib/' \
	             --include '/data/annotation/src/contrib/**' \
	             --exclude '/data/annotation/src/contrib/Archive/**' \
	             --include '/workflows/' \
	             --include '/workflows/REPOSITORY' \
	             --include '/workflows/SYMBOLS' \
	             --include '/workflows/VIEWS' \
	             --include '/workflows/src/' \
	             --include '/workflows/src/contrib/' \
	             --include '/workflows/src/contrib/**' \
	             --exclude '/workflows/src/contrib/Archive/**' \
	             --exclude '/**' \
	             master.bioconductor.org::release $(PACKAGE_MIRROR_DIRPATH)/bioconductor/release \
	             2>&1 | $(TEE) $(TEE_FLAGS) $(PACKAGE_LOG_DIRPATH)/bioc-mirror.log

extract-package-source:
	$(RM) -r $(PACKAGE_SRC_DIRPATH)/*
	find $(PACKAGE_MIRROR_DIRPATH)/cran/src/contrib                           \
	     $(PACKAGE_MIRROR_DIRPATH)/bioconductor/release/bioc/src/contrib      \
	     -maxdepth 1                                                          \
	     -type f                                                              \
	     -name "*.tar.gz"                                                     \
	     -execdir tar -xvf '{}'                                               \
	     -C $(PACKAGE_SRC_DIRPATH) \;

define newline


endef

define INSTALL_CRAN_PACKAGES_CODE
options(repos = 'file://$(PACKAGE_MIRROR_DIRPATH)/cran');
options(BioC_mirror = '$(PACKAGE_MIRROR_DIRPATH)/bioconductor');
packages <- setdiff(available.packages()[,1], installed.packages()[,1]);
cat('Installing', length(packages), 'packages with', $(CPU_COUNT), 'cpus\n');
install.packages(packages,
                 Ncpus = $(CPU_COUNT),
                 keep_outputs = TRUE,
                 INSTALL_opts = c('--example',
                                  '--install-tests',
                                  '--with-keep.source',
                                  '--no-multiarch'),
                 dependencies = c('Depends',
                                  'Imports',
                                  'LinkingTo',
                                  'Suggests',
                                  'Enhances'));
endef

install-cran: mirror-cran
	@mkdir -p $(PACKAGE_MIRROR_DIRPATH)
	@mkdir -p $(PACKAGE_LIB_DIRPATH)
	@mkdir -p $(PACKAGE_SRC_DIRPATH)
	@mkdir -p $(PACKAGE_LOG_DIRPATH)

	$(XVFB_RUN) $(R_DYNTRACE) -e "$(subst $(newline), ,$(INSTALL_CRAN_PACKAGES_CODE))" 2>&1 > $(PACKAGE_LOG_DIRPATH)/cran.log
	$(MV) -f *.out $(PACKAGE_LOG_DIRPATH) 2> /dev/null

define INSTALL_BIOC_PACKAGES_CODE
options(repos = 'file://$(PACKAGE_MIRROR_DIRPATH)/cran');
options(BioC_mirror = '$(PACKAGE_MIRROR_DIRPATH)/bioconductor');
library(BiocManager);
packages <- setdiff(available(), installed.packages()[,1]);
cat('Installing', length(packages), 'packages with', $(CPU_COUNT), 'cpus\n');
install(packages,
        Ncpus = $(CPU_COUNT),
        keep_outputs = TRUE,
        INSTALL_opts = c('--example',
                         '--install-tests',
                         '--with-keep.source',
                         '--no-multiarch'),
        dependencies = c('Depends',
                         'Imports',
                         'LinkingTo',
                         'Suggests',
                         'Enhances'));
endef

install-bioc: mirror-bioc
	@mkdir -p $(PACKAGE_MIRROR_DIRPATH)
	@mkdir -p $(PACKAGE_LIB_DIRPATH)
	@mkdir -p $(PACKAGE_SRC_DIRPATH)
	@mkdir -p $(PACKAGE_LOG_DIRPATH)

	mkdir -p $(PACKAGE_MIRROR_DIRPATH)/bioconductor/packages
	ln -sfn $(PACKAGE_MIRROR_DIRPATH)/bioconductor/release $(PACKAGE_MIRROR_DIRPATH)/bioconductor/packages/3.12

	$(XVFB_RUN) $(R_DYNTRACE) -e "$(subst $(newline), ,$(INSTALL_BIOC_PACKAGES_CODE))" 2>&1 > $(PACKAGE_LOG_DIRPATH)/bioc.log
	$(MV) -f *.out $(PACKAGE_LOG_DIRPATH) 2> /dev/null
