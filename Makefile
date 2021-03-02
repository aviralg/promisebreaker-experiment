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
## Applications
################################################################################
TEE := tee
TEE_FLAGS := --ignore-interrupts
TIME := time --portability
XVFB_RUN := xvfb-run
MV := mv
RM := rm

################################################################################
## Parallelism
################################################################################
CPU_COUNT := 72

################################################################################
## Github
################################################################################
AVIRALG_GIT_URL := git@github.com:aviralg
PRL_PRG_GIT_URL := git@github.com:PRL-PRG

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

define newline


endef

# https://gist.github.com/nicferrier/2277987
define clonepull
if [ ! -d ${3}/.git ]; then                                            \
    git clone --branch ${1} ${2} ${3} 2>&1 | $(TEE) $(TEE_FLAGS) ${4}; \
else                                                                   \
    cd ${3} && git pull 2>&1 | $(TEE) $(TEE_FLAGS) ${4};               \
fi;
endef

################################################################################
## experiment
################################################################################

EXPERIMENT_DIRPATH := $(PROJECT_DIRPATH)/experiment
LOGS_DIRPATH := $(PROJECT_DIRPATH)/logs

experiment: experiment-setup		\
            experiment-corpus		\
            experiment-profile	\
            experiment-remove		\
            experiment-analyze


################################################################################
## experiment/setup
################################################################################

EXPERIMENT_SETUP_DIRPATH := $(EXPERIMENT_DIRPATH)/setup
LOGS_SETUP_DIRPATH := $(LOGS_DIRPATH)/setup

experiment-setup: experiment-setup-dockr       \
                  experiment-setup-r-dyntrace  \
                  experiment-setup-library     \
                  experiment-setup-instrumentr \
                  experiment-setup-experimentr \
                  experiment-setup-lazr        \
                  experiment-setup-strictr

################################################################################
## experiment/setup/dockr
################################################################################

DOCKR_BRANCH := master
DOCKR_GIT_URL := $(AVIRALG_GIT_URL)/dockr.git
EXPERIMENT_SETUP_DOCKR_DIRPATH := $(EXPERIMENT_SETUP_DIRPATH)/dockr
LOGS_SETUP_DOCKR_DIRPATH := $(LOGS_SETUP_DIRPATH)/dockr/

experiment-setup-dockr:
	mkdir -p $(EXPERIMENT_SETUP_DIRPATH)
	mkdir -p $(LOGS_SETUP_DIRPATH)
	mkdir -p $(LOGS_SETUP_DOCKR_DIRPATH)
	$(call clonepull, $(DOCKR_BRANCH), $(DOCKR_GIT_URL), $(EXPERIMENT_SETUP_DOCKR_DIRPATH), $(LOGS_SETUP_DOCKR_DIRPATH)/clone.log)
	docker build                              \
	       --build-arg USER=$(USER)           \
	       --build-arg UID=$(UID)             \
	       --build-arg GID=$(GID)             \
	       --build-arg PASSWORD=$(PASSWORD)   \
	       --tag strictr                      \
	       $(EXPERIMENT_SETUP_DOCKR_DIRPATH) 2>&1 | $(TEE) $(TEE_FLAGS) $(LOGS_SETUP_DOCKR_DIRPATH)/build.log

################################################################################
## experiment/setup/r-dyntrace
################################################################################

R_DYNTRACE_BRANCH := r-4.0.2
R_DYNTRACE_GIT_URL := $(PRL_PRG_GIT_URL)/R-dyntrace.git
EXPERIMENT_SETUP_R_DYNTRACE_DIRPATH := $(EXPERIMENT_SETUP_DIRPATH)/R-dyntrace
LOGS_SETUP_R_DYNTRACE_DIRPATH := $(LOGS_SETUP_DIRPATH)/R-dyntrace
R_DYNTRACE_BIN := $(EXPERIMENT_SETUP_R_DYNTRACE_DIRPATH)/bin/R

