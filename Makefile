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


################################################################################
## corpus
################################################################################
CORPUS_DIRPATH := $(PROJECT_DIRPATH)corpus
CORPUS_INDEX_DIRPATH := $(CORPUS_DIRPATH)/index
CORPUS_DATA_DIRPATH := $(CORPUS_DIRPATH)/data
CORPUS_LOGS_DIRPATH := $(CORPUS_DIRPATH)/logs
CORPUS_INDEX_ALL_FILEPATH := $(CORPUS_INDEX_DIRPATH)/all.fst
CORPUS_DATA_ALL_DIRPATH := $(CORPUS_DATA_DIRPATH)/all

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


extract-package-source:

define newline


endef

################################################################################
## experiment
################################################################################
experiment: experiment-setup		\
            experiment-corpus		\
            experiment-profile	\
            experiment-remove		\
            experiment-analyze


################################################################################
## experiment/setup
################################################################################
experiment-setup: experiment-setup-docker        \
                  experiment-setup-r-dyntrace    \
                  experiment-setup-instrumentr   \
                  experiment-setup-experimentr   \
                  experiment-setup-repository    \
                  experiment-setup-dependencies


################################################################################
## experiment/setup/docker
################################################################################
experiment-setup-docker: experiment-setup-docker-download \
                         experiment-setup-docker-build

experiment-setup-docker-download:
	@mkdir -p $(EXPERIMENT_SETUP_DIRPATH)
	git clone $(PROMISEBREAKER_DOCKER_GIT_URL) $(EXPERIMENT_SETUP_DOCKER_DIRPATH)

experiment-setup-docker-build:
	docker build                              \
	       --build-arg USER=$(USER)           \
	       --build-arg UID=$(UID)             \
	       --build-arg GID=$(GID)             \
	       --build-arg PASSWORD=$(PASSWORD)   \
	       --tag strictr                      \
	       $(EXPERIMENT_SETUP_DOCKER_DIRPATH)

experiment-setup-docker-download:
	@mkdir -p $(EXPERIMENT_SETUP_DIRPATH)
	git clone $(PROMISEBREAKER_DOCKER_GIT_URL) $(EXPERIMENT_SETUP_DOCKER_DIRPATH)

################################################################################
## experiment/setup/r-dyntrace
################################################################################

################################################################################
## experiment/setup/repository
################################################################################
experiment-setup-repository: experiment-setup-repository-mirror  \
                             experiment-setup-repository-untar   \
                             experiment-setup-repository-install \
                             experiment-setup-repository-snapshot

experiment-setup-repository-mirror: experiment-setup-repository-mirror-cran  \
                                    experiment-setup-repository-mirror-bioc

experiment-setup-repository-mirror-cran:
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

experiment-setup-repository-mirror-bioc:
	@mkdir -p $(PACKAGE_MIRROR_DIRPATH)
	@mkdir -p $(PACKAGE_LIB_DIRPATH)
	@mkdir -p $(PACKAGE_SRC_DIRPATH)
	@mkdir -p $(PACKAGE_LOG_DIRPATH)
	@mkdir -p $(PACKAGE_MIRROR_DIRPATH)/bioconductor/release
	rsync -zrtlv --delete																																					\
	             --include '/bioc/'																																\
	             --include '/bioc/REPOSITORY'																											\
	             --include '/bioc/SYMBOLS'																												\
	             --include '/bioc/VIEWS'																													\
	             --include '/bioc/src/'																														\
	             --include '/bioc/src/contrib/'																										\
	             --include '/bioc/src/contrib/**'																									\
	             --exclude '/bioc/src/contrib/Archive/**'																					\
	             --include '/data/'																																\
	             --include '/data/experiment/'																										\
	             --include '/bioc/experiment/REPOSITORY'																					\
	             --include '/bioc/experiment/SYMBOLS'																							\
	             --include '/bioc/experiment/VIEWS'																								\
	             --include '/data/experiment/src/'																								\
	             --include '/data/experiment/src/contrib/'																				\
	             --include '/data/experiment/src/contrib/**'																			\
	             --exclude '/data/experiment/src/contrib/Archive/**'															\
	             --include '/data/annotation/'																										\
	             --include '/bioc/annotation/REPOSITORY'																					\
	             --include '/bioc/annotation/SYMBOLS'																							\
	             --include '/bioc/annotation/VIEWS'																								\
	             --include '/data/annotation/src/'																								\
	             --include '/data/annotation/src/contrib/'																				\
	             --include '/data/annotation/src/contrib/**'																			\
	             --exclude '/data/annotation/src/contrib/Archive/**'															\
	             --include '/workflows/'																													\
	             --include '/workflows/REPOSITORY'																								\
	             --include '/workflows/SYMBOLS'																										\
	             --include '/workflows/VIEWS'																											\
	             --include '/workflows/src/'																											\
	             --include '/workflows/src/contrib/'																							\
	             --include '/workflows/src/contrib/**'																						\
	             --exclude '/workflows/src/contrib/Archive/**'																		\
	             --exclude '/**'																																	\
	             master.bioconductor.org::release $(PACKAGE_MIRROR_DIRPATH)/bioconductor/release	\
	             2>&1 | $(TEE) $(TEE_FLAGS) $(PACKAGE_LOG_DIRPATH)/bioc-mirror.log

