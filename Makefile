################################################################################
## project base
## https://stackoverflow.com/questions/18136918/how-to-get-current-relative-directory-of-your-makefile
################################################################################
MAKEFILE_PATH := $(abspath $(lastword $(MAKEFILE_LIST)))
PROJECT_DIRPATH := $(dir $(MAKEFILE_PATH))

################################################################################
## Parallelism
################################################################################
CPU_COUNT := 72

################################################################################
## Github
################################################################################
AVIRALG_GIT_URL := git@github.com:aviralg
PRL_PRG_GIT_URL := git@github.com:PRL-PRG

# logs
LOGS_DIRPATH := $(PROJECT_DIRPATH)/logs

# dependency
DEPENDENCY_DIRPATH := $(PROJECT_DIRPATH)/dependency
LOGS_DEPENDENCY_DIRPATH := $(LOGS_DIRPATH)/dependency

## dependency/dirpath
DOCKR_BRANCH := master
DOCKR_GIT_URL := $(AVIRALG_GIT_URL)/dockr.git
DEPENDENCY_DOCKR_DIRPATH := $(DEPENDENCY_DIRPATH)/dockr
LOGS_DEPENDENCY_DOCKR_DIRPATH := $(LOGS_DEPENDENCY_DIRPATH)/dockr/

## dependency/r-dyntrace
R_DYNTRACE_BRANCH := r-4.0.2
R_DYNTRACE_GIT_URL := $(PRL_PRG_GIT_URL)/R-dyntrace.git
DEPENDENCY_R_DYNTRACE_DIRPATH := $(DEPENDENCY_DIRPATH)/R-dyntrace
LOGS_DEPENDENCY_R_DYNTRACE_DIRPATH := $(LOGS_DEPENDENCY_DIRPATH)/R-dyntrace
R_DYNTRACE_BIN := $(DEPENDENCY_R_DYNTRACE_DIRPATH)/bin/R

## dependency/library
DEPENDENCY_LIBRARY_DIRPATH := $(DEPENDENCY_DIRPATH)/library
LOGS_DEPENDENCY_LIBRARY_DIRPATH := $(LOGS_DEPENDENCY_DIRPATH)/library

### dependency/library/mirror
DEPENDENCY_LIBRARY_MIRROR_DIRPATH := $(DEPENDENCY_LIBRARY_DIRPATH)/mirror
LOGS_DEPENDENCY_LIBRARY_MIRROR_DIRPATH := $(LOGS_DEPENDENCY_LIBRARY_DIRPATH)/mirror

#### dependency/library/mirror/cran
DEPENDENCY_LIBRARY_MIRROR_CRAN_DIRPATH := $(DEPENDENCY_LIBRARY_MIRROR_DIRPATH)/cran
LOGS_DEPENDENCY_LIBRARY_MIRROR_CRAN_DIRPATH := $(LOGS_DEPENDENCY_LIBRARY_MIRROR_DIRPATH)/cran

#### dependency/library/mirror/bioc
DEPENDENCY_LIBRARY_MIRROR_BIOC_DIRPATH := $(DEPENDENCY_LIBRARY_MIRROR_DIRPATH)/bioc
DEPENDENCY_LIBRARY_MIRROR_BIOC_RELEASE_DIRPATH := $(DEPENDENCY_LIBRARY_MIRROR_BIOC_DIRPATH)/release
LOGS_DEPENDENCY_LIBRARY_MIRROR_BIOC_DIRPATH := $(LOGS_DEPENDENCY_LIBRARY_MIRROR_DIRPATH)/bioc

### dependency/library/extract
DEPENDENCY_LIBRARY_EXTRACT_DIRPATH := $(DEPENDENCY_LIBRARY_DIRPATH)/extract
LOGS_DEPENDENCY_LIBRARY_EXTRACT_DIRPATH := $(LOGS_DEPENDENCY_LIBRARY_DIRPATH)/extract

### dependency/library/install
DEPENDENCY_LIBRARY_INSTALL_DIRPATH := $(DEPENDENCY_LIBRARY_DIRPATH)/install
LOGS_DEPENDENCY_LIBRARY_INSTALL_DIRPATH := $(LOGS_DEPENDENCY_LIBRARY_DIRPATH)/install

#### dependency/library/install/cran
LOGS_DEPENDENCY_LIBRARY_INSTALL_CRAN_DIRPATH := $(LOGS_DEPENDENCY_LIBRARY_INSTALL_DIRPATH)/cran

#### dependency/library/install/bioc
LOGS_DEPENDENCY_LIBRARY_INSTALL_BIOC_DIRPATH := $(LOGS_DEPENDENCY_LIBRARY_INSTALL_DIRPATH)/bioc

## dependency/instrumentr
INSTRUMENTR_BRANCH := c-api
INSTRUMENTR_GIT_URL := $(PRL_PRG_GIT_URL)/instrumentr.git
DEPENDENCY_INSTRUMENTR_DIRPATH := $(DEPENDENCY_DIRPATH)/instrumentr
LOGS_DEPENDENCY_INSTRUMENTR_DIRPATH := $(LOGS_DEPENDENCY_DIRPATH)/instrumentr

## dependency/experimentr
EXPERIMENTR_BRANCH := master
EXPERIMENTR_GIT_URL := $(AVIRALG_GIT_URL)/experimentr.git
DEPENDENCY_EXPERIMENTR_DIRPATH := $(DEPENDENCY_DIRPATH)/experimentr
LOGS_DEPENDENCY_EXPERIMENTR_DIRPATH := $(LOGS_DEPENDENCY_DIRPATH)/experimentr

## dependency/lazr
LAZR_BRANCH := master
LAZR_GIT_URL := $(AVIRALG_GIT_URL)/lazr.git
DEPENDENCY_LAZR_DIRPATH := $(DEPENDENCY_DIRPATH)/lazr
LOGS_DEPENDENCY_LAZR_DIRPATH := $(LOGS_DEPENDENCY_DIRPATH)/lazr

## dependency/strictr
STRICTR_BRANCH := master
STRICTR_GIT_URL := $(AVIRALG_GIT_URL)/strictr.git
DEPENDENCY_STRICTR_DIRPATH := $(DEPENDENCY_DIRPATH)/strictr
LOGS_DEPENDENCY_STRICTR_DIRPATH := $(LOGS_DEPENDENCY_DIRPATH)/strictr

# experiment
EXPERIMENT_DIRPATH := $(PROJECT_DIRPATH)/experiment

## experiment/corpus
EXPERIMENT_CORPUS_DIRPATH := $(EXPERIMENT_DIRPATH)/corpus
LOGS_CORPUS_DIRPATH := $(LOGS_DIRPATH)/corpus

### experiment/corpus/extract
EXPERIMENT_CORPUS_EXTRACT_DIRPATH := $(EXPERIMENT_CORPUS_DIRPATH)/extract
EXPERIMENT_CORPUS_EXTRACT_INDEX_FILEPATH := $(EXPERIMENT_CORPUS_EXTRACT_DIRPATH)/index.fst
EXPERIMENT_CORPUS_EXTRACT_PROGRAMS_DIRPATH := $(EXPERIMENT_CORPUS_EXTRACT_DIRPATH)/programs
LOGS_CORPUS_EXTRACT_DIRPATH := $(LOGS_CORPUS_DIRPATH)/extract

### experiment/corpus/sloc
EXPERIMENT_CORPUS_SLOC_DIRPATH := $(EXPERIMENT_CORPUS_DIRPATH)/sloc
LOGS_CORPUS_SLOC_DIRPATH := $(LOGS_CORPUS_DIRPATH)/sloc

#### experiment/corpus/sloc/corpus
EXPERIMENT_CORPUS_SLOC_CORPUS_DIRPATH := $(EXPERIMENT_CORPUS_SLOC_DIRPATH)/corpus
EXPERIMENT_CORPUS_SLOC_CORPUS_FILEPATH := $(EXPERIMENT_CORPUS_SLOC_CORPUS_DIRPATH)/sloc.fst
LOGS_CORPUS_SLOC_CORPUS_DIRPATH := $(LOGS_CORPUS_SLOC_DIRPATH)/corpus

#### experiment/corpus/sloc/corpus
EXPERIMENT_CORPUS_SLOC_PACKAGE_DIRPATH := $(EXPERIMENT_CORPUS_SLOC_DIRPATH)/package
EXPERIMENT_CORPUS_SLOC_PACKAGE_FILEPATH := $(EXPERIMENT_CORPUS_SLOC_PACKAGE_DIRPATH)/sloc.fst
LOGS_CORPUS_SLOC_PACKAGE_DIRPATH := $(LOGS_CORPUS_SLOC_DIRPATH)/package


### experiment/corpus/package
EXPERIMENT_CORPUS_PACKAGE_DIRPATH := $(EXPERIMENT_CORPUS_DIRPATH)/package
EXPERIMENT_CORPUS_PACKAGE_INFO_FILEPATH := $(EXPERIMENT_CORPUS_PACKAGE_DIRPATH)/info.fst
LOGS_CORPUS_PACKAGE_DIRPATH := $(LOGS_CORPUS_DIRPATH)/package

## experiment/report
EXPERIMENT_REPORT_DIRPATH := $(EXPERIMENT_DIRPATH)/report
LOGS_REPORT_DIRPATH := $(LOGS_DIRPATH)/report

## experiment/report/paper
PAPER_BRANCH := master
PAPER_GIT_URL := $(AVIRALG_GIT_URL)/promisebreaker-paper.git
EXPERIMENT_REPORT_PAPER_DIRPATH := $(EXPERIMENT_REPORT_DIRPATH)/paper
LOGS_REPORT_PAPER_DIRPATH := $(LOGS_REPORT_DIRPATH)/paper

## experiment/report/input
PAEXPERIMENT_REPORT_PAPER_DATA_DIRPATH := $(EXPERIMENT_REPORT_PAPER_DIRPATH)/data
LOGS_REPORT_INPUT_DIRPATH := $(LOGS_REPORT_DIRPATH)/input

## experiment/report/update
LOGS_REPORT_UPDATE_DIRPATH := $(LOGS_REPORT_DIRPATH)/update

## experiment/report/render
LOGS_REPORT_RENDER_DIRPATH := $(LOGS_REPORT_DIRPATH)/render

PACKAGE_LIST := installed.packages()[,1]

################################################################################
## docker build args
################################################################################
PORT := 5000:80
USER := $(USER)
UID := $(shell id -u)
GID := $(shell id -g)
PASSWORD := $(USER)
R_LIBS_USER := $(DEPENDENCY_LIBRARY_INSTALL_DIRPATH)

R_DYNTRACE := $(PROJECT_DIRPATH)R-dyntrace/bin/R
DOCKR_RUN_ARGS := -t --env="DISPLAY" --volume="/tmp/.X11-unix:/tmp/.X11-unix" -v $(PROJECT_DIRPATH):$(PROJECT_DIRPATH) --publish=$(PORT)

################################################################################
## Applications
################################################################################
TEE := tee
TEE_FLAGS := -i
TIME := time --portability
XVFB_RUN := xvfb-run
MV := mv
RM := rm

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
	       --tag dockr                      \
	       .

docker-container:
	docker run                                        \
	       -d                                         \
	       --interactive                              \
	       --tty                                      \
	       $(DOCKR_RUN_ARGS)                          \
	       dockr                                      \
	       fish

docker-shell:
	docker run                                        \
	       --interactive                              \
	       --tty                                      \
	       $(DOCKR_RUN_ARGS)                          \
	       dockr                                      \
	       fish

define newline


endef

# https://gist.github.com/nicferrier/2277987
define clonepull
if [ ! -d ${3}/.git ]; then                                            \
    git clone --branch ${1} ${2} ${3} 2>&1 | $(TEE) $(TEE_FLAGS) ${4}; \
else                                                                   \
    cd ${3} && git pull origin ${1} 2>&1 | $(TEE) $(TEE_FLAGS) ${4};   \
fi;
endef

define dockr_rdyntrace
docker run $(DOCKR_RUN_ARGS) dockr $(R_DYNTRACE_BIN) -e ${1} 2>&1 | $(TEE) $(TEE_FLAGS) ${2}
endef

define dockr_bash
docker run $(DOCKR_RUN_ARGS) dockr bash -c ${1} 2>&1 | $(TEE) $(TEE_FLAGS) ${2}
endef

define tee
${1} 2>&1 | $(TEE) $(TEE_FLAGS) ${2}
endef

define dockr_make
$(call tee, docker run $(DOCKR_RUN_ARGS) dockr make ${1}, ${2})
endef


define CUSTOM_INSTALL_CODE
install.packages($(PACKAGE_LIST),repos = \"http://cran.us.r-project.org\")
endef


install-custom-packages:
	echo "begin"
	$(call dockr_rdyntrace, "$(subst $(newline), ,$(CUSTOM_INSTALL_CODE))", "/tmp/custom.log")
	echo "here"

.PHONY: install-custom-packages

################################################################################
## dependency
################################################################################

dependency: dependency-dockr       \
            dependency-r-dyntrace  \
            dependency-library     \
            dependency-instrumentr \
            dependency-experimentr \
            dependency-lazr        \
            dependency-strictr

################################################################################
## dependency/dockr
################################################################################

dependency-dockr:
	mkdir -p $(DEPENDENCY_DIRPATH)
	mkdir -p $(LOGS_DEPENDENCY_DIRPATH)
	mkdir -p $(LOGS_DEPENDENCY_DOCKR_DIRPATH)
	$(call clonepull, $(DOCKR_BRANCH), $(DOCKR_GIT_URL), $(DEPENDENCY_DOCKR_DIRPATH), $(LOGS_DEPENDENCY_DOCKR_DIRPATH)/clone.log)
	docker build                                   \
	       --build-arg USER=$(USER)                \
	       --build-arg UID=$(UID)                  \
	       --build-arg GID=$(GID)                  \
	       --build-arg PASSWORD=$(PASSWORD)        \
	       --build-arg R_LIBS_USER=$(R_LIBS_USER)  \
	       --tag dockr                             \
	       $(DEPENDENCY_DOCKR_DIRPATH) 2>&1 | $(TEE) $(TEE_FLAGS) $(LOGS_DEPENDENCY_DOCKR_DIRPATH)/build.log

################################################################################
## dependency/r-dyntrace
################################################################################

dependency-r-dyntrace:
	mkdir -p $(DEPENDENCY_DIRPATH)
	mkdir -p $(LOGS_DEPENDENCY_R_DYNTRACE_DIRPATH)
	$(call clonepull, $(R_DYNTRACE_BRANCH), $(R_DYNTRACE_GIT_URL), $(DEPENDENCY_R_DYNTRACE_DIRPATH), $(LOGS_DEPENDENCY_R_DYNTRACE_DIRPATH)/clone.log)
	$(call dockr_bash, 'cd $(DEPENDENCY_R_DYNTRACE_DIRPATH) && ./build', $(LOGS_DEPENDENCY_R_DYNTRACE_DIRPATH)/build.log)

################################################################################
## dependency/library
################################################################################

dependency-library: dependency-library-mirror  \
                    dependency-library-extract \
                    dependency-library-install \
                    dependency-library-snapshot

################################################################################
## dependency/library/mirror
################################################################################

dependency-library-mirror: dependency-library-mirror-cran  \
                           dependency-library-mirror-bioc

################################################################################
## dependency/library/mirror/cran
################################################################################

dependency-library-mirror-cran:
	@mkdir -p $(DEPENDENCY_LIBRARY_MIRROR_CRAN_DIRPATH)
	@mkdir -p $(LOGS_DEPENDENCY_LIBRARY_MIRROR_CRAN_DIRPATH)
	rsync -zrtlv --delete																																	\
	             --include '/src'																													\
	             --include '/src/contrib'																									\
	             --include '/src/contrib/*.tar.gz'																				\
	             --include '/src/contrib/PACKAGES'																				\
	             --include '/src/contrib/Symlink'																					\
	             --include '/src/contrib/Symlink/**'																			\
	             --exclude '**'																														\
	             cran.r-project.org::CRAN $(DEPENDENCY_LIBRARY_MIRROR_CRAN_DIRPATH) \
	             2>&1 | $(TEE) $(TEE_FLAGS) $(LOGS_DEPENDENCY_LIBRARY_MIRROR_CRAN_DIRPATH)/rsync.log

################################################################################
## dependency/library/mirror/bioc
################################################################################

dependency-library-mirror-bioc:
	@mkdir -p $(DEPENDENCY_LIBRARY_MIRROR_BIOC_RELEASE_DIRPATH)
	@mkdir -p $(LOGS_DEPENDENCY_LIBRARY_MIRROR_BIOC_DIRPATH)
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
	             master.bioconductor.org::release $(DEPENDENCY_LIBRARY_MIRROR_BIOC_RELEASE_DIRPATH) \
	             2>&1 | $(TEE) $(TEE_FLAGS) $(LOGS_DEPENDENCY_LIBRARY_MIRROR_BIOC_DIRPATH)/rsync.log

################################################################################
## dependency/library/extract
################################################################################

dependency-library-extract:
	@mkdir -p $(DEPENDENCY_LIBRARY_EXTRACT_DIRPATH)
	@mkdir -p $(LOGS_DEPENDENCY_LIBRARY_EXTRACT_DIRPATH)
	find $(DEPENDENCY_LIBRARY_MIRROR_CRAN_DIRPATH)/src/contrib               \
	     $(DEPENDENCY_LIBRARY_MIRROR_BIOC_RELEASE_DIRPATH)/bioc/src/contrib  \
	     -maxdepth 1                                                               \
	     -type f                                                                   \
	     -name "*.tar.gz"                                                          \
	     -execdir tar -xvf '{}'                                                    \
	     -C $(DEPENDENCY_LIBRARY_EXTRACT_DIRPATH) \; 2>&1 | $(TEE) $(TEE_FLAGS) $(LOGS_DEPENDENCY_LIBRARY_EXTRACT_DIRPATH)/tar.log

################################################################################
## dependency/library/install
################################################################################

dependency-library-install: dependency-library-install-cran \
                            dependency-library-install-bioc

define INSTALL_CRAN_PACKAGES_CODE
options(repos       = 'file://$(DEPENDENCY_LIBRARY_MIRROR_CRAN_DIRPATH)');
options(BioC_mirror = 'file://$(DEPENDENCY_LIBRARY_MIRROR_BIOC_DIRPATH)');
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


################################################################################
## dependency/library/install/cran
################################################################################

dependency-library-install-cran:
	@mkdir -p $(DEPENDENCY_LIBRARY_INSTALL_DIRPATH)
	@mkdir -p $(LOGS_DEPENDENCY_LIBRARY_INSTALL_DIRPATH)
	@mkdir -p $(LOGS_DEPENDENCY_LIBRARY_INSTALL_CRAN_DIRPATH)
	$(call dockr_rdyntrace, "$(subst $(newline), ,$(INSTALL_CRAN_PACKAGES_CODE))", $(LOGS_DEPENDENCY_LIBRARY_INSTALL_CRAN_DIRPATH)/install.log)
	$(MV) -f *.out $(LOGS_DEPENDENCY_LIBRARY_INSTALL_CRAN_DIRPATH) 2> /dev/null

################################################################################
## dependency/library/install/bioc
################################################################################

define INSTALL_BIOC_PACKAGES_CODE
options(repos       = 'file://$(DEPENDENCY_LIBRARY_MIRROR_CRAN_DIRPATH)');
options(BioC_mirror = 'file://$(DEPENDENCY_LIBRARY_MIRROR_BIOC_DIRPATH)');
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

dependency-repository-install-bioc:
	@mkdir -p $(DEPENDENCY_LIBRARY_INSTALL_DIRPATH)
	@mkdir -p $(LOGS_DEPENDENCY_LIBRARY_INSTALL_DIRPATH)
	@mkdir -p $(LOGS_DEPENDENCY_LIBRARY_INSTALL_BIOC_DIRPATH)

	mkdir -p $(DEPENDENCY_LIBRARY_MIRROR_BIOC)/packages
	ln -sfn $(DEPENDENCY_LIBRARY_MIRROR_BIOC)/release $(DEPENDENCY_LIBRARY_MIRROR_BIOC)/packages/3.12

	$(call dockr_rdyntrace, "$(subst $(newline), ,$(INSTALL_BIOC_PACKAGES_CODE))", $(LOGS_DEPENDENCY_LIBRARY_INSTALL_BIOC_DIRPATH)/install.log)
	$(MV) -f *.out $(LOGS_DEPENDENCY_LIBRARY_INSTALL_BIOC_DIRPATH) 2> /dev/null

dependency-repository-snapshot:
	@echo TODO

################################################################################
## dependency/instrumentr
################################################################################

dependency-instrumentr:
	@mkdir -p $(DEPENDENCY_DIRPATH)
	@mkdir -p $(LOGS_DEPENDENCY_INSTRUMENTR_DIRPATH)
	$(call clonepull, $(INSTRUMENTR_BRANCH), $(INSTRUMENTR_GIT_URL), $(DEPENDENCY_INSTRUMENTR_DIRPATH), $(LOGS_DEPENDENCY_INSTRUMENTR_DIRPATH)/clone.log)
	$(call dockr_make, make -C $(DEPENDENCY_INSTRUMENTR_DIRPATH) R=$(R_DYNTRACE_BIN), $(LOGS_DEPENDENCY_INSTRUMENTR_DIRPATH)/install.log)

################################################################################
## dependency/experimentr
################################################################################

dependency-experimentr:
	@mkdir -p $(DEPENDENCY_DIRPATH)
	@mkdir -p $(LOGS_DEPENDENCY_EXPERIMENTR_DIRPATH)
	$(call clonepull, $(EXPERIMENTR_BRANCH), $(EXPERIMENTR_GIT_URL), $(DEPENDENCY_EXPERIMENTR_DIRPATH), $(LOGS_DEPENDENCY_EXPERIMENTR_DIRPATH)/clone.log)
	$(call dockr_make, -C $(DEPENDENCY_EXPERIMENTR_DIRPATH) R=$(R_DYNTRACE_BIN), $(LOGS_DEPENDENCY_EXPERIMENTR_DIRPATH)/install.log)

################################################################################
## dependency/lazr
################################################################################

dependency-lazr:
	@mkdir -p $(DEPENDENCY_DIRPATH)
	@mkdir -p $(LOGS_DEPENDENCY_LAZR_DIRPATH)
	$(call clonepull,$(LAZR_BRANCH), $(LAZR_GIT_URL), $(DEPENDENCY_LAZR_DIRPATH), $(LOGS_DEPENDENCY_LAZR_DIRPATH)/clone.log)
	$(call dockr_make, -C $(DEPENDENCY_LAZR_DIRPATH) R=$(R_DYNTRACE_BIN), $(LOGS_DEPENDENCY_LAZR_DIRPATH)/install.log)

################################################################################
## dependency/strictr
################################################################################

dependency-strictr:
	@mkdir -p $(DEPENDENCY_DIRPATH)
	@mkdir -p $(LOGS_DEPENDENCY_STRICTR_DIRPATH)
	$(call clonepull, $(STRICTR_BRANCH), $(STRICTR_GIT_URL), $(DEPENDENCY_STRICTR_DIRPATH), $(LOGS_DEPENDENCY_STRICTR_DIRPATH)/clone.log)
	$(call dockr_make, -C $(DEPENDENCY_STRICTR_DIRPATH) R=$(R_DYNTRACE_BIN), $(LOGS_DEPENDENCY_STRICTR_DIRPATH)/install.log)

################################################################################
## experiment
################################################################################

experiment: experiment-corpus		\
            experiment-profile	\
            experiment-remove		\
            experiment-analyze

################################################################################
## experiment/corpus
################################################################################

experiment-corpus: experiment-corpus-extract       \
                   experiment-corpus-sloc          \
                   experiment-corpus-package       \
                   experiment-corpus-deterministic

define CODE_EXTRACT_CODE
library(experimentr);
res <- extract_code($(PACKAGE_LIST),
                    type=c('example', 'vignette', 'testthat', 'test'),
                    index_filepath='$(EXPERIMENT_CORPUS_EXTRACT_INDEX_FILEPATH)',
                    data_dirpath='$(EXPERIMENT_CORPUS_EXTRACT_PROGRAMS_DIRPATH)');
endef


################################################################################
## experiment/corpus/extract
################################################################################

experiment-corpus-extract:
	mkdir -p $(EXPERIMENT_CORPUS_EXTRACT_DIRPATH)
	mkdir -p $(EXPERIMENT_CORPUS_EXTRACT_PROGRAMS_DIRPATH)
	mkdir -p $(LOGS_CORPUS_EXTRACT_DIRPATH)
	$(call dockr_rdyntrace, "$(subst $(newline), ,$(CODE_EXTRACT_CODE))", $(LOGS_CORPUS_EXTRACT_DIRPATH)/extract.log)

################################################################################
## experiment/corpus/sloc
################################################################################

experiment-corpus-sloc: experiment-corpus-sloc-corpus  \
                        experiment-corpus-sloc-package

################################################################################
## experiment/corpus/sloc/corpus
################################################################################

define CORPUS_SLOC
library(experimentr);
res <- compute_sloc('$(EXPERIMENT_CORPUS_EXTRACT_PROGRAMS_DIRPATH)',
                    output_filepath='$(EXPERIMENT_CORPUS_SLOC_CORPUS_FILEPATH)',
                    echo = TRUE);
endef

experiment-corpus-sloc-corpus:
	mkdir -p $(EXPERIMENT_CORPUS_SLOC_CORPUS_DIRPATH)
	mkdir -p $(LOGS_CORPUS_SLOC_CORPUS_DIRPATH)
	$(call dockr_rdyntrace, "$(subst $(newline), ,$(CORPUS_SLOC))", $(LOGS_CORPUS_SLOC_CORPUS_DIRPATH)/sloc.log)


################################################################################
## experiment/corpus/sloc/package
################################################################################

define PACKAGE_SLOC
library(experimentr);
res <- compute_sloc('$(DEPENDENCY_LIBRARY_EXTRACT_DIRPATH)',
                    output_filepath='$(EXPERIMENT_CORPUS_SLOC_PACKAGE_FILEPATH)',
                    echo = FALSE);
endef

experiment-corpus-sloc-package:
	mkdir -p $(EXPERIMENT_CORPUS_SLOC_PACKAGE_DIRPATH)
	mkdir -p $(LOGS_CORPUS_SLOC_PACKAGE_DIRPATH)
	$(call dockr_rdyntrace, "$(subst $(newline), ,$(PACKAGE_SLOC))", $(LOGS_CORPUS_SLOC_PACKAGE_DIRPATH)/sloc.log)


################################################################################
## experiment/corpus/package
################################################################################

define CORPUS_PACKAGE
library(experimentr);
get_package_info($(PACKAGE_LIST),
                 progress = TRUE,
                 output_filepath='$(EXPERIMENT_CORPUS_PACKAGE_INFO_FILEPATH)');
endef

experiment-corpus-package:
	mkdir -p $(EXPERIMENT_CORPUS_PACKAGE_DIRPATH)
	mkdir -p $(LOGS_CORPUS_PACKAGE_DIRPATH)
	$(call dockr_rdyntrace, "$(subst $(newline), ,$(CORPUS_PACKAGE))", $(LOGS_CORPUS_PACKAGE_DIRPATH)/package.log)

################################################################################
## experiment/corpus/deterministic
################################################################################
experiment-corpus-deterministic:
	@echo TODO

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
## experiment/report
################################################################################
experiment-report: experiment-report-paper  \
                   experiment-report-input  \
                   experiment-report-update \
                   experiment-report-render

################################################################################
## experiment/report/paper
################################################################################
experiment-report-paper:
	@mkdir -p $(EXPERIMENT_REPORT_DIRPATH)
	@mkdir -p $(LOGS_REPORT_PAPER_DIRPATH)
	$(call clonepull, $(PAPER_BRANCH), $(PAPER_GIT_URL), $(EXPERIMENT_REPORT_PAPER_DIRPATH), $(LOGS_REPORT_PAPER_DIRPATH)/clone.log)

################################################################################
## experimentr/report/input
################################################################################
experiment-report-input:
	mkdir -p $(EXPERIMENT_REPORT_PAPER_DATA_DIRPATH)
	mkdir -p $(LOGS_REPORT_INPUT_DIRPATH)
	cp $(EXPERIMENT_CORPUS_EXTRACT_INDEX_FILEPATH)  $(EXPERIMENT_REPORT_PAPER_DATA_DIRPATH)/extract-index.fst
	cp $(EXPERIMENT_CORPUS_SLOC_CORPUS_FILEPATH)  $(EXPERIMENT_REPORT_PAPER_DATA_DIRPATH)/sloc-corpus.fst
	cp $(EXPERIMENT_CORPUS_SLOC_PACKAGE_FILEPATH)  $(EXPERIMENT_REPORT_PAPER_DATA_DIRPATH)/sloc-package.fst
	cp $(EXPERIMENT_CORPUS_PACKAGE_INFO_FILEPATH) $(EXPERIMENT_REPORT_PAPER_DATA_DIRPATH)/package-info.fst

################################################################################
## experiment/report/render
################################################################################

experiment-report-render:
	mkdir -p $(LOGS_REPORT_RENDER_DIRPATH)
	$(call dockr_make, -C $(EXPERIMENT_REPORT_PAPER_DIRPATH) report R=$(R_DYNTRACE_BIN), $(LOGS_REPORT_RENDER_DIRPATH)/render.log)

################################################################################
## experiment/report/update
################################################################################

experiment-report-update:
	mkdir -p $(EXPERIMENT_REPORT_PAPER_DATA_DIRPATH)
	mkdir -p $(LOGS_REPORT_UPDATE_DIRPATH)
	$(call tee, git -C $(EXPERIMENT_REPORT_PAPER_DIRPATH) add *.fst *.html, $(LOGS_REPORT_UPDATE_DIRPATH)/add.log)
	$(call tee, git -C $(EXPERIMENT_REPORT_PAPER_DIRPATH) diff-index --quiet HEAD || git -C $(EXPERIMENT_REPORT_PAPER_DIRPATH) commit -m "Update data on $(shell date) by $(shell hostname)", $(LOGS_REPORT_UPDATE_DIRPATH)/commit.log)
	$(call tee, git -C $(EXPERIMENT_REPORT_PAPER_DIRPATH) push origin $(PAPER_BRANCH), $(LOGS_REPORT_UPDATE_DIRPATH)/push.log)