experiment-setup-r-dyntrace:
	mkdir -p $(EXPERIMENT_SETUP_DIRPATH)
	mkdir -p $(LOGS_SETUP_R_DYNTRACE_DIRPATH)
	$(call clonepull, $(R_DYNTRACE_BRANCH), $(R_DYNTRACE_GIT_URL), $(EXPERIMENT_SETUP_R_DYNTRACE_DIRPATH), $(LOGS_SETUP_R_DYNTRACE_DIRPATH)/clone.log)
	cd $(EXPERIMENT_SETUP_R_DYNTRACE_DIRPATH) && ./build 2>&1 | $(TEE) $(TEE_FLAGS) $(LOGS_SETUP_R_DYNTRACE_DIRPATH)/build.log

################################################################################
## experiment/setup/library
################################################################################

EXPERIMENT_SETUP_LIBRARY_DIRPATH := $(EXPERIMENT_SETUP_DIRPATH)/library
LOGS_SETUP_LIBRARY_DIRPATH := $(LOGS_SETUP_DIRPATH)/library

experiment-setup-library: experiment-setup-library-mirror  \
                          experiment-setup-library-extract \
                          experiment-setup-library-install \
                          experiment-setup-library-snapshot

################################################################################
## experiment/setup/library/mirror
################################################################################

EXPERIMENT_SETUP_LIBRARY_MIRROR_DIRPATH := $(EXPERIMENT_SETUP_LIBRARY_DIRPATH)/mirror
LOGS_SETUP_LIBRARY_MIRROR_DIRPATH := $(LOGS_SETUP_LIBRARY_DIRPATH)/mirror
experiment-setup-library-mirror: experiment-setup-library-mirror-cran  \
                                 experiment-setup-library-mirror-bioc

################################################################################
## experiment/setup/library/mirror/cran
################################################################################

EXPERIMENT_SETUP_LIBRARY_MIRROR_CRAN_DIRPATH := $(EXPERIMENT_SETUP_LIBRARY_MIRROR_DIRPATH)/cran
LOGS_SETUP_LIBRARY_MIRROR_CRAN_DIRPATH := $(LOGS_SETUP_LIBRARY_MIRROR_DIRPATH)/cran

experiment-setup-library-mirror-cran:
	@mkdir -p $(EXPERIMENT_SETUP_LIBRARY_MIRROR_CRAN_DIRPATH)
	@mkdir -p $(LOGS_SETUP_LIBRARY_MIRROR_CRAN_DIRPATH)
	rsync -zrtlv --delete																																	\
	             --include '/src'																													\
	             --include '/src/contrib'																									\
	             --include '/src/contrib/*.tar.gz'																				\
	             --include '/src/contrib/PACKAGES'																				\
	             --include '/src/contrib/Symlink'																					\
	             --include '/src/contrib/Symlink/**'																			\
	             --exclude '**'																														\
	             cran.r-project.org::CRAN $(EXPERIMENT_SETUP_LIBRARY_MIRROR_CRAN_DIRPATH) \
	             2>&1 | $(TEE) $(TEE_FLAGS) $(LOGS_SETUP_LIBRARY_MIRROR_CRAN_DIRPATH)/rsync.log

################################################################################
## experiment/setup/library/mirror/cran
################################################################################

EXPERIMENT_SETUP_LIBRARY_MIRROR_BIOC_DIRPATH := $(EXPERIMENT_SETUP_LIBRARY_MIRROR_DIRPATH)/bioc
EXPERIMENT_SETUP_LIBRARY_MIRROR_BIOC_RELEASE_DIRPATH := $(EXPERIMENT_SETUP_LIBRARY_MIRROR_BIOC_DIRPATH)/release

LOGS_SETUP_LIBRARY_MIRROR_BIOC_DIRPATH := $(LOGS_SETUP_LIBRARY_MIRROR_DIRPATH)/bioc

experiment-setup-library-mirror-bioc:
	@mkdir -p $(EXPERIMENT_SETUP_LIBRARY_MIRROR_BIOC_RELEASE_DIRPATH)
	@mkdir -p $(LOGS_SETUP_LIBRARY_MIRROR_BIOC_DIRPATH)
	rsync -zrtlv --delete																																									\
	             --include '/bioc/'																																				\
	             --include '/bioc/REPOSITORY'																															\
	             --include '/bioc/SYMBOLS'																																\
	             --include '/bioc/VIEWS'																																	\
	             --include '/bioc/src/'																																		\
	             --include '/bioc/src/contrib/'																														\
	             --include '/bioc/src/contrib/**'																													\
	             --exclude '/bioc/src/contrib/Archive/**'																									\
	             --include '/data/'																																				\
	             --include '/data/experiment/'																														\
	             --include '/bioc/experiment/REPOSITORY'																									\
	             --include '/bioc/experiment/SYMBOLS'																											\
	             --include '/bioc/experiment/VIEWS'																												\
	             --include '/data/experiment/src/'																												\
	             --include '/data/experiment/src/contrib/'																								\
	             --include '/data/experiment/src/contrib/**'																							\
	             --exclude '/data/experiment/src/contrib/Archive/**'																			\
	             --include '/data/annotation/'																														\
	             --include '/bioc/annotation/REPOSITORY'																									\
	             --include '/bioc/annotation/SYMBOLS'																											\
	             --include '/bioc/annotation/VIEWS'																												\
	             --include '/data/annotation/src/'																												\
	             --include '/data/annotation/src/contrib/'																								\
	             --include '/data/annotation/src/contrib/**'																							\
	             --exclude '/data/annotation/src/contrib/Archive/**'																			\
	             --include '/workflows/'																																	\
	             --include '/workflows/REPOSITORY'																												\
	             --include '/workflows/SYMBOLS'																														\
	             --include '/workflows/VIEWS'																															\
	             --include '/workflows/src/'																															\
	             --include '/workflows/src/contrib/'																											\
	             --include '/workflows/src/contrib/**'																										\
	             --exclude '/workflows/src/contrib/Archive/**'																						\
	             --exclude '/**'																																					\
	             master.bioconductor.org::release $(EXPERIMENT_SETUP_LIBRARY_MIRROR_BIOC_RELEASE_DIRPATH) \
	             2>&1 | $(TEE) $(TEE_FLAGS) $(LOGS_SETUP_LIBRARY_MIRROR_BIOC_DIRPATH)/rsync.log

################################################################################
## experiment/setup/library/extract
################################################################################

EXPERIMENT_SETUP_LIBRARY_EXTRACT_DIRPATH := $(EXPERIMENT_SETUP_LIBRARY_DIRPATH)/extract
LOGS_SETUP_LIBRARY_EXTRACT_DIRPATH := $(LOGS_SETUP_LIBRARY_DIRPATH)/extract

experiment-setup-library-extract:
	@mkdir -p $(EXPERIMENT_SETUP_LIBRARY_EXTRACT_DIRPATH)
	@mkdir -p $(LOGS_SETUP_LIBRARY_EXTRACT_DIRPATH)
	find $(EXPERIMENT_SETUP_LIBRARY_MIRROR_CRAN_DIRPATH)/src/contrib               \
	     $(EXPERIMENT_SETUP_LIBRARY_MIRROR_BIOC_RELEASE_DIRPATH)/bioc/src/contrib  \
	     -maxdepth 1                                                               \
	     -type f                                                                   \
	     -name "*.tar.gz"                                                          \
	     -execdir tar -xvf '{}'                                                    \
	     -C $(EXPERIMENT_SETUP_LIBRARY_EXTRACT_DIRPATH) \; 2>&1 | $(TEE) $(TEE_FLAGS) $(LOGS_SETUP_LIBRARY_EXTRACT_DIRPATH)/tar.log

################################################################################
## experiment/setup/library/install
################################################################################

EXPERIMENT_SETUP_LIBRARY_INSTALL_DIRPATH := $(EXPERIMENT_SETUP_LIBRARY_DIRPATH)/install
LOGS_SETUP_LIBRARY_INSTALL_DIRPATH := $(LOGS_SETUP_LIBRARY_DIRPATH)/install

experiment-setup-library-install: experiment-setup-library-install-cran \
                                  experiment-setup-library-install-bioc

define INSTALL_CRAN_PACKAGES_CODE
options(repos       = 'file://$(EXPERIMENT_SETUP_LIBRARY_MIRROR_CRAN)');
options(BioC_mirror = 'file://$(EXPERIMENT_SETUP_LIBRARY_MIRROR_BIOC)');
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



LOGS_SETUP_LIBRARY_INSTALL_CRAN_DIRPATH := $(LOGS_SETUP_LIBRARY_INSTALL_DIRPATH)/cran

experiment-setup-library-install-cran:
	@mkdir -p $(EXPERIMENT_SETUP_LIBRARY_INSTALL_DIRPATH)
	@mkdir -p $(LOGS_SETUP_LIBRARY_INSTALL_DIRPATH)
	@mkdir -p $(LOGS_SETUP_LIBRARY_INSTALL_CRAN_DIRPATH)
	$(XVFB_RUN) $(R_DYNTRACE) -e "$(subst $(newline), ,$(INSTALL_CRAN_PACKAGES_CODE))" 2>&1 | $(TEE) $(TEE_FLAGS) $(LOGS_SETUP_LIBRARY_INSTALL_CRAN_DIRPATH)/install.log
	$(MV) -f *.out $(LOGS_SETUP_LIBRARY_INSTALL_CRAN_DIRPATH) 2> /dev/null

define INSTALL_BIOC_PACKAGES_CODE
options(repos       = 'file://$(EXPERIMENT_SETUP_LIBRARY_MIRROR_CRAN)');
options(BioC_mirror = 'file://$(EXPERIMENT_SETUP_LIBRARY_MIRROR_BIOC)');
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

LOGS_SETUP_LIBRARY_INSTALL_BIOC_DIRPATH := $(LOGS_SETUP_LIBRARY_INSTALL_DIRPATH)/bioc

experiment-setup-repository-install-bioc:
	@mkdir -p $(EXPERIMENT_SETUP_LIBRARY_INSTALL_DIRPATH)
	@mkdir -p $(LOGS_SETUP_LIBRARY_INSTALL_DIRPATH)
	@mkdir -p $(LOGS_SETUP_LIBRARY_INSTALL_BIOC_DIRPATH)

	mkdir -p $(EXPERIMENT_SETUP_LIBRARY_MIRROR_BIOC)/packages
	ln -sfn $(EXPERIMENT_SETUP_LIBRARY_MIRROR_BIOC)/release $(EXPERIMENT_SETUP_LIBRARY_MIRROR_BIOC)/packages/3.12

	$(XVFB_RUN) $(R_DYNTRACE) -e "$(subst $(newline), ,$(INSTALL_BIOC_PACKAGES_CODE))" 2>&1 | $(TEE) $(TEE_FLAGS) $(LOGS_SETUP_LIBRARY_INSTALL_BIOC_DIRPATH)/install.log
	$(MV) -f *.out $(LOGS_SETUP_LIBRARY_INSTALL_BIOC_DIRPATH) 2> /dev/null

experiment-setup-repository-snapshot:
	@echo TODO

################################################################################
## experiment/setup/instrumentr
################################################################################

INSTRUMENTR_BRANCH := c-api
INSTRUMENTR_GIT_URL := $(PRL_PRG_GIT_URL)/instrumentr.git
EXPERIMENT_SETUP_INSTRUMENTR_DIRPATH := $(EXPERIMENT_SETUP_DIRPATH)/instrumentr
LOGS_SETUP_INSTRUMENTR_DIRPATH := $(LOGS_SETUP_DIRPATH)/instrumentr

experiment-setup-instrumentr:
	@mkdir -p $(EXPERIMENT_SETUP_DIRPATH)
	@mkdir -p $(LOGS_SETUP_INSTRUMENTR_DIRPATH)
	$(call clonepull, $(INSTRUMENTR_BRANCH), $(INSTRUMENTR_GIT_URL), $(EXPERIMENT_SETUP_INSTRUMENTR_DIRPATH), $(LOGS_SETUP_INSTRUMENTR_DIRPATH)/clone.log)
	cd $(EXPERIMENT_SETUP_INSTRUMENTR_DIRPATH) && make R=$(R_DYNTRACE_BIN) 2>&1 | $(TEE) $(TEE_FLAGS) $(LOGS_SETUP_INSTRUMENTR_DIRPATH)/install.log

################################################################################
## experiment/setup/experimentr
################################################################################

EXPERIMENTR_BRANCH := master
EXPERIMENTR_GIT_URL := $(AVIRALG_GIT_URL)/experimentr.git
EXPERIMENT_SETUP_EXPERIMENTR_DIRPATH := $(EXPERIMENT_SETUP_DIRPATH)/experimentr
LOGS_SETUP_EXPERIMENTR_DIRPATH := $(LOGS_SETUP_DIRPATH)/experimentr

experiment-setup-experimentr:
	@mkdir -p $(EXPERIMENT_SETUP_DIRPATH)
	@mkdir -p $(LOGS_SETUP_EXPERIMENTR_DIRPATH)
	$(call clonepull, $(EXPERIMENTR_BRANCH), $(EXPERIMENTR_GIT_URL), $(EXPERIMENT_SETUP_EXPERIMENTR_DIRPATH), $(LOGS_SETUP_EXPERIMENTR_DIRPATH)/clone.log)
	cd $(EXPERIMENT_SETUP_EXPERIMENTR_DIRPATH) && make R=$(R_DYNTRACE_BIN) 2>&1 | $(TEE) $(TEE_FLAGS) $(LOGS_SETUP_EXPERIMENTR_DIRPATH)/install.log

################################################################################
## experiment/setup/lazr
################################################################################

LAZR_BRANCH := master
LAZR_GIT_URL := $(AVIRALG_GIT_URL)/lazr.git
EXPERIMENT_SETUP_LAZR_DIRPATH := $(EXPERIMENT_SETUP_DIRPATH)/lazr
LOGS_SETUP_LAZR_DIRPATH := $(LOGS_SETUP_DIRPATH)/lazr

experiment-setup-lazr:
	@mkdir -p $(EXPERIMENT_SETUP_DIRPATH)
	@mkdir -p $(LOGS_SETUP_LAZR_DIRPATH)
	$(call clonepull,$(LAZR_BRANCH), $(LAZR_GIT_URL), $(EXPERIMENT_SETUP_LAZR_DIRPATH), $(LOGS_SETUP_LAZR_DIRPATH)/clone.log)
	cd $(EXPERIMENT_SETUP_LAZR_DIRPATH) && make R=$(R_DYNTRACE_BIN) 2>&1 | $(TEE) $(TEE_FLAGS) $(LOGS_SETUP_LAZR_DIRPATH)/install.log

################################################################################
## experiment/setup/strictr
################################################################################

STRICTR_BRANCH := master
STRICTR_GIT_URL := $(AVIRALG_GIT_URL)/strictr.git
EXPERIMENT_SETUP_STRICTR_DIRPATH := $(EXPERIMENT_SETUP_DIRPATH)/strictr
LOGS_SETUP_STRICTR_DIRPATH := $(LOGS_SETUP_DIRPATH)/strictr

experiment-setup-strictr:
	@mkdir -p $(EXPERIMENT_SETUP_DIRPATH)
	@mkdir -p $(LOGS_SETUP_STRICTR_DIRPATH)
	$(call clonepull, $(STRICTR_BRANCH), $(STRICTR_GIT_URL), $(EXPERIMENT_SETUP_STRICTR_DIRPATH), $(LOGS_SETUP_STRICTR_DIRPATH)/clone.log)
	cd $(EXPERIMENT_SETUP_STRICTR_DIRPATH) && make R=$(R_DYNTRACE_BIN) 2>&1 | $(TEE) $(TEE_FLAGS) $(LOGS_SETUP_STRICTR_DIRPATH)/install.log


################################################################################
## experiment/corpus
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