experiment-setup-repository-untar:
	$(RM) -r $(PACKAGE_SRC_DIRPATH)/*
	find $(PACKAGE_MIRROR_DIRPATH)/cran/src/contrib                           \
	     $(PACKAGE_MIRROR_DIRPATH)/bioconductor/release/bioc/src/contrib      \
	     -maxdepth 1                                                          \
	     -type f                                                              \
	     -name "*.tar.gz"                                                     \
	     -execdir tar -xvf '{}'                                               \
	     -C $(PACKAGE_SRC_DIRPATH) \;

experiment-setup-repository-install: experiment-setup-repository-install-cran \
                                     experiment-setup-repository-install-bioc

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

experiment-setup-repository-install-cran:
	@mkdir -p $(PACKAGE_MIRROR_DIRPATH)
	@mkdir -p $(PACKAGE_LIB_DIRPATH)
	@mkdir -p $(PACKAGE_SRC_DIRPATH)
	@mkdir -p $(PACKAGE_LOG_DIRPATH)

	$(XVFB_RUN) $(R_DYNTRACE) -e "$(subst $(newline), ,$(INSTALL_CRAN_PACKAGES_CODE))" 2>&1 > $(PACKAGE_LOG_DIRPATH)/cran.log
	$(MV) -f *.out $(PACKAGE_LOG_DIRPATH) 2> /dev/null

define INSTALL_BIOC_PACKAGES_CODE
options(repos = 'file://$(PACKAGE_MIRROR_DIRPATH)/cran');
options(BioC_mirror = 'file://$(PACKAGE_MIRROR_DIRPATH)/bioconductor');
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

experiment-setup-repository-install-bioc:
	@mkdir -p $(PACKAGE_MIRROR_DIRPATH)
	@mkdir -p $(PACKAGE_LIB_DIRPATH)
	@mkdir -p $(PACKAGE_SRC_DIRPATH)
	@mkdir -p $(PACKAGE_LOG_DIRPATH)

	mkdir -p $(PACKAGE_MIRROR_DIRPATH)/bioconductor/packages
	ln -sfn $(PACKAGE_MIRROR_DIRPATH)/bioconductor/release $(PACKAGE_MIRROR_DIRPATH)/bioconductor/packages/3.12

	$(XVFB_RUN) $(R_DYNTRACE) -e "$(subst $(newline), ,$(INSTALL_BIOC_PACKAGES_CODE))" 2>&1 > $(PACKAGE_LOG_DIRPATH)/bioc.log
	$(MV) -f *.out $(PACKAGE_LOG_DIRPATH) 2> /dev/null


experiment-setup-repository-snapshot:
	@echo TODO

experiment-setup-dependency:
	git clone --branch $(R_DYNTRACE_BRANCH) $(R_DYNTRACE_GIT_URL) $(EXPERIMENT_SETUP_DEPENDENCY_R_DYNTRACE_DIRPATH)
	git clone --branch $(INSTRUMENTR_BRANCH) $(INSTRUMENTR_GIT_URL) $(EXPERIMENT_SETUP_DEPENDENCY_INSTRUMENTR_DIRPATH)
	git clone --branch $(EXPERIMENTR_BRANCH) $(EXPERIMENTR_GIT_URL) $(EXPERIMENT_SETUP_DEPENDENCY_EXPERIMENTR_DIRPATH)
	git clone --branch $(LAZR_BRANCH) $(LAZR_GIT_URL) $(EXPERIMENT_SETUP_DEPENDENCY_LAZR_DIRPATH)
	git clone --branch $(STRICTR_BRANCH) $(STRICTR_GIT_URL) $(EXPERIMENT_SETUP_DEPENDENCY_STRICTR_DIRPATH)

################################################################################
## Experiment: Corpus
################################################################################
experiment-corpus: experiment-corpus-extract      \
                   experiment-corpus-sloc         \
                   experiment-corpus-determinism


define CODE_EXTRACT_CODE
library(experimentr);
res <- extract_code(installed.packages()[,1],
                    type=c('example', 'vignette', 'testthat', 'test'),
                    index_filepath='$(CORPUS_INDEX_ALL_FILEPATH)',
                    data_dirpath='$(CORPUS_DATA_ALL_DIRPATH)');
endef

experiment-corpus-extract-clean:
	rm -rf $(CORPUS_DIRPATH)

experiment-corpus-extract-redo:
	mkdir -p $(CORPUS_INDEX_DIRPATH)
	mkdir -p $(CORPUS_DATA_DIRPATH)
	mkdir -p $(CORPUS_LOGS_DIRPATH)
	$(XVFB_RUN) $(R_DYNTRACE) -e "$(subst $(newline), ,$(CODE_EXTRACT_CODE))" 2>&1 > $(CORPUS_LOGS_DIRPATH)/all.log

experiment-corpus-extract-run: experiment-corpus-extract-clean \
                               experiment-corpus-extract-redo

experiment-corpus-sloc:

experiment-corpus-determinism:

################################################################################
## Experiment: Profile
################################################################################
experiment-profile: experiment-profile-drive   \
                    experiment-profile-trace   \
                    experiment-profile-analyze

experiment-profile-drive:

experiment-profile-trace:

################################################################################
## Experiment: Remove
################################################################################
experiment-remove: experiment-remove-drive    \
                   experiment-remove-trace    \
                   experiment-remove-analyze

experiment-remove-drive:

experiment-remove-trace:

################################################################################
## Experiment: Report
################################################################################
experiment-report:
