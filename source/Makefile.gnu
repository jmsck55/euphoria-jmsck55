# GNU Makefile for Euphoria Unix systems
#
# NOTE: This is meant to be used with GNU make,
#       so on BSD, you should use gmake instead
#       of make
#
# Syntax:
#
#   You must run configure before building
#
#   Configure the make system :  ./configure
#                                path/to/configure
#
#   Clean up binary files     :  make clean
#   Clean up binary and       :  make distclean clobber
#        translated files
#   eui, euc, eub, eu.a       :  make
#   Interpreter          (eui):  make interpreter
#   Translator           (euc):  make translator
#   Translator Library  (eu.a):  make library
#   Backend              (eub):  make backend
#   Utilities/Binder/Shrouder :  make tools (requires translator and library)
#   Run Unit Tests            :  make test (requires interpreter, translator, backend, binder)
#   Run Unit Tests with eu.ex :  make testeu
#   Run coverage analysis     :  make coverage
#   Code Page Database        :  make code-page-db
#   Generate automatic        :  make depend
#   dependencies (requires
#   makedepend to be installed)
#
#   Html Documentation        :  make htmldoc 
#   PDF Documentation         :  make pdfdoc
#   Test eucode blocks in API
#       comments              :  make test-eucode
#
#   Note that Html and PDF Documentation require eudoc and creole
#   PDF docs also require a complete LaTeX installation
#
#   eudoc can be retrieved via make get-eudoc if you have
#   Mercurial installed.
#
#   creole can be retrieved via make get-creole if you have
#   Mercurial installed.
#

CONFIG_FILE = config.gnu
CC=$(CC_PREFIX)$(CC_SUFFIX)
RC=$(CC_PREFIX)$(RC_SUFFIX)
ifndef CONFIG
CONFIG = ${CURDIR}/$(CONFIG_FILE)
endif

PCRE_CC=$(CC)


include $(CONFIG)
include $(TRUNKDIR)/source/pcre/objects.mak

ifeq "$(EHOST)" "$(ETARGET)"
HOSTCC=$(CC)
else
# so far this is all we support
HOSTCC=gcc
endif

ifeq "$(RELEASE)" "1"
RELEASE_FLAG = -D EU_FULL_RELEASE
endif

ifdef ERUNTIME
RUNTIME_FLAGS = -DERUNTIME
endif

ifdef EBACKEND
BACKEND_FLAGS = -DBACKEND
endif

ifeq "$(EBSD)" "1"
  LDLFLAG=
  EBSDFLAG=-DEBSD -DEBSD62
  SEDFLAG=-Ei
  ifeq "$(EOSX)" "1"
    LDLFLAG=-lresolv
    EBSDFLAG=-DEBSD -DEBSD62 -DEOSX
  endif
  ifeq "$(EOPENBSD)" "1"
    EBSDFLAG=-DEBSD -DEBSD62 -DEOPENBSD
  endif
  ifeq "$(ENETBSD)" "1"
    EBSDFLAG=-DEBSD -DEBSD62 -DENETBSD
  endif
else
  LDLFLAG=-ldl -lresolv -lnsl
  PREREGEX=$(FROMBSDREGEX)
  SEDFLAG=-ri
endif
ifeq "$(EMINGW)" "1"
	EXE_EXT=.exe
	ifeq "$(EHOST)" "EWINDOWS"
		HOST_EXE_EXT=.exe
	endif
	EPTHREAD=
	EOSTYPE=-DEWINDOWS
	EBSDFLAG=-DEMINGW
	LDLFLAG=
	SEDFLAG=-ri
	EOSFLAGS=$(NO_CYGWIN) -mwindows
	EOSFLAGSCONSOLE=$(NO_CYGWIN)
	EOSPCREFLAGS=$(NO_CYGWIN)
	EECUA=eu.a
	EECUDBGA=eudbg.a
	EECUSOA=euso.a
	EECUSODBGA=eusodbg.a
	ifdef EDEBUG
		EOSMING=
		ifdef FPIC
			LIBRARY_NAME=eusodbg.a
		else
			LIBRARY_NAME=eudbg.a
		endif
	else
		EOSMING=-ffast-math -O3 -Os
		ifdef FPIC
			LIBRARY_NAME=euso.a
		else
			LIBRARY_NAME=eu.a
		endif
	endif
	EUBW_RES=$(BUILDDIR)/eubw.res
	EUB_RES=$(BUILDDIR)/eub.res
	EUC_RES=$(BUILDDIR)/euc.res
	EUI_RES=$(BUILDDIR)/eui.res
	EUIW_RES=$(BUILDDIR)/euiw.res
	ifeq "$(MANAGED_MEM)" "1"
		ifeq "$(ALIGN4)" "1"
			MEM_FLAGS=-DEALIGN4
		else
			MEM_FLAGS=
		endif
	else
		ifeq "$(ALIGN4)" "1"
			MEM_FLAGS=-DEALIGN4 -DESIMPLE_MALLOC
		else
			MEM_FLAGS=-DESIMPLE_MALLOC
		endif
	endif
	CREATEDLLFLAGS=-Wl,--out-implib,lib818dll.a 
else
	EXE_EXT=
	EPTHREAD=-pthread
	EOSTYPE=-DEUNIX
	EOSFLAGS=
	EOSFLAGSCONSOLE=
	EOSPCREFLAGS=
	EECUA=eu.a
	EECUDBGA=eudbg.a
	EECUSOA=euso.a
	EECUSODBGA=eusodbg.a
	ifdef EDEBUG
		ifdef FPIC
			LIBRARY_NAME=eusodbg.a
		else
			LIBRARY_NAME=eudbg.a
		endif
	else
		EOSMING=-ffast-math -O3 -Os
		ifdef FPIC
			LIBRARY_NAME=euso.a
		else
			LIBRARY_NAME=eu.a
		endif
	endif
	MEM_FLAGS=-DESIMPLE_MALLOC
	CREATEDLLFLAGS=
endif

MKVER=$(BUILDDIR)/mkver$(EXE_EXT)
ifeq "$(EMINGW)" "1"
	# Windowed backend
	EBACKENDW=eubw$(EXE_EXT)
endif
# Console based backend
EBACKENDC=eub$(EXE_EXT)
EECU=euc$(EXE_EXT)
EEXU=eui$(EXE_EXT)
HOST_EEXU=eui$(HOST_EXE_EXT)
EEXUW=euiw$(EXE_EXT)

LDLFLAG+= $(EPTHREAD)

ifdef EDEBUG
DEBUG_FLAGS=-g3 -O0 -Wall
CALLC_DEBUG=-g3
EC_DEBUG=-D DEBUG
EUC_DEBUG_FLAG=-debug
else
DEBUG_FLAGS=-fomit-frame-pointer $(EOSMING)
endif

ifdef EPROFILE
PROFILE_FLAGS=-pg -g
ifndef EDEBUG
DEBUG_FLAGS=$(EOSMING)
endif
endif

ifdef ENO_DBL_CACHE
MEM_FLAGS+=-DNO_DBL_CACHE
endif

ifdef COVERAGE
COVERAGEFLAG=-fprofile-arcs -ftest-coverage
DEBUG_FLAGS=-g3 -O0 -Wall
COVERAGELIB=-lgcov
endif

ifndef TESTFILE
COVERAGE_ERASE=-coverage-erase
endif

ifeq  "$(ELINUX)" "1"
EBSDFLAG=-DELINUX
endif

# backwards compatibility
# don't make Unix users reconfigure for a MinGW-only change
ifndef CYPTRUNKDIR
CYPTRUNKDIR=$(TRUNKDIR)
endif
ifndef CYPBUILDDIR
CYPBUILDDIR=$(BUILDDIR)
endif

ifeq "$(ELINUX)" "1"
PLAT=LINUX
else ifeq "$(EOPENBSD)" "1"
PLAT=OPENBSD
else ifeq "$(ENETBSD)" "1"
PLAT=NETBSD
else ifeq "$(EFREEBSD)" "1"
PLAT=FREEBSD
else ifeq "$(EOSX)" "1"
PLAT=OSX
else ifeq "$(EMINGW)" "1"
PLAT=WINDOWS
endif

# We mustn't use eui rather than $(EEXU) in these three lines below.   When this translates from Unix, the interpreter we call to do the translation must not have a .exe extension. 
ifeq  "$(EUBIN)" ""
EXE=$(EEXU)
HOST_EXE=$(HOST_EEXU)
else
EXE=$(EUBIN)/$(EEXU)
HOST_EXE=$(EUBIN)/$(HOST_EEXU)
endif
# The -i command with the include directory in the form we need the EUPHORIA binaries to see them. 
# (Use a drive id 'C:')
# [Which on Windows is different from the how it is expressed in for the GNU binaries. ]
CYPINCDIR=-i $(CYPTRUNKDIR)/include


BE_CALLC = be_callc

ifndef ECHO
ECHO=/bin/echo
endif

ifeq "$(EUDOC)" ""
EUDOC=eudoc
endif

ifeq "$(CREOLE)" ""
CREOLE=creole
endif

ifeq "$(TRANSLATE)" "euc"
	TRANSLATE="euc"
else
#   We MUST pass these arguments to $(EXE), for $(EXE) is not and shouldn't be governed by eu.cfg in BUILDDIR.
	TRANSLATE=$(HOST_EXE) $(CYPINCDIR) $(EC_DEBUG) $(EFLAG) $(CYPTRUNKDIR)/source/euc.ex $(EUC_DEBUG_FLAG)
endif

ifeq "$(ARCH)" "ARM"
	ARCH_FLAG=-DEARM
else ifeq "$(ARCH)" "ix86"
	ARCH_FLAG=-DEX86
	# Mostly for OSX, but prevents bad conversions double<-->long
	# See ticket #874
	FP_FLAGS=-mno-sse
else ifeq "$(ARCH)" "ix86_64"
	ARCH_FLAG=-DEX86_64
endif


ifeq "$(MANAGED_MEM)" "1"
FE_FLAGS =  $(ARCH_FLAG) $(COVERAGEFLAG) $(MSIZE) $(EPTHREAD) -c -fsigned-char $(EOSTYPE) $(EOSMING) -ffast-math $(FP_FLAGS) $(EOSFLAGS) $(DEBUG_FLAGS) -I$(CYPTRUNKDIR)/source -I$(CYPTRUNKDIR) $(PROFILE_FLAGS) -DARCH=$(ARCH) $(EREL_TYPE) $(MEM_FLAGS)
else
FE_FLAGS =  $(ARCH_FLAG) $(COVERAGEFLAG) $(MSIZE) $(EPTHREAD) -c -fsigned-char $(EOSTYPE) $(EOSMING) -ffast-math $(FP_FLAGS) $(EOSFLAGS) $(DEBUG_FLAGS) -I$(CYPTRUNKDIR)/source -I$(CYPTRUNKDIR) $(PROFILE_FLAGS) -DARCH=$(ARCH) $(EREL_TYPE)
endif
BE_FLAGS =  $(ARCH_FLAG) $(COVERAGEFLAG) $(MSIZE) $(EPTHREAD) -c -Wall $(EOSTYPE) $(EBSDFLAG) $(RUNTIME_FLAGS) $(EOSFLAGS) $(BACKEND_FLAGS) -fsigned-char -ffast-math $(FP_FLAGS) $(DEBUG_FLAGS) $(MEM_FLAGS) $(PROFILE_FLAGS) -DARCH=$(ARCH) $(EREL_TYPE) $(FPIC) -I$(TRUNKDIR)/source

EU_CORE_FILES = \
	$(TRUNKDIR)/source/block.e \
	$(TRUNKDIR)/source/common.e \
	$(TRUNKDIR)/source/coverage.e \
	$(TRUNKDIR)/source/emit.e \
	$(TRUNKDIR)/source/error.e \
	$(TRUNKDIR)/source/fwdref.e \
	$(TRUNKDIR)/source/inline.e \
	$(TRUNKDIR)/source/keylist.e \
	$(TRUNKDIR)/source/main.e \
	$(TRUNKDIR)/source/msgtext.e \
	$(TRUNKDIR)/source/mode.e \
	$(TRUNKDIR)/source/opnames.e \
	$(TRUNKDIR)/source/parser.e \
	$(TRUNKDIR)/source/pathopen.e \
	$(TRUNKDIR)/source/platform.e \
	$(TRUNKDIR)/source/preproc.e \
	$(TRUNKDIR)/source/reswords.e \
	$(TRUNKDIR)/source/scanner.e \
	$(TRUNKDIR)/source/shift.e \
	$(TRUNKDIR)/source/syncolor.e \
	$(TRUNKDIR)/source/symtab.e 

# TODO XXX should syncolor.e really be in EU_INTERPRETER_FILES ?

EU_INTERPRETER_FILES = \
	$(TRUNKDIR)/source/backend.e \
	$(TRUNKDIR)/source/c_out.e \
	$(TRUNKDIR)/source/cominit.e \
	$(TRUNKDIR)/source/compress.e \
	$(TRUNKDIR)/source/global.e \
	$(TRUNKDIR)/source/intinit.e \
	$(TRUNKDIR)/source/eui.ex

EU_TRANSLATOR_FILES = \
	$(TRUNKDIR)/source/buildsys.e \
	$(TRUNKDIR)/source/c_decl.e \
	$(TRUNKDIR)/source/c_out.e \
	$(TRUNKDIR)/source/cominit.e \
	$(TRUNKDIR)/source/compile.e \
	$(TRUNKDIR)/source/compress.e \
	$(TRUNKDIR)/source/global.e \
	$(TRUNKDIR)/source/traninit.e \
	$(TRUNKDIR)/source/euc.ex

EU_BACKEND_RUNNER_FILES = \
	$(TRUNKDIR)/source/backend.e \
	$(TRUNKDIR)/source/il.e \
	$(TRUNKDIR)/source/cominit.e \
	$(TRUNKDIR)/source/compress.e \
	$(TRUNKDIR)/source/error.e \
	$(TRUNKDIR)/source/intinit.e \
	$(TRUNKDIR)/source/mode.e \
	$(TRUNKDIR)/source/reswords.e \
	$(TRUNKDIR)/source/pathopen.e \
	$(TRUNKDIR)/source/common.e \
	$(TRUNKDIR)/source/backend.ex
PREFIXED_PCRE_OBJECTS = $(addprefix $(BUILDDIR)/pcre$(FPIC)/,$(PCRE_OBJECTS))

EU_BACKEND_OBJECTS = \
	$(BUILDDIR)/$(OBJDIR)/back/be_decompress.o \
	$(BUILDDIR)/$(OBJDIR)/back/be_debug.o \
	$(BUILDDIR)/$(OBJDIR)/back/be_execute.o \
	$(BUILDDIR)/$(OBJDIR)/back/be_task.o \
	$(BUILDDIR)/$(OBJDIR)/back/be_main.o \
	$(BUILDDIR)/$(OBJDIR)/back/be_alloc.o \
	$(BUILDDIR)/$(OBJDIR)/back/be_callc.o \
	$(BUILDDIR)/$(OBJDIR)/back/be_inline.o \
	$(BUILDDIR)/$(OBJDIR)/back/be_machine.o \
	$(BUILDDIR)/$(OBJDIR)/back/be_coverage.o \
	$(BUILDDIR)/$(OBJDIR)/back/be_pcre.o \
	$(BUILDDIR)/$(OBJDIR)/back/be_rterror.o \
	$(BUILDDIR)/$(OBJDIR)/back/be_syncolor.o \
	$(BUILDDIR)/$(OBJDIR)/back/be_runtime.o \
	$(BUILDDIR)/$(OBJDIR)/back/be_symtab.o \
	$(BUILDDIR)/$(OBJDIR)/back/be_socket.o \
	$(BUILDDIR)/$(OBJDIR)/back/be_w.o \
	$(PREFIXED_PCRE_OBJECTS)

EU_LIB_OBJECTS = \
	$(BUILDDIR)/$(OBJDIR)/back/be_decompress.o \
	$(BUILDDIR)/$(OBJDIR)/back/be_machine.o \
	$(BUILDDIR)/$(OBJDIR)/back/be_coverage.o \
	$(BUILDDIR)/$(OBJDIR)/back/be_w.o \
	$(BUILDDIR)/$(OBJDIR)/back/be_alloc.o \
	$(BUILDDIR)/$(OBJDIR)/back/be_inline.o \
	$(BUILDDIR)/$(OBJDIR)/back/be_pcre.o \
	$(BUILDDIR)/$(OBJDIR)/back/be_socket.o \
	$(BUILDDIR)/$(OBJDIR)/back/be_syncolor.o \
	$(BUILDDIR)/$(OBJDIR)/back/be_runtime.o \
	$(BUILDDIR)/$(OBJDIR)/back/be_task.o \
	$(BUILDDIR)/$(OBJDIR)/back/be_callc.o \
	$(PREFIXED_PCRE_OBJECTS)
	
# The bare include directory in this checkout as we want the make file to see it.  Forward slashes, no 'C:'. 
# Which (on Windows) is different to the way we need to give paths to EUPHORIA's binaries.
INCDIR = $(TRUNKDIR)/include

EU_STD_INC = \
	$(wildcard $(INCDIR)/std/*.e) \
	$(wildcard $(INCDIR)/std/unix/*.e) \
	$(wildcard $(INCDIR)/std/net/*.e) \
	$(wildcard $(INCDIR)/std/win32/*.e) \
	$(wildcard $(INCDIR)/euphoria/*.e)

DOCDIR = $(TRUNKDIR)/docs
EU_DOC_SOURCE = \
	$(EU_STD_INC) \
	$(DOCDIR)/manual.af \
	$(wildcard $(DOCDIR)/*.txt) \
	$(wildcard $(INCDIR)/euphoria/debug/*.e) \
	$(wildcard $(DOCDIR)/release/*.txt)

EU_TRANSLATOR_OBJECTS = $(patsubst %.c,%.o,$(wildcard $(BUILDDIR)/transobj/*.c))
EU_BACKEND_RUNNER_OBJECTS = $(patsubst %.c,%.o,$(wildcard $(BUILDDIR)/backobj/*.c))
EU_INTERPRETER_OBJECTS = $(patsubst %.c,%.o,$(wildcard $(BUILDDIR)/intobj/*.c))

all : 
	$(MAKE) interpreter translator library debug-library backend shared-library debug-shared-library lib818
	$(MAKE) tools


BUILD_DIRS=\
	$(BUILDDIR)/intobj/back/ \
	$(BUILDDIR)/transobj/back/ \
	$(BUILDDIR)/libobj/back/ \
	$(BUILDDIR)/libobjdbg \
	$(BUILDDIR)/libobjdbg/back/ \
	$(BUILDDIR)/backobj/back/ \
	$(BUILDDIR)/intobj/ \
	$(BUILDDIR)/transobj/ \
	$(BUILDDIR)/libobj/ \
	$(BUILDDIR)/backobj/ \
	$(BUILDDIR)/include/ \
	$(BUILDDIR)/libobj-fPIC/ \
	$(BUILDDIR)/libobj-fPIC/back \
	$(BUILDDIR)/libobjdbg-fPIC \
	$(BUILDDIR)/libobjdbg-fPIC/back


clean : 	
	-for f in $(BUILD_DIRS) ; do \
		rm -r $${f} ; \
	done ;
	-rm -r $(BUILDDIR)/pcre
	-rm -r $(BUILDDIR)/pcre_fpic
	-rm $(BUILDDIR)/*pdf
	-rm $(BUILDDIR)/*txt
	-rm -r $(BUILDDIR)/*-build
	-rm $(BUILDDIR)/eui$(EXE_EXT) $(BUILDDIR)/$(EEXUW)
	-rm $(BUILDDIR)/$(EECU)
	-rm $(BUILDDIR)/$(EBACKENDC) $(BUILDDIR)/$(EBACKENDW)
	-rm $(BUILDDIR)/eu.a
	-rm $(BUILDDIR)/eudbg.a
	-rm $(BUILDDIR)/euso.a
	-for f in $(EU_TOOLS) ; do \
		rm $${f} ; \
	done ;
	rm -f $(BUILDDIR)/euphoria.{pdf,txt}
	-rm $(BUILDDIR)/ver.cache
	-rm $(BUILDDIR)/mkver$(EXE_EXT)
	-rm $(BUILDDIR)/eudist$(EXE_EXT) $(BUILDDIR)/echoversion$(EXE_EXT)
	-rm $(BUILDDIR)/test818.o
	-rm -r $(BUILDDIR)/html
	-rm -r $(BUILDDIR)/coverage
	-rm -r $(BUILDDIR)/manual
	-rm $(TRUNKDIR)/tests/lib818.dll	
	-rm $(BUILDDIR)/*.res

clobber distclean : clean
	-rm -f $(CONFIG)
	-rm -f Makefile
	-rm -fr $(BUILDDIR)
	-rm eu.cfg

	$(MAKE) -C pcre CONFIG=$(BUILDDIR)/$(CONFIG) clean
	$(MAKE) -C pcre CONFIG=$(BUILDDIR)/$(CONFIG) FPIC=-fPIC clean
	

.PHONY : clean distclean clobber all htmldoc manual lib818

debug-library : builddirs
	$(MAKE) $(BUILDDIR)/$(EECUDBGA) OBJDIR=libobjdbg ERUNTIME=1 CONFIG=$(CONFIG) EDEBUG=1 EPROFILE=$(EPROFILE)

library : builddirs
	$(MAKE) $(BUILDDIR)/$(EECUA) OBJDIR=libobj ERUNTIME=1 CONFIG=$(CONFIG) EDEBUG= EPROFILE=$(EPROFILE)


shared-library :
ifneq "$(EMINGW)" "1"
	$(MAKE) $(BUILDDIR)/$(EECUSOA) OBJDIR=libobj-fPIC ERUNTIME=1 CONFIG=$(CONFIG) EDEBUG= EPROFILE=$(EPROFILE) FPIC=-fPIC
endif

debug-shared-library : builddirs
ifneq "$(EMINGW)" "1"
	$(MAKE) $(BUILDDIR)/$(EECUSODBGA) OBJDIR=libobjdbg-fPIC ERUNTIME=1 CONFIG=$(CONFIG) EDEBUG=1 EPROFILE=$(EPROFILE) FPIC=-fPIC
endif

# All code in Ming is position independent.  So simply link
# to the other existing one.
ifeq "$(EMINGW)" "1"
ifdef FPIC
ifdef EDEBUG
$(BUILDDIR)/$(LIBRARY_NAME) : $(BUILDDIR)/eudbg.a
else
$(BUILDDIR)/$(LIBRARY_NAME) : $(BUILDDIR)/eu.a
endif
	ln -f $<  $@
else
$(BUILDDIR)/$(LIBRARY_NAME) : $(EU_LIB_OBJECTS)
	$(CC_PREFIX)ar -rc $(BUILDDIR)/$(LIBRARY_NAME) $(EU_LIB_OBJECTS)
	$(ECHO) $(MAKEARGS)
endif
else
$(BUILDDIR)/$(LIBRARY_NAME) : $(EU_LIB_OBJECTS)
	$(CC_PREFIX)ar -rc $(BUILDDIR)/$(LIBRARY_NAME) $(EU_LIB_OBJECTS)
	$(ECHO) $(MAKEARGS)
endif
builddirs : $(BUILD_DIRS)

$(BUILD_DIRS) :
	mkdir -p $(BUILD_DIRS) 

ifeq "$(ROOTDIR)" ""
ROOTDIR=$(TRUNKDIR)
endif

code-page-db : $(BUILDDIR)/ecp.dat

$(BUILDDIR)/ecp.dat : $(TRUNKDIR)/source/codepage/*.ecp
	$(BUILDDIR)/$(EEXU) -i $(CYPTRUNKDIR)/include $(CYPTRUNKDIR)/bin/buildcpdb.ex -p$(CYPTRUNKDIR)/source/codepage -o$(CYPBUILDDIR)


ifeq "$(OBJDIR)" ""
interpreter :
	$(MAKE) interpreter OBJDIR=intobj EBSD=$(EBSD) CONFIG=$(CONFIG) EDEBUG=$(EDEBUG) EPROFILE=$(EPROFILE)

translator :
	$(MAKE) translator OBJDIR=transobj EBSD=$(EBSD) CONFIG=$(CONFIG) EDEBUG=$(EDEBUG) EPROFILE=$(EPROFILE)
else

ifeq "$(EUPHORIA)" "1"
interpreter : euisource
translator  : eucsource
backend     : backendsource
endif

interpreter : builddirs $(EU_BACKEND_OBJECTS)
	$(MAKE) $(BUILDDIR)/$(EEXU) OBJDIR=intobj EBSD=$(EBSD) CONFIG=$(CONFIG) EDEBUG=$(EDEBUG) EPROFILE=$(EPROFILE)

translator  : builddirs $(EU_BACKEND_OBJECTS)
	$(MAKE) $(BUILDDIR)/$(EECU) OBJDIR=transobj EBSD=$(EBSD) CONFIG=$(CONFIG) EDEBUG=$(EDEBUG) EPROFILE=$(EPROFILE)

endif



EUBIND=eubind$(EXE_EXT)
EUSHROUD=eushroud$(EXE_EXT)

binder : translator library $(EU_BACKEND_RUNNER_FILES)
	$(MAKE) $(BUILDDIR)/$(EUBIND)
	$(MAKE) $(BUILDDIR)/$(EUSHROUD)

.PHONY : library debug-library
.PHONY : builddirs
.PHONY : interpreter
.PHONY : translator
.PHONY : svn_rev
.PHONY : code-page-db-rm $(BUILDDIR)/eui
.PHONY : binder

euisource : $(BUILDDIR)/intobj/main-.c
euisource :  EU_TARGET = eui.ex
euisource : $(BUILDDIR)/include/be_ver.h
eucsource : $(BUILDDIR)/transobj/main-.c
eucsource :  EU_TARGET = euc.ex
eucsource : $(BUILDDIR)/include/be_ver.h
backendsource : $(BUILDDIR)/backobj/main-.c
backendsource :  EU_TARGET = backend.ex
backendsource : $(BUILDDIR)/include/be_ver.h

source : builddirs
	$(MAKE) euisource OBJDIR=intobj EBSD=$(EBSD) CONFIG=$(CONFIG) EDEBUG=$(EDEBUG) EPROFILE=$(EPROFILE)
	$(MAKE) eucsource OBJDIR=transobj EBSD=$(EBSD) CONFIG=$(CONFIG) EDEBUG=$(EDEBUG) EPROFILE=$(EPROFILE)
	$(MAKE) backendsource OBJDIR=backobj EBSD=$(EBSD) CONFIG=$(CONFIG) EDEBUG=$(EDEBUG) EPROFILE=$(EPROFILE)

ifneq "$(VERSION)" ""
SOURCEDIR=euphoria-$(PLAT)-$(VERSION)
else
ifeq "$(REV)" ""
REV := $(shell hg parents --template '{node|short}')
endif

ifeq "$(PLAT)" ""
SOURCEDIR=euphoria-$(REV)
else
SOURCEDIR=euphoria-$(PLAT)-$(REV)
TARGETPLAT=-plat $(PLAT)
endif

endif

source-tarball :
	echo building source-tarball for $(PLAT)
	rm -rf $(BUILDDIR)/$(SOURCEDIR)
	hg archive $(BUILDDIR)/$(SOURCEDIR)
	mkdir $(BUILDDIR)/$(SOURCEDIR)/build
	cd $(BUILDDIR)/$(SOURCEDIR)/build && ../source/configure $(CONFIGURE_PARAMS)
	$(MAKE) -C $(BUILDDIR)/$(SOURCEDIR)/build source
	-rm $(BUILDDIR)/$(SOURCEDIR)/build/config.gnu
	-rm $(BUILDDIR)/$(SOURCEDIR)/build/mkver$(EXE_EXT)
	cd $(BUILDDIR) && tar -zcf $(SOURCEDIR)-src.tar.gz $(SOURCEDIR)
ifneq "$(VERSION)" ""
	cd $(BUILDDIR) && mkdir -p $(PLAT) && mv $(SOURCEDIR)-src.tar.gz $(PLAT)
endif

.PHONY : euisource
.PHONY : eucsource
.PHONY : backendsource
.PHONY : source

ifeq "$(EMINGW)" "1"
$(EUI_RES) :  $(TRUNKDIR)/source/eui.rc  $(TRUNKDIR)/source/version_info.rc  $(TRUNKDIR)/source/eu.manifest
$(EUIW_RES) :  $(TRUNKDIR)/source/euiw.rc  $(TRUNKDIR)/source/version_info.rc  $(TRUNKDIR)/source/eu.manifest
endif

$(BUILDDIR)/$(EEXU) :  EU_TARGET = eui.ex
$(BUILDDIR)/$(EEXU) :  EU_MAIN = $(EU_CORE_FILES) $(EU_INTERPRETER_FILES) $(EU_STD_INC)
$(BUILDDIR)/$(EEXU) :  EU_OBJS = $(EU_INTERPRETER_OBJECTS) $(EU_BACKEND_OBJECTS)
$(BUILDDIR)/$(EEXU) :  $(EU_INTERPRETER_OBJECTS) $(EU_BACKEND_OBJECTS) $(EU_TRANSLATOR_FILES) $(EUI_RES) $(EUIW_RES)
	@$(ECHO) making $(EEXU)
	@echo $(OS)
ifeq "$(EMINGW)" "1"
	$(CC) $(EOSFLAGSCONSOLE) $(EUI_RES) $(EU_INTERPRETER_OBJECTS) $(EU_BACKEND_OBJECTS) -lm $(LDLFLAG) $(COVERAGELIB) -o $(BUILDDIR)/$(EEXU)
	$(CC) $(EOSFLAGS) $(EUIW_RES) $(EU_INTERPRETER_OBJECTS) $(EU_BACKEND_OBJECTS) -lm $(LDLFLAG) $(COVERAGELIB) -o $(BUILDDIR)/$(EEXUW)
else
	$(CC) $(EOSFLAGS) $(EU_INTERPRETER_OBJECTS) $(EU_BACKEND_OBJECTS) -lm $(LDLFLAG) $(COVERAGELIB) $(PROFILE_FLAGS) $(MSIZE) -o $(BUILDDIR)/$(EEXU)
endif

$(BUILDDIR)/$(OBJDIR)/back/be_machine.o : $(BUILDDIR)/include/be_ver.h

ifeq "$(EMINGW)" "1"
$(EUC_RES) :  $(TRUNKDIR)/source/euc.rc  $(TRUNKDIR)/source/version_info.rc  $(TRUNKDIR)/source/eu.manifest
endif

$(BUILDDIR)/$(EECU) :  OBJDIR = transobj
$(BUILDDIR)/$(EECU) :  EU_TARGET = euc.ex
$(BUILDDIR)/$(EECU) :  EU_MAIN = $(EU_CORE_FILES) $(EU_TRANSLATOR_FILES) $(EU_STD_INC)
$(BUILDDIR)/$(EECU) :  EU_OBJS = $(EU_TRANSLATOR_OBJECTS) $(EU_BACKEND_OBJECTS)
$(BUILDDIR)/$(EECU) : $(EU_TRANSLATOR_OBJECTS) $(EU_BACKEND_OBJECTS) $(EUC_RES)
	@$(ECHO) making $(EECU)
	$(CC) $(EOSFLAGSCONSOLE) $(EUC_RES) $(EU_TRANSLATOR_OBJECTS) $(DEBUG_FLAGS) $(PROFILE_FLAGS) $(EU_BACKEND_OBJECTS) $(MSIZE) -lm $(LDLFLAG) $(COVERAGELIB) -o $(BUILDDIR)/$(EECU) 
	
backend : builddirs
ifeq "$(EUPHORIA)" "1"
	$(MAKE) backendsource EBACKEND=1 OBJDIR=backobj CONFIG=$(CONFIG)  EDEBUG=$(EDEBUG) EPROFILE=$(EPROFILE)
endif	
	$(MAKE) $(BUILDDIR)/$(EBACKENDC) EBACKEND=1 OBJDIR=backobj CONFIG=$(CONFIG) EDEBUG=$(EDEBUG) EPROFILE=$(EPROFILE)
ifeq "$(EMINGW)" "1"
	$(MAKE) $(BUILDDIR)/$(EBACKENDW) EBACKEND=1 OBJDIR=backobj CONFIG=$(CONFIG) EDEBUG=$(EDEBUG) EPROFILE=$(EPROFILE)
endif

ifeq "$(EMINGW)" "1"
$(EUB_RES) :  $(TRUNKDIR)/source/eub.rc  $(TRUNKDIR)/source/version_info.rc  $(TRUNKDIR)/source/eu.manifest
$(EUBW_RES) :  $(TRUNKDIR)/source/eubw.rc  $(TRUNKDIR)/source/version_info.rc  $(TRUNKDIR)/source/eu.manifest
endif

$(BUILDDIR)/$(EBACKENDC) $(BUILDDIR)/$(EBACKENDW) : OBJDIR = backobj
$(BUILDDIR)/$(EBACKENDC) $(BUILDDIR)/$(EBACKENDW) : EU_TARGET = backend.ex
$(BUILDDIR)/$(EBACKENDC) $(BUILDDIR)/$(EBACKENDW) : EU_MAIN = $(EU_BACKEND_RUNNER_FILES)
$(BUILDDIR)/$(EBACKENDC) $(BUILDDIR)/$(EBACKENDW) : EU_OBJS = $(EU_BACKEND_RUNNER_OBJECTS) $(EU_BACKEND_OBJECTS)
$(BUILDDIR)/$(EBACKENDC) $(BUILDDIR)/$(EBACKENDW) : $(EU_BACKEND_RUNNER_OBJECTS) $(EU_BACKEND_OBJECTS) $(EUB_RES) $(EUBW_RES)
	@$(ECHO) making $(EBACKENDC) $(OBJDIR)
	$(CC) $(EOSFLAGS) $(EUB_RES) $(EU_BACKEND_RUNNER_OBJECTS) $(EU_BACKEND_OBJECTS) -lm $(LDLFLAG) $(COVERAGELIB) $(DEBUG_FLAGS) $(MSIZE) $(PROFILE_FLAGS) -o $(BUILDDIR)/$(EBACKENDC)
ifeq "$(EMINGW)" "1"
	$(CC) $(EOSFLAGS) $(EUBW_RES) $(EU_BACKEND_RUNNER_OBJECTS) $(EU_BACKEND_OBJECTS) -lm $(LDLFLAG) $(COVERAGELIB) $(DEBUG_FLAGS) $(MSIZE) $(PROFILE_FLAGS) -o $(BUILDDIR)/$(EBACKENDW)
endif

ifeq "$(HG)" ""
HG=hg
endif

.PHONY: update-version-cache
update-version-cache : $(MKVER) $(BUILD_DIRS)
	cd $(TRUNKDIR) && $(MKVER) "$(HG)" "$(BUILDDIR)/ver.cache" "$(BUILDDIR)/include/be_ver.h" "$(EREL_TYPE)$(RELEASE)"

$(MKVER): $(TRUNKDIR)/source/mkver.c
	$(HOSTCC) -o $@ $<


$(BUILDDIR)/ver.cache : update-version-cache

$(BUILDDIR)/include/be_ver.h:  $(BUILDDIR)/ver.cache $(BUILD_DIRS)

###############################################################################
#
# Documentation
#
###############################################################################

get-eudoc: $(TRUNKDIR)/source/eudoc/eudoc.ex
get-creole: $(TRUNKDIR)/source/creole/creole.ex

$(TRUNKDIR)/source/eudoc/eudoc.ex :
	hg clone http://scm.openeuphoria.org/hg/eudoc $(TRUNKDIR)/source/eudoc

$(TRUNKDIR)/source/creole/creole.ex :
	hg clone http://scm.openeuphoria.org/hg/creole $(TRUNKDIR)/source/creole

$(BUILDDIR)/euphoria.txt : $(EU_DOC_SOURCE)
	cd $(TRUNKDIR)/docs && $(EUDOC) -d HTML --strip=2 --verbose -a manual.af -o $(CYPBUILDDIR)/euphoria.txt

$(BUILDDIR)/docs/index.html : $(BUILDDIR)/euphoria.txt $(DOCDIR)/*.txt $(TRUNKDIR)/include/std/*.e
	-mkdir -p $(BUILDDIR)/docs/images
	-mkdir -p $(BUILDDIR)/docs/js
	cd $(CYPTRUNKDIR)/docs && $(CREOLE) -A -d=$(CYPTRUNKDIR)/docs/ -t=template.html -o=$(CYPBUILDDIR)/docs $(CYPBUILDDIR)/euphoria.txt
	cp $(DOCDIR)/html/images/* $(BUILDDIR)/docs/images
	cp $(DOCDIR)/style.css $(BUILDDIR)/docs

manual : $(BUILDDIR)/docs/index.html

manual-send : manual
	$(SCP) $(TRUNKDIR)/docs/style.css $(BUILDDIR)/docs/*.html $(oe_username)@openeuphoria.org:/home/euweb/docs

manual-reindex:
	$(SSH) $(oe_username)@openeuphoria.org "cd /home/euweb/prod/euweb/source/ && sh reindex_manual.sh"

manual-upload: manual-send manual-reindex

$(BUILDDIR)/html/index.html : $(BUILDDIR)/euphoria.txt $(DOCDIR)/offline-template.html
	-mkdir -p $(BUILDDIR)/html/images
	-mkdir -p $(BUILDDIR)/html/js
	cd $(CYPTRUNKDIR)/docs && $(CREOLE) -A -d=$(CYPTRUNKDIR)/docs/ -t=offline-template.html -o=$(CYPBUILDDIR)/html $(CYPBUILDDIR)/euphoria.txt
	cp $(DOCDIR)/*js $(BUILDDIR)/html/js
	cp $(DOCDIR)/html/images/* $(BUILDDIR)/html/images
	cp $(DOCDIR)/style.css $(BUILDDIR)/html

$(BUILDDIR)/html/js/scriptaculous.js: $(DOCDIR)/scriptaculous.js  $(BUILDDIR)/html/js
	copy $(DOCDIR)/scriptaculous.js $^@

$(BUILDDIR)/html/js/prototype.js: $(DOCDIR)/prototype.js  $(BUILDDIR)/html/js
	copy $(DOCDIR)/prototype.js $^@

htmldoc : $(BUILDDIR)/html/index.html
	echo $(EU_STD_INC)
#
# PDF manual
#

pdfdoc : $(BUILDDIR)/euphoria.pdf

$(BUILDDIR)/pdf/euphoria.txt : $(EU_DOC_SOURCE)
	-mkdir -p $(BUILDDIR)/pdf
	$(EUDOC) -d PDF --single --strip=2 -a $(TRUNKDIR)/docs/manual.af -o $(BUILDDIR)/pdf/euphoria.txt

$(BUILDDIR)/pdf/euphoria.tex : $(BUILDDIR)/pdf/euphoria.txt $(TRUNKDIR)/docs/template.tex
	cd $(TRUNKDIR)/docs && $(CREOLE) -f latex -A -t=$(TRUNKDIR)/docs/template.tex -o=$(BUILDDIR)/pdf $<

$(BUILDDIR)/euphoria.pdf : $(BUILDDIR)/pdf/euphoria.tex
	cd $(TRUNKDIR)/docs && pdflatex -output-directory=$(BUILDDIR)/pdf $(BUILDDIR)/pdf/euphoria.tex && pdflatex -output-directory=$(BUILDDIR)/pdf $(BUILDDIR)/pdf/euphoria.tex && cp $(BUILDDIR)/pdf/euphoria.pdf $(BUILDDIR)/
	
pdfdoc-initial : $(BUILDDIR)/euphoria.pdf
	cd $(TRUNKDIR)/docs && pdflatex -output-directory=$(BUILDDIR)/pdf $(BUILDDIR)/pdf/euphoria.tex && cp $(BUILDDIR)/pdf/euphoria.pdf $(BUILDDIR)/

.PHONY : pdfdoc-initial pdfdoc

###############################################################################
#
# Testing Targets
#
###############################################################################

#
# Test <eucode>...</eucode> blocks found in our API reference docs
#

.PHONY: test-eucode

test-eucode : 
	$(EUDOC) --single --verbose --test-eucode --work-dir=$(BUILDDIR)/eudoc_test -o $(BUILDDIR)/test_eucode.txt $(EU_STD_INC)
	$(CREOLE) -o $(BUILDDIR) $(BUILDDIR)/test_eucode.txt

#
# Unit Testing
#

test : EUDIR=$(TRUNKDIR)
test : EUCOMPILEDIR=$(TRUNKDIR)
test : EUCOMPILEDIR=$(TRUNKDIR)	
test : C_INCLUDE_PATH=$(TRUNKDIR):..:$(C_INCLUDE_PATH)
test : LIBRARY_PATH=$(%LIBRARY_PATH)
test : $(TRUNKDIR)/tests/lib818.dll
test :  
	cd $(TRUNKDIR)/tests && EUDIR=$(CYPTRUNKDIR) EUCOMPILEDIR=$(CYPTRUNKDIR) \
		$(EXE) -i $(TRUNKDIR)/include $(TRUNKDIR)/source/eutest.ex -i $(TRUNKDIR)/include -cc gcc $(VERBOSE_TESTS) \
		-exe "$(CYPBUILDDIR)/$(EEXU)" \
		-ec "$(CYPBUILDDIR)/$(EECU)" \
		-eubind "$(CYPBUILDDIR)/$(EUBIND)" -eub $(CYPBUILDDIR)/$(EBACKENDC) \
		-lib "$(CYPBUILDDIR)/$(LIBRARY_NAME)" \
		-log $(TESTFILE) ; \
	$(EXE) -i $(TRUNKDIR)/include $(TRUNKDIR)/source/eutest.ex -exe "$(CYPBUILDDIR)/$(EEXU)" -process-log > $(CYPBUILDDIR)/test-report.txt ; \
	$(EXE) -i $(TRUNKDIR)/include $(TRUNKDIR)/source/eutest.ex -eui "$(CYPBUILDDIR)/$(EEXU)" -process-log -html > $(CYPBUILDDIR)/test-report.html
	cd $(TRUNKDIR)/tests && sh check_diffs.sh

testeu : $(TRUNKDIR)/tests/lib818.dll
testeu :
	cd $(TRUNKDIR)/tests && EUDIR=$(CYPTRUNKDIR) EUCOMPILEDIR=$(CYPTRUNKDIR) $(EXE) $(TRUNKDIR)/source/eutest.ex --nocheck -i $(TRUNKDIR)/include -cc gcc -exe "$(CYPBUILDDIR)/$(EEXU) -batch $(CYPTRUNKDIR)/source/eu.ex" $(TESTFILE)

test-311 :
	cd $(TRUNKDIR)/tests/311 && EUDIR=$(CYPTRUNKDIR) EUCOMPILEDIR=$(CYPTRUNKDIR) \
		$(EXE) -i $(TRUNKDIR)/include $(CYPTRUNKDIR)/source/eutest.ex -i $(CYPTRUNKDIR)/include -cc gcc $(VERBOSE_TESTS) \
		-exe "$(CYPBUILDDIR)/$(EEXU)" \
		-ec "$(CYPBUILDDIR)/$(EECU)" \
		-eubind $(CYPBUILDDIR)/$(EUBIND) -eub $(CYPBUILDDIR)/$(EBACKENDC) \
		-lib "$(CYPBUILDDIR)/$(LIBRARY_NAME)" \
		$(TESTFILE)
		
coverage-311 : 
	cd $(TRUNKDIR)/tests/311 && EUDIR=$(CYPTRUNKDIR) EUCOMPILEDIR=$(CYPTRUNKDIR) \
		$(EXE) -i $(TRUNKDIR)/include $(CYPTRUNKDIR)/source/eutest.ex -i $(CYPTRUNKDIR)/include \
		-exe "$(CYPBUILDDIR)/$(EEXU)" $(COVERAGE_ERASE) \
		-coverage-db $(CYPBUILDDIR)/unit-test-311.edb -coverage $(CYPTRUNKDIR)/include \
		-coverage-exclude std -coverage-exclude euphoria \
		 -coverage-pp "$(EXE) -i $(CYPTRUNKDIR)/include $(CYPTRUNKDIR)/bin/eucoverage.ex" $(TESTFILE)

coverage :  $(TRUNKDIR)/tests/lib818.dll
coverage :
	cd $(TRUNKDIR)/tests && EUDIR=$(CYPTRUNKDIR) EUCOMPILEDIR=$(CYPTRUNKDIR) \
		$(EXE) -i $(TRUNKDIR)/include $(CYPTRUNKDIR)/source/eutest.ex -i $(CYPTRUNKDIR)/include \
		-exe "$(CYPBUILDDIR)/$(EEXU)" $(COVERAGE_ERASE) \
		-coverage-db $(CYPBUILDDIR)/unit-test.edb -coverage $(CYPTRUNKDIR)/include/std \
		-verbose \
		 -coverage-pp "$(EXE) -i $(CYPTRUNKDIR)/include $(CYPTRUNKDIR)/bin/eucoverage.ex" $(TESTFILE)

coverage-front-end :  $(TRUNKDIR)/tests/lib818.dll
coverage-front-end :
	-rm $(CYPBUILDDIR)/front-end.edb
	cd $(TRUNKDIR)/tests && EUDIR=$(CYPTRUNKDIR) EUCOMPILEDIR=$(CYPTRUNKDIR) \
		$(EXE) -i $(TRUNKDIR)/include $(CYPTRUNKDIR)/source/eutest.ex -i $(CYPTRUNKDIR)/include \
		-exe "$(CYPBUILDDIR)/$(EEXU) -coverage-db $(CYPBUILDDIR)/front-end.edb -coverage $(CYPTRUNKDIR)/source $(CYPTRUNKDIR)/source/eu.ex" \
		-verbose $(TESTFILE)
	eucoverage $(CYPBUILDDIR)/front-end.edb

.PHONY : coverage

ifeq "$(PREFIX)" ""
PREFIX=/usr/local
endif

install :
	mkdir -p $(DESTDIR)$(PREFIX)/share/euphoria/include/euphoria
	mkdir -p $(DESTDIR)$(PREFIX)/share/euphoria/include/euphoria/debug
	mkdir -p $(DESTDIR)$(PREFIX)/share/euphoria/include/std/win32
	mkdir -p $(DESTDIR)$(PREFIX)/share/euphoria/include/std/net
	mkdir -p $(DESTDIR)$(PREFIX)/share/euphoria/demo/langwar
	mkdir -p $(DESTDIR)$(PREFIX)/share/euphoria/demo/unix
	mkdir -p $(DESTDIR)$(PREFIX)/share/euphoria/demo/net
	mkdir -p $(DESTDIR)$(PREFIX)/share/euphoria/demo/preproc
	mkdir -p $(DESTDIR)$(PREFIX)/share/euphoria/demo/win32
	mkdir -p $(DESTDIR)$(PREFIX)/share/euphoria/demo/bench
	mkdir -p $(DESTDIR)$(PREFIX)/share/euphoria/tutorial 
	mkdir -p $(DESTDIR)$(PREFIX)/share/euphoria/bin 
	mkdir -p $(DESTDIR)$(PREFIX)/share/euphoria/source 
	mkdir -p $(DESTDIR)$(PREFIX)/bin 
	mkdir -p $(DESTDIR)$(PREFIX)/lib
	install $(BUILDDIR)/$(EECUA) $(DESTDIR)$(PREFIX)/lib
	install $(BUILDDIR)/$(EECUDBGA) $(DESTDIR)$(PREFIX)/lib
ifneq "$(EMINGW)" "1"
	install $(BUILDDIR)/$(EECUSOA) $(DESTDIR)$(PREFIX)/lib
	install $(BUILDDIR)/$(EECUSODBGA) $(DESTDIR)$(PREFIX)/lib
endif
	install $(BUILDDIR)/$(EEXU) $(DESTDIR)$(PREFIX)/bin
	install $(BUILDDIR)/$(EECU) $(DESTDIR)$(PREFIX)/bin
	install $(BUILDDIR)/$(EBACKENDC) $(DESTDIR)$(PREFIX)/bin
	install $(BUILDDIR)/$(EUBIND) $(DESTDIR)$(PREFIX)/bin
	install $(BUILDDIR)/$(EUSHROUD) $(DESTDIR)$(PREFIX)/bin
	install $(BUILDDIR)/$(EUTEST) $(DESTDIR)$(PREFIX)/bin
	install $(BUILDDIR)/$(EUDIS) $(DESTDIR)$(PREFIX)/bin
	install $(BUILDDIR)/$(EUDIST) $(DESTDIR)$(PREFIX)/bin
	install $(BUILDDIR)/$(EUCOVERAGE) $(DESTDIR)$(PREFIX)/bin
	install -m 755 $(TRUNKDIR)/bin/*.ex $(DESTDIR)$(PREFIX)/bin
	install -m 755 $(TRUNKDIR)/bin/ecp.dat $(DESTDIR)$(PREFIX)/bin
ifeq "$(EMINGW)" "1"
	install $(BUILDDIR)/$(EBACKENDW) $(DESTDIR)$(PREFIX)/bin
endif
	install $(TRUNKDIR)/include/*e  $(DESTDIR)$(PREFIX)/share/euphoria/include
	install $(TRUNKDIR)/include/std/*e  $(DESTDIR)$(PREFIX)/share/euphoria/include/std
	install $(TRUNKDIR)/include/std/net/*e  $(DESTDIR)$(PREFIX)/share/euphoria/include/std/net
	install $(TRUNKDIR)/include/std/win32/*e  $(DESTDIR)$(PREFIX)/share/euphoria/include/std/win32
	install $(TRUNKDIR)/include/euphoria/*.e  $(DESTDIR)$(PREFIX)/share/euphoria/include/euphoria
	install $(TRUNKDIR)/include/euphoria/debug/*.e  $(DESTDIR)$(PREFIX)/share/euphoria/include/euphoria/debug
	install $(TRUNKDIR)/include/euphoria.h $(DESTDIR)$(PREFIX)/share/euphoria/include
	install $(TRUNKDIR)/demo/*.e* $(DESTDIR)$(PREFIX)/share/euphoria/demo
	install $(TRUNKDIR)/demo/bench/* $(DESTDIR)$(PREFIX)/share/euphoria/demo/bench
	install $(TRUNKDIR)/demo/langwar/* $(DESTDIR)$(PREFIX)/share/euphoria/demo/langwar
	install $(TRUNKDIR)/demo/unix/* $(DESTDIR)$(PREFIX)/share/euphoria/demo/unix
	install $(TRUNKDIR)/demo/net/* $(DESTDIR)$(PREFIX)/share/euphoria/demo/net
	install $(TRUNKDIR)/demo/preproc/* $(DESTDIR)$(PREFIX)/share/euphoria/demo/preproc
	install $(TRUNKDIR)/tutorial/* $(DESTDIR)$(PREFIX)/share/euphoria/tutorial
	install  \
	           $(TRUNKDIR)/bin/edx.ex \
	           $(TRUNKDIR)/bin/bugreport.ex \
	           $(TRUNKDIR)/bin/buildcpdb.ex \
	           $(TRUNKDIR)/bin/ecp.dat \
	           $(TRUNKDIR)/bin/eucoverage.ex \
	           $(TRUNKDIR)/bin/euloc.ex \
	           $(DESTDIR)$(PREFIX)/share/euphoria/bin
	install  \
	           $(TRUNKDIR)/source/*.ex \
	           $(TRUNKDIR)/source/*.e \
	           $(TRUNKDIR)/source/be_*.c \
                   $(TRUNKDIR)/source/*.h \
	           $(DESTDIR)$(PREFIX)/share/euphoria/source

EUDIS=eudis
EUTEST=eutest
EUCOVERAGE=eucoverage
EUDIST=eudist

ifeq "$(EMINGW)" "1"
	MINGW_FLAGS=-gcc
else
	MINGW_FLAGS=
endif

ifeq "$(ARCH)" "ARM"
	EUC_CFLAGS=-cflags "-fomit-frame-pointer -c -w -fsigned-char -O2 -I$(TRUNKDIR) -ffast-math"
	EUC_LFLAGS=-lflags "$(BUILDDIR)/eu.a -ldl -lm -lpthread"
else
	EUC_CFLAGS=-cflags "$(FE_FLAGS)"
	EUC_LFLAGS=
endif

$(BUILDDIR)/eudist-build/main-.c : $(TRUNKDIR)/source/eudist.ex
	$(TRANSLATE) -build-dir "$(BUILDDIR)/eudist-build" \
		-c "$(BUILDDIR)/eu.cfg" \
		-o "$(BUILDDIR)/$(EUDIST)" \
		-lib "$(BUILDDIR)/eu.a" \
		-makefile -eudir $(TRUNKDIR) $(EUC_CFLAGS) $(EUC_LFLAGS) \
		$(MINGW_FLAGS) $(TRUNKDIR)/source/eudist.ex

$(BUILDDIR)/$(EUDIST) : $(TRUNKDIR)/source/eudist.ex translator library $(BUILDDIR)/eudist-build/main-.c
		$(MAKE) -C "$(BUILDDIR)/eudist-build" -f eudist.mak

$(BUILDDIR)/eudis-build/main-.c : $(TRUNKDIR)/source/dis.ex  $(TRUNKDIR)/source/dis.e $(TRUNKDIR)/source/dox.e
$(BUILDDIR)/eudis-build/main-.c : $(EU_CORE_FILES) 
$(BUILDDIR)/eudis-build/main-.c : $(EU_INTERPRETER_FILES) 
	$(TRANSLATE) -build-dir "$(BUILDDIR)/eudis-build" \
		-c "$(BUILDDIR)/eu.cfg" \
		-o "$(BUILDDIR)/$(EUDIS)" \
		-lib "$(BUILDDIR)/eu.a" \
		-makefile -eudir $(TRUNKDIR) $(EUC_CFLAGS) $(EUC_LFLAGS) \
		$(MINGW_FLAGS) $(TRUNKDIR)/source/dis.ex

$(BUILDDIR)/$(EUDIS) : translator library $(BUILDDIR)/eudis-build/main-.c
		$(MAKE) -C "$(BUILDDIR)/eudis-build" -f dis.mak

$(BUILDDIR)/bind-build/main-.c : $(TRUNKDIR)/source/eubind.ex $(EU_INTERPRETER_FILES) $(EU_BACKEND_RUNNER_FILES) $(EU_CORE_FILES)
	$(TRANSLATE) -build-dir "$(BUILDDIR)/bind-build" \
		-c "$(BUILDDIR)/eu.cfg" \
		-o "$(BUILDDIR)/$(EUBIND)" \
		-lib "$(BUILDDIR)/eu.a" \
		-makefile -eudir $(TRUNKDIR) $(EUC_CFLAGS) $(EUC_LFLAGS) \
		$(MINGW_FLAGS) $(TRUNKDIR)/source/eubind.ex

$(BUILDDIR)/$(EUBIND) : $(BUILDDIR)/bind-build/main-.c
		$(MAKE) -C "$(BUILDDIR)/bind-build" -f eubind.mak

$(BUILDDIR)/shroud-build/main-.c : $(TRUNKDIR)/source/eushroud.ex  $(EU_INTERPRETER_FILES) $(EU_BACKEND_RUNNER_FILES) $(EU_CORE_FILES)
	$(TRANSLATE) -build-dir "$(BUILDDIR)/shroud-build" \
		-c "$(BUILDDIR)/eu.cfg" \
		-o "$(BUILDDIR)/$(EUSHROUD)" \
		-lib "$(BUILDDIR)/eu.a" \
		-makefile -eudir $(TRUNKDIR) $(EUC_CFLAGS) $(EUC_LFLAGS) \
		$(MINGW_FLAGS) $(TRUNKDIR)/source/eushroud.ex

$(BUILDDIR)/$(EUSHROUD) : $(BUILDDIR)/shroud-build/main-.c
		$(MAKE) -C "$(BUILDDIR)/shroud-build" -f eushroud.mak

$(BUILDDIR)/eutest-build/main-.c : $(TRUNKDIR)/source/eutest.ex
	$(TRANSLATE) -build-dir "$(BUILDDIR)/eutest-build" \
		-c "$(BUILDDIR)/eu.cfg" \
		-o "$(BUILDDIR)/$(EUTEST)" \
		-lib "$(BUILDDIR)/eu.a" \
		-makefile -eudir $(TRUNKDIR) $(EUC_CFLAGS) $(EUC_LFLAGS) \
		$(MINGW_FLAGS) $(TRUNKDIR)/source/eutest.ex

$(BUILDDIR)/$(EUTEST) : $(BUILDDIR)/eutest-build/main-.c
		$(MAKE) -C "$(BUILDDIR)/eutest-build" -f eutest.mak

$(BUILDDIR)/eucoverage-build/main-.c : $(TRUNKDIR)/bin/eucoverage.ex
	$(TRANSLATE) -build-dir "$(BUILDDIR)/eucoverage-build" \
		-c "$(BUILDDIR)/eu.cfg" \
		-o "$(BUILDDIR)/$(EUCOVERAGE)" \
		-lib "$(BUILDDIR)/eu.a" \
		-makefile -eudir $(TRUNKDIR) $(EUC_CFLAGS) $(EUC_LFLAGS) \
		$(MINGW_FLAGS) $(TRUNKDIR)/bin/eucoverage.ex

$(BUILDDIR)/$(EUCOVERAGE) : $(BUILDDIR)/eucoverage-build/main-.c
		$(MAKE) -C "$(BUILDDIR)/eucoverage-build" -f eucoverage.mak

EU_TOOLS= $(BUILDDIR)/$(EUDIST) \
	$(BUILDDIR)/$(EUDIS) \
	$(BUILDDIR)/$(EUTEST) \
	$(BUILDDIR)/$(EUBIND) \
	$(BUILDDIR)/$(EUSHROUD) \
	$(BUILDDIR)/$(EUCOVERAGE)

tools : $(EU_TOOLS)

clean-tools :
	-rm $(EU_TOOLS)

install-tools :
	install $(BUILDDIR)/$(EUDIST) $(DESTDIR)$(PREFIX)/bin/
	install $(BUILDDIR)/$(EUDIS) $(DESTDIR)$(PREFIX)/bin/
	install $(BUILDDIR)/$(EUTEST) $(DESTDIR)$(PREFIX)/bin/
	install $(BUILDDIR)/$(EUCOVERAGE) $(DESTDIR)$(PREFIX)/bin/

install-docs :
	# create dirs
	install -d $(DESTDIR)$(PREFIX)/share/doc/euphoria/html/js
	install -d $(DESTDIR)$(PREFIX)/share/doc/euphoria/html/images
	install $(BUILDDIR)/euphoria.pdf $(DESTDIR)$(PREFIX)/share/doc/euphoria/
	install  \
		$(BUILDDIR)/html/*html \
		$(BUILDDIR)/html/*css \
		$(BUILDDIR)/html/search.dat \
		$(DESTDIR)$(PREFIX)/share/doc/euphoria/html
	install  \
		$(BUILDDIR)/html/images/* \
		$(DESTDIR)$(PREFIX)/share/doc/euphoria/html/images
	install  \
		$(BUILDDIR)/html/js/* \
		$(DESTDIR)$(PREFIX)/share/doc/euphoria/html/js

		
# This doesn't seem right. What about eushroud ?
uninstall :
	-rm $(PREFIX)/bin/$(EEXU) $(PREFIX)/bin/$(EECU) $(PREFIX)/lib/$(EECUA) $(PREFIX)/lib/$(EECUDBGA) $(PREFIX)/bin/$(EBACKENDC)
ifeq "$(EMINGW)" "1"
	-rm $(PREFIX)/lib/$(EBACKENDW)
endif
	-rm -r $(PREFIX)/share/euphoria

uninstall-docs :
	-rm -rf $(PREFIX)/share/doc/euphoria

.PHONY : install install-docs install-tools
.PHONY : uninstall uninstall-docs

ifeq "$(EUPHORIA)" "1"
$(BUILDDIR)/intobj/main-.c : $(EU_CORE_FILES) $(EU_INTERPRETER_FILES) $(EU_TRANSLATOR_FILES) $(EU_STD_INC)
$(BUILDDIR)/transobj/main-.c : $(EU_CORE_FILES) $(EU_TRANSLATOR_FILES) $(EU_STD_INC)
$(BUILDDIR)/backobj/main-.c : $(EU_CORE_FILES) $(EU_BACKEND_RUNNER_FILES) $(EU_TRANSLATOR_FILES) $(EU_STD_INC)
endif

%obj :
	mkdir -p $@

%back : %
	mkdir -p $@

$(BUILDDIR)/%.res : $(TRUNKDIR)/source/%.rc
	$(RC) $< -O coff -o $@
	
$(BUILDDIR)/$(OBJDIR)/%.o : $(BUILDDIR)/$(OBJDIR)/%.c
	$(CC) $(EBSDFLAG) $(FE_FLAGS) $(BUILDDIR)/$(OBJDIR)/$*.c -I/usr/share/euphoria -o$(BUILDDIR)/$(OBJDIR)/$*.o

ifneq "$(ARCH)" "ARM"
LIB818_FPIC=-fPIC
endif

$(BUILDDIR)/test818.o : test818.c
	$(CC) -c $(LIB818_FPIC) -I $(TRUNKDIR)/include $(FE_FLAGS) -Wall -shared $(TRUNKDIR)/source/test818.c -o $(BUILDDIR)/test818.o

lib818 :
	touch test818.c
	$(MAKE) $(TRUNKDIR)/tests/lib818.dll

$(TRUNKDIR)/tests/lib818.dll : $(BUILDDIR)/test818.o
	$(CC)  $(MSIZE) $(LIB818_FPIC) -shared -o $(TRUNKDIR)/tests/lib818.dll $(CREATEDLLFLAGS) $(BUILDDIR)/test818.o

ifeq "$(EUPHORIA)" "1"

$(BUILDDIR)/$(OBJDIR)/%.c : $(EU_MAIN)
	@$(ECHO) Translating $(EU_TARGET) to create $(EU_MAIN)
	rm -f $(BUILDDIR)/$(OBJDIR)/{*.c,*.o}
	(cd $(BUILDDIR)/$(OBJDIR);$(TRANSLATE) -nobuild $(CYPINCDIR) -$(XLTTARGETCC) $(RELEASE_FLAG) $(TARGETPLAT)  \
		-arch $(ARCH) -c "$(BUILDDIR)/eu.cfg" \
		-c $(CYPTRUNKDIR)/source/eu.cfg $(CYPTRUNKDIR)/source/$(EU_TARGET) )
	
endif

ifneq "$(OBJDIR)" ""
$(BUILDDIR)/$(OBJDIR)/back/%.o : $(TRUNKDIR)/source/%.c $(CONFIG_FILE)
	$(CC) $(BE_FLAGS) $(EBSDFLAG) -I $(BUILDDIR)/$(OBJDIR)/back -I $(BUILDDIR)/include $(TRUNKDIR)/source/$*.c -o$(BUILDDIR)/$(OBJDIR)/back/$*.o

$(BUILDDIR)/$(OBJDIR)/back/be_callc.o : $(TRUNKDIR)/source/$(BE_CALLC).c $(CONFIG_FILE)
	$(CC) -c -Wall $(EOSTYPE) $(ARCH_FLAG) $(FPIC) $(EOSFLAGS) $(EBSDFLAG) $(MSIZE) -DARCH=$(ARCH) -fsigned-char -O3 -fno-omit-frame-pointer -ffast-math -fno-defer-pop $(CALLC_DEBUG) $(TRUNKDIR)/source/$(BE_CALLC).c -o$(BUILDDIR)/$(OBJDIR)/back/be_callc.o

$(BUILDDIR)/$(OBJDIR)/back/be_inline.o : $(TRUNKDIR)/source/be_inline.c $(CONFIG_FILE)
	$(CC) -finline-functions $(BE_FLAGS) $(EBSDFLAG) $(RUNTIME_FLAGS) $(TRUNKDIR)/source/be_inline.c -o$(BUILDDIR)/$(OBJDIR)/back/be_inline.o
endif
ifdef PCRE_OBJECTS	
$(PREFIXED_PCRE_OBJECTS) : $(patsubst %.o,$(TRUNKDIR)/source/pcre/%.c,$(PCRE_OBJECTS)) $(TRUNKDIR)/source/pcre/config.h.unix $(TRUNKDIR)/source/pcre/pcre.h.unix
	$(MAKE) -C $(TRUNKDIR)/source/pcre all CC="$(PCRE_CC)" PCRE_CC="$(PCRE_CC)" EOSTYPE="$(EOSTYPE)" EOSFLAGS="$(EOSPCREFLAGS)" FPIC=$(FPIC)
endif

.IGNORE : test

depend :
	cd $(TRUNKDIR)/source && ./depend.sh
	
# The dependencies below are automatically generated using the depend target above.
# DO NOT DELETE


$(BUILDDIR)/intobj/back/be_alloc.o: $(TRUNKDIR)/source/alldefs.h $(TRUNKDIR)/source/global.h $(TRUNKDIR)/source/object.h $(TRUNKDIR)/source/symtab.h
$(BUILDDIR)/intobj/back/be_alloc.o: $(TRUNKDIR)/source/execute.h $(TRUNKDIR)/source/reswords.h $(TRUNKDIR)/source/be_runtime.h
$(BUILDDIR)/intobj/back/be_alloc.o: $(TRUNKDIR)/source/be_alloc.h
$(BUILDDIR)/intobj/back/be_callc.o: $(TRUNKDIR)/source/alldefs.h $(TRUNKDIR)/source/global.h $(TRUNKDIR)/source/object.h $(TRUNKDIR)/source/symtab.h
$(BUILDDIR)/intobj/back/be_callc.o: $(TRUNKDIR)/source/execute.h $(TRUNKDIR)/source/reswords.h $(TRUNKDIR)/source/be_runtime.h
$(BUILDDIR)/intobj/back/be_callc.o: $(TRUNKDIR)/source/be_machine.h $(TRUNKDIR)/source/be_alloc.h
$(BUILDDIR)/intobj/back/be_coverage.o: $(TRUNKDIR)/source/be_coverage.h $(TRUNKDIR)/source/be_machine.h $(TRUNKDIR)/source/global.h
$(BUILDDIR)/intobj/back/be_coverage.o: $(TRUNKDIR)/source/object.h $(TRUNKDIR)/source/symtab.h $(TRUNKDIR)/source/execute.h
$(BUILDDIR)/intobj/back/be_debug.o: $(TRUNKDIR)/source/execute.h $(TRUNKDIR)/source/global.h $(TRUNKDIR)/source/object.h $(TRUNKDIR)/source/symtab.h
$(BUILDDIR)/intobj/back/be_debug.o: $(TRUNKDIR)/source/redef.h $(TRUNKDIR)/source/reswords.h $(TRUNKDIR)/source/be_alloc.h $(TRUNKDIR)/source/be_debug.h
$(BUILDDIR)/intobj/back/be_debug.o: $(TRUNKDIR)/source/be_execute.h $(TRUNKDIR)/source/be_machine.h $(TRUNKDIR)/source/be_rterror.h
$(BUILDDIR)/intobj/back/be_debug.o: $(TRUNKDIR)/source/be_runtime.h $(TRUNKDIR)/source/be_symtab.h
$(BUILDDIR)/intobj/back/be_decompress.o: $(TRUNKDIR)/source/alldefs.h $(TRUNKDIR)/source/global.h $(TRUNKDIR)/source/object.h $(TRUNKDIR)/source/symtab.h
$(BUILDDIR)/intobj/back/be_decompress.o: $(TRUNKDIR)/source/execute.h $(TRUNKDIR)/source/reswords.h $(TRUNKDIR)/source/be_alloc.h
$(BUILDDIR)/intobj/back/be_decompress.o: $(TRUNKDIR)/source/be_runtime.h
$(BUILDDIR)/intobj/back/be_execute.o: $(TRUNKDIR)/source/alldefs.h $(TRUNKDIR)/source/global.h $(TRUNKDIR)/source/object.h $(TRUNKDIR)/source/symtab.h
$(BUILDDIR)/intobj/back/be_execute.o: $(TRUNKDIR)/source/execute.h $(TRUNKDIR)/source/reswords.h $(TRUNKDIR)/source/be_alloc.h
$(BUILDDIR)/intobj/back/be_execute.o: $(TRUNKDIR)/source/be_runtime.h $(TRUNKDIR)/source/be_decompress.h
$(BUILDDIR)/intobj/back/be_execute.o: $(TRUNKDIR)/source/be_inline.h $(TRUNKDIR)/source/be_machine.h $(TRUNKDIR)/source/be_task.h
$(BUILDDIR)/intobj/back/be_execute.o: $(TRUNKDIR)/source/be_rterror.h $(TRUNKDIR)/source/be_symtab.h $(TRUNKDIR)/source/be_w.h
$(BUILDDIR)/intobj/back/be_execute.o: $(TRUNKDIR)/source/be_callc.h $(TRUNKDIR)/source/be_coverage.h $(TRUNKDIR)/source/be_execute.h
$(BUILDDIR)/intobj/back/be_execute.o: $(TRUNKDIR)/source/be_debug.h
$(BUILDDIR)/intobj/back/be_inline.o: $(TRUNKDIR)/source/alldefs.h $(TRUNKDIR)/source/global.h $(TRUNKDIR)/source/object.h $(TRUNKDIR)/source/symtab.h
$(BUILDDIR)/intobj/back/be_inline.o: $(TRUNKDIR)/source/execute.h $(TRUNKDIR)/source/reswords.h $(TRUNKDIR)/source/be_alloc.h
$(BUILDDIR)/intobj/back/be_machine.o: $(TRUNKDIR)/source/global.h $(TRUNKDIR)/source/object.h $(TRUNKDIR)/source/symtab.h $(TRUNKDIR)/source/alldefs.h
$(BUILDDIR)/intobj/back/be_machine.o: $(TRUNKDIR)/source/execute.h $(TRUNKDIR)/source/reswords.h $(TRUNKDIR)/source/version.h
$(BUILDDIR)/intobj/back/be_machine.o: $(TRUNKDIR)/source/be_runtime.h $(TRUNKDIR)/source/be_rterror.h $(TRUNKDIR)/source/be_main.h
$(BUILDDIR)/intobj/back/be_machine.o: $(TRUNKDIR)/source/be_w.h $(TRUNKDIR)/source/be_symtab.h $(TRUNKDIR)/source/be_machine.h
$(BUILDDIR)/intobj/back/be_machine.o: $(TRUNKDIR)/source/be_pcre.h $(TRUNKDIR)/source/pcre/pcre.h $(TRUNKDIR)/source/be_task.h
$(BUILDDIR)/intobj/back/be_machine.o: $(TRUNKDIR)/source/be_alloc.h $(TRUNKDIR)/source/be_execute.h $(TRUNKDIR)/source/be_socket.h
$(BUILDDIR)/intobj/back/be_machine.o: $(TRUNKDIR)/source/be_coverage.h $(TRUNKDIR)/source/be_syncolor.h $(TRUNKDIR)/source/be_debug.h
$(BUILDDIR)/intobj/back/be_main.o: $(TRUNKDIR)/source/alldefs.h $(TRUNKDIR)/source/global.h $(TRUNKDIR)/source/object.h $(TRUNKDIR)/source/symtab.h
$(BUILDDIR)/intobj/back/be_main.o: $(TRUNKDIR)/source/execute.h $(TRUNKDIR)/source/reswords.h $(TRUNKDIR)/source/be_runtime.h
$(BUILDDIR)/intobj/back/be_main.o: $(TRUNKDIR)/source/be_execute.h $(TRUNKDIR)/source/be_alloc.h $(TRUNKDIR)/source/be_rterror.h
$(BUILDDIR)/intobj/back/be_main.o: $(TRUNKDIR)/source/be_w.h
$(BUILDDIR)/intobj/back/be_pcre.o: $(TRUNKDIR)/source/alldefs.h $(TRUNKDIR)/source/global.h $(TRUNKDIR)/source/object.h $(TRUNKDIR)/source/symtab.h
$(BUILDDIR)/intobj/back/be_pcre.o: $(TRUNKDIR)/source/execute.h $(TRUNKDIR)/source/reswords.h $(TRUNKDIR)/source/be_alloc.h
$(BUILDDIR)/intobj/back/be_pcre.o: $(TRUNKDIR)/source/be_runtime.h $(TRUNKDIR)/source/be_pcre.h $(TRUNKDIR)/source/pcre/pcre.h
$(BUILDDIR)/intobj/back/be_pcre.o: $(TRUNKDIR)/source/be_machine.h
$(BUILDDIR)/intobj/back/be_rterror.o: $(TRUNKDIR)/source/alldefs.h $(TRUNKDIR)/source/global.h $(TRUNKDIR)/source/object.h $(TRUNKDIR)/source/symtab.h
$(BUILDDIR)/intobj/back/be_rterror.o: $(TRUNKDIR)/source/execute.h $(TRUNKDIR)/source/reswords.h $(TRUNKDIR)/source/be_rterror.h
$(BUILDDIR)/intobj/back/be_rterror.o: $(TRUNKDIR)/source/be_runtime.h $(TRUNKDIR)/source/be_task.h $(TRUNKDIR)/source/be_w.h
$(BUILDDIR)/intobj/back/be_rterror.o: $(TRUNKDIR)/source/be_machine.h $(TRUNKDIR)/source/be_execute.h $(TRUNKDIR)/source/be_symtab.h
$(BUILDDIR)/intobj/back/be_rterror.o: $(TRUNKDIR)/source/be_alloc.h $(TRUNKDIR)/source/be_syncolor.h $(TRUNKDIR)/source/be_debug.h
$(BUILDDIR)/intobj/back/be_runtime.o: $(TRUNKDIR)/source/alldefs.h $(TRUNKDIR)/source/global.h $(TRUNKDIR)/source/object.h $(TRUNKDIR)/source/symtab.h
$(BUILDDIR)/intobj/back/be_runtime.o: $(TRUNKDIR)/source/execute.h $(TRUNKDIR)/source/reswords.h $(TRUNKDIR)/source/be_alloc.h
$(BUILDDIR)/intobj/back/be_runtime.o: $(TRUNKDIR)/source/be_runtime.h $(TRUNKDIR)/source/be_machine.h $(TRUNKDIR)/source/be_inline.h
$(BUILDDIR)/intobj/back/be_runtime.o: $(TRUNKDIR)/source/be_w.h $(TRUNKDIR)/source/be_callc.h $(TRUNKDIR)/source/be_task.h
$(BUILDDIR)/intobj/back/be_runtime.o: $(TRUNKDIR)/source/be_rterror.h $(TRUNKDIR)/source/be_coverage.h $(TRUNKDIR)/source/be_execute.h
$(BUILDDIR)/intobj/back/be_runtime.o: $(TRUNKDIR)/source/be_symtab.h
$(BUILDDIR)/intobj/back/be_socket.o: $(TRUNKDIR)/source/alldefs.h $(TRUNKDIR)/source/global.h $(TRUNKDIR)/source/object.h $(TRUNKDIR)/source/symtab.h
$(BUILDDIR)/intobj/back/be_socket.o: $(TRUNKDIR)/source/execute.h $(TRUNKDIR)/source/reswords.h $(TRUNKDIR)/source/be_alloc.h
$(BUILDDIR)/intobj/back/be_socket.o: $(TRUNKDIR)/source/be_machine.h $(TRUNKDIR)/source/be_runtime.h $(TRUNKDIR)/source/be_socket.h
$(BUILDDIR)/intobj/back/be_symtab.o: $(TRUNKDIR)/source/alldefs.h $(TRUNKDIR)/source/global.h $(TRUNKDIR)/source/object.h $(TRUNKDIR)/source/symtab.h
$(BUILDDIR)/intobj/back/be_symtab.o: $(TRUNKDIR)/source/execute.h $(TRUNKDIR)/source/reswords.h $(TRUNKDIR)/source/be_execute.h
$(BUILDDIR)/intobj/back/be_symtab.o: $(TRUNKDIR)/source/be_alloc.h $(TRUNKDIR)/source/be_machine.h $(TRUNKDIR)/source/be_runtime.h
$(BUILDDIR)/intobj/back/be_syncolor.o: $(TRUNKDIR)/source/be_w.h $(TRUNKDIR)/source/global.h $(TRUNKDIR)/source/object.h $(TRUNKDIR)/source/symtab.h
$(BUILDDIR)/intobj/back/be_syncolor.o: $(TRUNKDIR)/source/execute.h $(TRUNKDIR)/source/alldefs.h $(TRUNKDIR)/source/reswords.h
$(BUILDDIR)/intobj/back/be_syncolor.o: $(TRUNKDIR)/source/be_alloc.h $(TRUNKDIR)/source/be_machine.h $(TRUNKDIR)/source/be_syncolor.h
$(BUILDDIR)/intobj/back/be_task.o: $(TRUNKDIR)/source/global.h $(TRUNKDIR)/source/object.h $(TRUNKDIR)/source/symtab.h $(TRUNKDIR)/source/execute.h
$(BUILDDIR)/intobj/back/be_task.o: $(TRUNKDIR)/source/reswords.h $(TRUNKDIR)/source/be_runtime.h $(TRUNKDIR)/source/be_task.h
$(BUILDDIR)/intobj/back/be_task.o: $(TRUNKDIR)/source/be_alloc.h $(TRUNKDIR)/source/be_machine.h $(TRUNKDIR)/source/be_execute.h
$(BUILDDIR)/intobj/back/be_task.o: $(TRUNKDIR)/source/be_symtab.h $(TRUNKDIR)/source/alldefs.h
$(BUILDDIR)/intobj/back/be_w.o: $(TRUNKDIR)/source/alldefs.h $(TRUNKDIR)/source/global.h $(TRUNKDIR)/source/object.h $(TRUNKDIR)/source/symtab.h
$(BUILDDIR)/intobj/back/be_w.o: $(TRUNKDIR)/source/execute.h $(TRUNKDIR)/source/reswords.h $(TRUNKDIR)/source/be_w.h $(TRUNKDIR)/source/be_machine.h
$(BUILDDIR)/intobj/back/be_w.o: $(TRUNKDIR)/source/be_runtime.h $(TRUNKDIR)/source/be_rterror.h $(TRUNKDIR)/source/be_alloc.h
$(BUILDDIR)/intobj/back/echoversion.o: $(TRUNKDIR)/source/version.h
$(BUILDDIR)/intobj/back/rbt.o: $(TRUNKDIR)/source/rbt.h

$(BUILDDIR)/transobj/back/be_alloc.o: $(TRUNKDIR)/source/alldefs.h $(TRUNKDIR)/source/global.h $(TRUNKDIR)/source/object.h $(TRUNKDIR)/source/symtab.h
$(BUILDDIR)/transobj/back/be_alloc.o: $(TRUNKDIR)/source/execute.h $(TRUNKDIR)/source/reswords.h $(TRUNKDIR)/source/be_runtime.h
$(BUILDDIR)/transobj/back/be_alloc.o: $(TRUNKDIR)/source/be_alloc.h
$(BUILDDIR)/transobj/back/be_callc.o: $(TRUNKDIR)/source/alldefs.h $(TRUNKDIR)/source/global.h $(TRUNKDIR)/source/object.h $(TRUNKDIR)/source/symtab.h
$(BUILDDIR)/transobj/back/be_callc.o: $(TRUNKDIR)/source/execute.h $(TRUNKDIR)/source/reswords.h $(TRUNKDIR)/source/be_runtime.h
$(BUILDDIR)/transobj/back/be_callc.o: $(TRUNKDIR)/source/be_machine.h $(TRUNKDIR)/source/be_alloc.h
$(BUILDDIR)/transobj/back/be_coverage.o: $(TRUNKDIR)/source/be_coverage.h $(TRUNKDIR)/source/be_machine.h $(TRUNKDIR)/source/global.h
$(BUILDDIR)/transobj/back/be_coverage.o: $(TRUNKDIR)/source/object.h $(TRUNKDIR)/source/symtab.h $(TRUNKDIR)/source/execute.h
$(BUILDDIR)/transobj/back/be_debug.o: $(TRUNKDIR)/source/execute.h $(TRUNKDIR)/source/global.h $(TRUNKDIR)/source/object.h $(TRUNKDIR)/source/symtab.h
$(BUILDDIR)/transobj/back/be_debug.o: $(TRUNKDIR)/source/redef.h $(TRUNKDIR)/source/reswords.h $(TRUNKDIR)/source/be_alloc.h
$(BUILDDIR)/transobj/back/be_debug.o: $(TRUNKDIR)/source/be_debug.h $(TRUNKDIR)/source/be_execute.h $(TRUNKDIR)/source/be_machine.h
$(BUILDDIR)/transobj/back/be_debug.o: $(TRUNKDIR)/source/be_rterror.h $(TRUNKDIR)/source/be_runtime.h $(TRUNKDIR)/source/be_symtab.h
$(BUILDDIR)/transobj/back/be_decompress.o: $(TRUNKDIR)/source/alldefs.h $(TRUNKDIR)/source/global.h $(TRUNKDIR)/source/object.h
$(BUILDDIR)/transobj/back/be_decompress.o: $(TRUNKDIR)/source/symtab.h $(TRUNKDIR)/source/execute.h $(TRUNKDIR)/source/reswords.h
$(BUILDDIR)/transobj/back/be_decompress.o: $(TRUNKDIR)/source/be_alloc.h $(TRUNKDIR)/source/be_runtime.h
$(BUILDDIR)/transobj/back/be_execute.o: $(TRUNKDIR)/source/alldefs.h $(TRUNKDIR)/source/global.h $(TRUNKDIR)/source/object.h $(TRUNKDIR)/source/symtab.h
$(BUILDDIR)/transobj/back/be_execute.o: $(TRUNKDIR)/source/execute.h $(TRUNKDIR)/source/reswords.h $(TRUNKDIR)/source/be_alloc.h
$(BUILDDIR)/transobj/back/be_execute.o: $(TRUNKDIR)/source/be_runtime.h $(TRUNKDIR)/source/be_decompress.h
$(BUILDDIR)/transobj/back/be_execute.o: $(TRUNKDIR)/source/be_inline.h $(TRUNKDIR)/source/be_machine.h $(TRUNKDIR)/source/be_task.h
$(BUILDDIR)/transobj/back/be_execute.o: $(TRUNKDIR)/source/be_rterror.h $(TRUNKDIR)/source/be_symtab.h $(TRUNKDIR)/source/be_w.h
$(BUILDDIR)/transobj/back/be_execute.o: $(TRUNKDIR)/source/be_callc.h $(TRUNKDIR)/source/be_coverage.h $(TRUNKDIR)/source/be_execute.h
$(BUILDDIR)/transobj/back/be_execute.o: $(TRUNKDIR)/source/be_debug.h
$(BUILDDIR)/transobj/back/be_inline.o: $(TRUNKDIR)/source/alldefs.h $(TRUNKDIR)/source/global.h $(TRUNKDIR)/source/object.h $(TRUNKDIR)/source/symtab.h
$(BUILDDIR)/transobj/back/be_inline.o: $(TRUNKDIR)/source/execute.h $(TRUNKDIR)/source/reswords.h $(TRUNKDIR)/source/be_alloc.h
$(BUILDDIR)/transobj/back/be_machine.o: $(TRUNKDIR)/source/global.h $(TRUNKDIR)/source/object.h $(TRUNKDIR)/source/symtab.h $(TRUNKDIR)/source/alldefs.h
$(BUILDDIR)/transobj/back/be_machine.o: $(TRUNKDIR)/source/execute.h $(TRUNKDIR)/source/reswords.h $(TRUNKDIR)/source/version.h
$(BUILDDIR)/transobj/back/be_machine.o: $(TRUNKDIR)/source/be_runtime.h $(TRUNKDIR)/source/be_rterror.h $(TRUNKDIR)/source/be_main.h
$(BUILDDIR)/transobj/back/be_machine.o: $(TRUNKDIR)/source/be_w.h $(TRUNKDIR)/source/be_symtab.h $(TRUNKDIR)/source/be_machine.h
$(BUILDDIR)/transobj/back/be_machine.o: $(TRUNKDIR)/source/be_pcre.h $(TRUNKDIR)/source/pcre/pcre.h $(TRUNKDIR)/source/be_task.h
$(BUILDDIR)/transobj/back/be_machine.o: $(TRUNKDIR)/source/be_alloc.h $(TRUNKDIR)/source/be_execute.h $(TRUNKDIR)/source/be_socket.h
$(BUILDDIR)/transobj/back/be_machine.o: $(TRUNKDIR)/source/be_coverage.h $(TRUNKDIR)/source/be_syncolor.h
$(BUILDDIR)/transobj/back/be_machine.o: $(TRUNKDIR)/source/be_debug.h
$(BUILDDIR)/transobj/back/be_main.o: $(TRUNKDIR)/source/alldefs.h $(TRUNKDIR)/source/global.h $(TRUNKDIR)/source/object.h $(TRUNKDIR)/source/symtab.h
$(BUILDDIR)/transobj/back/be_main.o: $(TRUNKDIR)/source/execute.h $(TRUNKDIR)/source/reswords.h $(TRUNKDIR)/source/be_runtime.h
$(BUILDDIR)/transobj/back/be_main.o: $(TRUNKDIR)/source/be_execute.h $(TRUNKDIR)/source/be_alloc.h $(TRUNKDIR)/source/be_rterror.h
$(BUILDDIR)/transobj/back/be_main.o: $(TRUNKDIR)/source/be_w.h
$(BUILDDIR)/transobj/back/be_pcre.o: $(TRUNKDIR)/source/alldefs.h $(TRUNKDIR)/source/global.h $(TRUNKDIR)/source/object.h $(TRUNKDIR)/source/symtab.h
$(BUILDDIR)/transobj/back/be_pcre.o: $(TRUNKDIR)/source/execute.h $(TRUNKDIR)/source/reswords.h $(TRUNKDIR)/source/be_alloc.h
$(BUILDDIR)/transobj/back/be_pcre.o: $(TRUNKDIR)/source/be_runtime.h $(TRUNKDIR)/source/be_pcre.h $(TRUNKDIR)/source/pcre/pcre.h
$(BUILDDIR)/transobj/back/be_pcre.o: $(TRUNKDIR)/source/be_machine.h
$(BUILDDIR)/transobj/back/be_rterror.o: $(TRUNKDIR)/source/alldefs.h $(TRUNKDIR)/source/global.h $(TRUNKDIR)/source/object.h $(TRUNKDIR)/source/symtab.h
$(BUILDDIR)/transobj/back/be_rterror.o: $(TRUNKDIR)/source/execute.h $(TRUNKDIR)/source/reswords.h $(TRUNKDIR)/source/be_rterror.h
$(BUILDDIR)/transobj/back/be_rterror.o: $(TRUNKDIR)/source/be_runtime.h $(TRUNKDIR)/source/be_task.h $(TRUNKDIR)/source/be_w.h
$(BUILDDIR)/transobj/back/be_rterror.o: $(TRUNKDIR)/source/be_machine.h $(TRUNKDIR)/source/be_execute.h $(TRUNKDIR)/source/be_symtab.h
$(BUILDDIR)/transobj/back/be_rterror.o: $(TRUNKDIR)/source/be_alloc.h $(TRUNKDIR)/source/be_syncolor.h $(TRUNKDIR)/source/be_debug.h
$(BUILDDIR)/transobj/back/be_runtime.o: $(TRUNKDIR)/source/alldefs.h $(TRUNKDIR)/source/global.h $(TRUNKDIR)/source/object.h $(TRUNKDIR)/source/symtab.h
$(BUILDDIR)/transobj/back/be_runtime.o: $(TRUNKDIR)/source/execute.h $(TRUNKDIR)/source/reswords.h $(TRUNKDIR)/source/be_alloc.h
$(BUILDDIR)/transobj/back/be_runtime.o: $(TRUNKDIR)/source/be_runtime.h $(TRUNKDIR)/source/be_machine.h $(TRUNKDIR)/source/be_inline.h
$(BUILDDIR)/transobj/back/be_runtime.o: $(TRUNKDIR)/source/be_w.h $(TRUNKDIR)/source/be_callc.h $(TRUNKDIR)/source/be_task.h
$(BUILDDIR)/transobj/back/be_runtime.o: $(TRUNKDIR)/source/be_rterror.h $(TRUNKDIR)/source/be_coverage.h
$(BUILDDIR)/transobj/back/be_runtime.o: $(TRUNKDIR)/source/be_execute.h $(TRUNKDIR)/source/be_symtab.h
$(BUILDDIR)/transobj/back/be_socket.o: $(TRUNKDIR)/source/alldefs.h $(TRUNKDIR)/source/global.h $(TRUNKDIR)/source/object.h $(TRUNKDIR)/source/symtab.h
$(BUILDDIR)/transobj/back/be_socket.o: $(TRUNKDIR)/source/execute.h $(TRUNKDIR)/source/reswords.h $(TRUNKDIR)/source/be_alloc.h
$(BUILDDIR)/transobj/back/be_socket.o: $(TRUNKDIR)/source/be_machine.h $(TRUNKDIR)/source/be_runtime.h $(TRUNKDIR)/source/be_socket.h
$(BUILDDIR)/transobj/back/be_symtab.o: $(TRUNKDIR)/source/alldefs.h $(TRUNKDIR)/source/global.h $(TRUNKDIR)/source/object.h $(TRUNKDIR)/source/symtab.h
$(BUILDDIR)/transobj/back/be_symtab.o: $(TRUNKDIR)/source/execute.h $(TRUNKDIR)/source/reswords.h $(TRUNKDIR)/source/be_execute.h
$(BUILDDIR)/transobj/back/be_symtab.o: $(TRUNKDIR)/source/be_alloc.h $(TRUNKDIR)/source/be_machine.h $(TRUNKDIR)/source/be_runtime.h
$(BUILDDIR)/transobj/back/be_syncolor.o: $(TRUNKDIR)/source/be_w.h $(TRUNKDIR)/source/global.h $(TRUNKDIR)/source/object.h $(TRUNKDIR)/source/symtab.h
$(BUILDDIR)/transobj/back/be_syncolor.o: $(TRUNKDIR)/source/execute.h $(TRUNKDIR)/source/alldefs.h $(TRUNKDIR)/source/reswords.h
$(BUILDDIR)/transobj/back/be_syncolor.o: $(TRUNKDIR)/source/be_alloc.h $(TRUNKDIR)/source/be_machine.h
$(BUILDDIR)/transobj/back/be_syncolor.o: $(TRUNKDIR)/source/be_syncolor.h
$(BUILDDIR)/transobj/back/be_task.o: $(TRUNKDIR)/source/global.h $(TRUNKDIR)/source/object.h $(TRUNKDIR)/source/symtab.h $(TRUNKDIR)/source/execute.h
$(BUILDDIR)/transobj/back/be_task.o: $(TRUNKDIR)/source/reswords.h $(TRUNKDIR)/source/be_runtime.h $(TRUNKDIR)/source/be_task.h
$(BUILDDIR)/transobj/back/be_task.o: $(TRUNKDIR)/source/be_alloc.h $(TRUNKDIR)/source/be_machine.h $(TRUNKDIR)/source/be_execute.h
$(BUILDDIR)/transobj/back/be_task.o: $(TRUNKDIR)/source/be_symtab.h $(TRUNKDIR)/source/alldefs.h
$(BUILDDIR)/transobj/back/be_w.o: $(TRUNKDIR)/source/alldefs.h $(TRUNKDIR)/source/global.h $(TRUNKDIR)/source/object.h $(TRUNKDIR)/source/symtab.h
$(BUILDDIR)/transobj/back/be_w.o: $(TRUNKDIR)/source/execute.h $(TRUNKDIR)/source/reswords.h $(TRUNKDIR)/source/be_w.h $(TRUNKDIR)/source/be_machine.h
$(BUILDDIR)/transobj/back/be_w.o: $(TRUNKDIR)/source/be_runtime.h $(TRUNKDIR)/source/be_rterror.h $(TRUNKDIR)/source/be_alloc.h
$(BUILDDIR)/transobj/back/echoversion.o: $(TRUNKDIR)/source/version.h
$(BUILDDIR)/transobj/back/rbt.o: $(TRUNKDIR)/source/rbt.h

$(BUILDDIR)/backobj/back/be_alloc.o: $(TRUNKDIR)/source/alldefs.h $(TRUNKDIR)/source/global.h $(TRUNKDIR)/source/object.h $(TRUNKDIR)/source/symtab.h
$(BUILDDIR)/backobj/back/be_alloc.o: $(TRUNKDIR)/source/execute.h $(TRUNKDIR)/source/reswords.h $(TRUNKDIR)/source/be_runtime.h
$(BUILDDIR)/backobj/back/be_alloc.o: $(TRUNKDIR)/source/be_alloc.h
$(BUILDDIR)/backobj/back/be_callc.o: $(TRUNKDIR)/source/alldefs.h $(TRUNKDIR)/source/global.h $(TRUNKDIR)/source/object.h $(TRUNKDIR)/source/symtab.h
$(BUILDDIR)/backobj/back/be_callc.o: $(TRUNKDIR)/source/execute.h $(TRUNKDIR)/source/reswords.h $(TRUNKDIR)/source/be_runtime.h
$(BUILDDIR)/backobj/back/be_callc.o: $(TRUNKDIR)/source/be_machine.h $(TRUNKDIR)/source/be_alloc.h
$(BUILDDIR)/backobj/back/be_coverage.o: $(TRUNKDIR)/source/be_coverage.h $(TRUNKDIR)/source/be_machine.h $(TRUNKDIR)/source/global.h
$(BUILDDIR)/backobj/back/be_coverage.o: $(TRUNKDIR)/source/object.h $(TRUNKDIR)/source/symtab.h $(TRUNKDIR)/source/execute.h
$(BUILDDIR)/backobj/back/be_debug.o: $(TRUNKDIR)/source/execute.h $(TRUNKDIR)/source/global.h $(TRUNKDIR)/source/object.h $(TRUNKDIR)/source/symtab.h
$(BUILDDIR)/backobj/back/be_debug.o: $(TRUNKDIR)/source/redef.h $(TRUNKDIR)/source/reswords.h $(TRUNKDIR)/source/be_alloc.h $(TRUNKDIR)/source/be_debug.h
$(BUILDDIR)/backobj/back/be_debug.o: $(TRUNKDIR)/source/be_execute.h $(TRUNKDIR)/source/be_machine.h $(TRUNKDIR)/source/be_rterror.h
$(BUILDDIR)/backobj/back/be_debug.o: $(TRUNKDIR)/source/be_runtime.h $(TRUNKDIR)/source/be_symtab.h
$(BUILDDIR)/backobj/back/be_decompress.o: $(TRUNKDIR)/source/alldefs.h $(TRUNKDIR)/source/global.h $(TRUNKDIR)/source/object.h
$(BUILDDIR)/backobj/back/be_decompress.o: $(TRUNKDIR)/source/symtab.h $(TRUNKDIR)/source/execute.h $(TRUNKDIR)/source/reswords.h
$(BUILDDIR)/backobj/back/be_decompress.o: $(TRUNKDIR)/source/be_alloc.h $(TRUNKDIR)/source/be_runtime.h
$(BUILDDIR)/backobj/back/be_execute.o: $(TRUNKDIR)/source/alldefs.h $(TRUNKDIR)/source/global.h $(TRUNKDIR)/source/object.h $(TRUNKDIR)/source/symtab.h
$(BUILDDIR)/backobj/back/be_execute.o: $(TRUNKDIR)/source/execute.h $(TRUNKDIR)/source/reswords.h $(TRUNKDIR)/source/be_alloc.h
$(BUILDDIR)/backobj/back/be_execute.o: $(TRUNKDIR)/source/be_runtime.h $(TRUNKDIR)/source/be_decompress.h
$(BUILDDIR)/backobj/back/be_execute.o: $(TRUNKDIR)/source/be_inline.h $(TRUNKDIR)/source/be_machine.h $(TRUNKDIR)/source/be_task.h
$(BUILDDIR)/backobj/back/be_execute.o: $(TRUNKDIR)/source/be_rterror.h $(TRUNKDIR)/source/be_symtab.h $(TRUNKDIR)/source/be_w.h
$(BUILDDIR)/backobj/back/be_execute.o: $(TRUNKDIR)/source/be_callc.h $(TRUNKDIR)/source/be_coverage.h $(TRUNKDIR)/source/be_execute.h
$(BUILDDIR)/backobj/back/be_execute.o: $(TRUNKDIR)/source/be_debug.h
$(BUILDDIR)/backobj/back/be_inline.o: $(TRUNKDIR)/source/alldefs.h $(TRUNKDIR)/source/global.h $(TRUNKDIR)/source/object.h $(TRUNKDIR)/source/symtab.h
$(BUILDDIR)/backobj/back/be_inline.o: $(TRUNKDIR)/source/execute.h $(TRUNKDIR)/source/reswords.h $(TRUNKDIR)/source/be_alloc.h
$(BUILDDIR)/backobj/back/be_machine.o: $(TRUNKDIR)/source/global.h $(TRUNKDIR)/source/object.h $(TRUNKDIR)/source/symtab.h $(TRUNKDIR)/source/alldefs.h
$(BUILDDIR)/backobj/back/be_machine.o: $(TRUNKDIR)/source/execute.h $(TRUNKDIR)/source/reswords.h $(TRUNKDIR)/source/version.h
$(BUILDDIR)/backobj/back/be_machine.o: $(TRUNKDIR)/source/be_runtime.h $(TRUNKDIR)/source/be_rterror.h $(TRUNKDIR)/source/be_main.h
$(BUILDDIR)/backobj/back/be_machine.o: $(TRUNKDIR)/source/be_w.h $(TRUNKDIR)/source/be_symtab.h $(TRUNKDIR)/source/be_machine.h
$(BUILDDIR)/backobj/back/be_machine.o: $(TRUNKDIR)/source/be_pcre.h $(TRUNKDIR)/source/pcre/pcre.h $(TRUNKDIR)/source/be_task.h
$(BUILDDIR)/backobj/back/be_machine.o: $(TRUNKDIR)/source/be_alloc.h $(TRUNKDIR)/source/be_execute.h $(TRUNKDIR)/source/be_socket.h
$(BUILDDIR)/backobj/back/be_machine.o: $(TRUNKDIR)/source/be_coverage.h $(TRUNKDIR)/source/be_syncolor.h $(TRUNKDIR)/source/be_debug.h
$(BUILDDIR)/backobj/back/be_main.o: $(TRUNKDIR)/source/alldefs.h $(TRUNKDIR)/source/global.h $(TRUNKDIR)/source/object.h $(TRUNKDIR)/source/symtab.h
$(BUILDDIR)/backobj/back/be_main.o: $(TRUNKDIR)/source/execute.h $(TRUNKDIR)/source/reswords.h $(TRUNKDIR)/source/be_runtime.h
$(BUILDDIR)/backobj/back/be_main.o: $(TRUNKDIR)/source/be_execute.h $(TRUNKDIR)/source/be_alloc.h $(TRUNKDIR)/source/be_rterror.h
$(BUILDDIR)/backobj/back/be_main.o: $(TRUNKDIR)/source/be_w.h
$(BUILDDIR)/backobj/back/be_pcre.o: $(TRUNKDIR)/source/alldefs.h $(TRUNKDIR)/source/global.h $(TRUNKDIR)/source/object.h $(TRUNKDIR)/source/symtab.h
$(BUILDDIR)/backobj/back/be_pcre.o: $(TRUNKDIR)/source/execute.h $(TRUNKDIR)/source/reswords.h $(TRUNKDIR)/source/be_alloc.h
$(BUILDDIR)/backobj/back/be_pcre.o: $(TRUNKDIR)/source/be_runtime.h $(TRUNKDIR)/source/be_pcre.h $(TRUNKDIR)/source/pcre/pcre.h
$(BUILDDIR)/backobj/back/be_pcre.o: $(TRUNKDIR)/source/be_machine.h
$(BUILDDIR)/backobj/back/be_rterror.o: $(TRUNKDIR)/source/alldefs.h $(TRUNKDIR)/source/global.h $(TRUNKDIR)/source/object.h $(TRUNKDIR)/source/symtab.h
$(BUILDDIR)/backobj/back/be_rterror.o: $(TRUNKDIR)/source/execute.h $(TRUNKDIR)/source/reswords.h $(TRUNKDIR)/source/be_rterror.h
$(BUILDDIR)/backobj/back/be_rterror.o: $(TRUNKDIR)/source/be_runtime.h $(TRUNKDIR)/source/be_task.h $(TRUNKDIR)/source/be_w.h
$(BUILDDIR)/backobj/back/be_rterror.o: $(TRUNKDIR)/source/be_machine.h $(TRUNKDIR)/source/be_execute.h $(TRUNKDIR)/source/be_symtab.h
$(BUILDDIR)/backobj/back/be_rterror.o: $(TRUNKDIR)/source/be_alloc.h $(TRUNKDIR)/source/be_syncolor.h $(TRUNKDIR)/source/be_debug.h
$(BUILDDIR)/backobj/back/be_runtime.o: $(TRUNKDIR)/source/alldefs.h $(TRUNKDIR)/source/global.h $(TRUNKDIR)/source/object.h $(TRUNKDIR)/source/symtab.h
$(BUILDDIR)/backobj/back/be_runtime.o: $(TRUNKDIR)/source/execute.h $(TRUNKDIR)/source/reswords.h $(TRUNKDIR)/source/be_alloc.h
$(BUILDDIR)/backobj/back/be_runtime.o: $(TRUNKDIR)/source/be_runtime.h $(TRUNKDIR)/source/be_machine.h $(TRUNKDIR)/source/be_inline.h
$(BUILDDIR)/backobj/back/be_runtime.o: $(TRUNKDIR)/source/be_w.h $(TRUNKDIR)/source/be_callc.h $(TRUNKDIR)/source/be_task.h
$(BUILDDIR)/backobj/back/be_runtime.o: $(TRUNKDIR)/source/be_rterror.h $(TRUNKDIR)/source/be_coverage.h
$(BUILDDIR)/backobj/back/be_runtime.o: $(TRUNKDIR)/source/be_execute.h $(TRUNKDIR)/source/be_symtab.h
$(BUILDDIR)/backobj/back/be_socket.o: $(TRUNKDIR)/source/alldefs.h $(TRUNKDIR)/source/global.h $(TRUNKDIR)/source/object.h $(TRUNKDIR)/source/symtab.h
$(BUILDDIR)/backobj/back/be_socket.o: $(TRUNKDIR)/source/execute.h $(TRUNKDIR)/source/reswords.h $(TRUNKDIR)/source/be_alloc.h
$(BUILDDIR)/backobj/back/be_socket.o: $(TRUNKDIR)/source/be_machine.h $(TRUNKDIR)/source/be_runtime.h $(TRUNKDIR)/source/be_socket.h
$(BUILDDIR)/backobj/back/be_symtab.o: $(TRUNKDIR)/source/alldefs.h $(TRUNKDIR)/source/global.h $(TRUNKDIR)/source/object.h $(TRUNKDIR)/source/symtab.h
$(BUILDDIR)/backobj/back/be_symtab.o: $(TRUNKDIR)/source/execute.h $(TRUNKDIR)/source/reswords.h $(TRUNKDIR)/source/be_execute.h
$(BUILDDIR)/backobj/back/be_symtab.o: $(TRUNKDIR)/source/be_alloc.h $(TRUNKDIR)/source/be_machine.h $(TRUNKDIR)/source/be_runtime.h
$(BUILDDIR)/backobj/back/be_syncolor.o: $(TRUNKDIR)/source/be_w.h $(TRUNKDIR)/source/global.h $(TRUNKDIR)/source/object.h $(TRUNKDIR)/source/symtab.h
$(BUILDDIR)/backobj/back/be_syncolor.o: $(TRUNKDIR)/source/execute.h $(TRUNKDIR)/source/alldefs.h $(TRUNKDIR)/source/reswords.h
$(BUILDDIR)/backobj/back/be_syncolor.o: $(TRUNKDIR)/source/be_alloc.h $(TRUNKDIR)/source/be_machine.h $(TRUNKDIR)/source/be_syncolor.h
$(BUILDDIR)/backobj/back/be_task.o: $(TRUNKDIR)/source/global.h $(TRUNKDIR)/source/object.h $(TRUNKDIR)/source/symtab.h $(TRUNKDIR)/source/execute.h
$(BUILDDIR)/backobj/back/be_task.o: $(TRUNKDIR)/source/reswords.h $(TRUNKDIR)/source/be_runtime.h $(TRUNKDIR)/source/be_task.h
$(BUILDDIR)/backobj/back/be_task.o: $(TRUNKDIR)/source/be_alloc.h $(TRUNKDIR)/source/be_machine.h $(TRUNKDIR)/source/be_execute.h
$(BUILDDIR)/backobj/back/be_task.o: $(TRUNKDIR)/source/be_symtab.h $(TRUNKDIR)/source/alldefs.h
$(BUILDDIR)/backobj/back/be_w.o: $(TRUNKDIR)/source/alldefs.h $(TRUNKDIR)/source/global.h $(TRUNKDIR)/source/object.h $(TRUNKDIR)/source/symtab.h
$(BUILDDIR)/backobj/back/be_w.o: $(TRUNKDIR)/source/execute.h $(TRUNKDIR)/source/reswords.h $(TRUNKDIR)/source/be_w.h $(TRUNKDIR)/source/be_machine.h
$(BUILDDIR)/backobj/back/be_w.o: $(TRUNKDIR)/source/be_runtime.h $(TRUNKDIR)/source/be_rterror.h $(TRUNKDIR)/source/be_alloc.h
$(BUILDDIR)/backobj/back/echoversion.o: $(TRUNKDIR)/source/version.h
$(BUILDDIR)/backobj/back/rbt.o: $(TRUNKDIR)/source/rbt.h

$(BUILDDIR)/libobj/back/be_alloc.o: $(TRUNKDIR)/source/alldefs.h $(TRUNKDIR)/source/global.h $(TRUNKDIR)/source/object.h $(TRUNKDIR)/source/symtab.h
$(BUILDDIR)/libobj/back/be_alloc.o: $(TRUNKDIR)/source/execute.h $(TRUNKDIR)/source/reswords.h $(TRUNKDIR)/source/be_runtime.h
$(BUILDDIR)/libobj/back/be_alloc.o: $(TRUNKDIR)/source/be_alloc.h
$(BUILDDIR)/libobj/back/be_callc.o: $(TRUNKDIR)/source/alldefs.h $(TRUNKDIR)/source/global.h $(TRUNKDIR)/source/object.h $(TRUNKDIR)/source/symtab.h
$(BUILDDIR)/libobj/back/be_callc.o: $(TRUNKDIR)/source/execute.h $(TRUNKDIR)/source/reswords.h $(TRUNKDIR)/source/be_runtime.h
$(BUILDDIR)/libobj/back/be_callc.o: $(TRUNKDIR)/source/be_machine.h $(TRUNKDIR)/source/be_alloc.h
$(BUILDDIR)/libobj/back/be_coverage.o: $(TRUNKDIR)/source/be_coverage.h $(TRUNKDIR)/source/be_machine.h $(TRUNKDIR)/source/global.h
$(BUILDDIR)/libobj/back/be_coverage.o: $(TRUNKDIR)/source/object.h $(TRUNKDIR)/source/symtab.h $(TRUNKDIR)/source/execute.h
$(BUILDDIR)/libobj/back/be_debug.o: $(TRUNKDIR)/source/execute.h $(TRUNKDIR)/source/global.h $(TRUNKDIR)/source/object.h $(TRUNKDIR)/source/symtab.h
$(BUILDDIR)/libobj/back/be_debug.o: $(TRUNKDIR)/source/redef.h $(TRUNKDIR)/source/reswords.h $(TRUNKDIR)/source/be_alloc.h $(TRUNKDIR)/source/be_debug.h
$(BUILDDIR)/libobj/back/be_debug.o: $(TRUNKDIR)/source/be_execute.h $(TRUNKDIR)/source/be_machine.h $(TRUNKDIR)/source/be_rterror.h
$(BUILDDIR)/libobj/back/be_debug.o: $(TRUNKDIR)/source/be_runtime.h $(TRUNKDIR)/source/be_symtab.h
$(BUILDDIR)/libobj/back/be_decompress.o: $(TRUNKDIR)/source/alldefs.h $(TRUNKDIR)/source/global.h $(TRUNKDIR)/source/object.h $(TRUNKDIR)/source/symtab.h
$(BUILDDIR)/libobj/back/be_decompress.o: $(TRUNKDIR)/source/execute.h $(TRUNKDIR)/source/reswords.h $(TRUNKDIR)/source/be_alloc.h
$(BUILDDIR)/libobj/back/be_decompress.o: $(TRUNKDIR)/source/be_runtime.h
$(BUILDDIR)/libobj/back/be_execute.o: $(TRUNKDIR)/source/alldefs.h $(TRUNKDIR)/source/global.h $(TRUNKDIR)/source/object.h $(TRUNKDIR)/source/symtab.h
$(BUILDDIR)/libobj/back/be_execute.o: $(TRUNKDIR)/source/execute.h $(TRUNKDIR)/source/reswords.h $(TRUNKDIR)/source/be_alloc.h
$(BUILDDIR)/libobj/back/be_execute.o: $(TRUNKDIR)/source/be_runtime.h $(TRUNKDIR)/source/be_decompress.h
$(BUILDDIR)/libobj/back/be_execute.o: $(TRUNKDIR)/source/be_inline.h $(TRUNKDIR)/source/be_machine.h $(TRUNKDIR)/source/be_task.h
$(BUILDDIR)/libobj/back/be_execute.o: $(TRUNKDIR)/source/be_rterror.h $(TRUNKDIR)/source/be_symtab.h $(TRUNKDIR)/source/be_w.h
$(BUILDDIR)/libobj/back/be_execute.o: $(TRUNKDIR)/source/be_callc.h $(TRUNKDIR)/source/be_coverage.h $(TRUNKDIR)/source/be_execute.h
$(BUILDDIR)/libobj/back/be_execute.o: $(TRUNKDIR)/source/be_debug.h
$(BUILDDIR)/libobj/back/be_inline.o: $(TRUNKDIR)/source/alldefs.h $(TRUNKDIR)/source/global.h $(TRUNKDIR)/source/object.h $(TRUNKDIR)/source/symtab.h
$(BUILDDIR)/libobj/back/be_inline.o: $(TRUNKDIR)/source/execute.h $(TRUNKDIR)/source/reswords.h $(TRUNKDIR)/source/be_alloc.h
$(BUILDDIR)/libobj/back/be_machine.o: $(TRUNKDIR)/source/global.h $(TRUNKDIR)/source/object.h $(TRUNKDIR)/source/symtab.h $(TRUNKDIR)/source/alldefs.h
$(BUILDDIR)/libobj/back/be_machine.o: $(TRUNKDIR)/source/execute.h $(TRUNKDIR)/source/reswords.h $(TRUNKDIR)/source/version.h
$(BUILDDIR)/libobj/back/be_machine.o: $(TRUNKDIR)/source/be_runtime.h $(TRUNKDIR)/source/be_rterror.h $(TRUNKDIR)/source/be_main.h
$(BUILDDIR)/libobj/back/be_machine.o: $(TRUNKDIR)/source/be_w.h $(TRUNKDIR)/source/be_symtab.h $(TRUNKDIR)/source/be_machine.h
$(BUILDDIR)/libobj/back/be_machine.o: $(TRUNKDIR)/source/be_pcre.h $(TRUNKDIR)/source/pcre/pcre.h $(TRUNKDIR)/source/be_task.h
$(BUILDDIR)/libobj/back/be_machine.o: $(TRUNKDIR)/source/be_alloc.h $(TRUNKDIR)/source/be_execute.h $(TRUNKDIR)/source/be_socket.h
$(BUILDDIR)/libobj/back/be_machine.o: $(TRUNKDIR)/source/be_coverage.h $(TRUNKDIR)/source/be_syncolor.h $(TRUNKDIR)/source/be_debug.h
$(BUILDDIR)/libobj/back/be_main.o: $(TRUNKDIR)/source/alldefs.h $(TRUNKDIR)/source/global.h $(TRUNKDIR)/source/object.h $(TRUNKDIR)/source/symtab.h
$(BUILDDIR)/libobj/back/be_main.o: $(TRUNKDIR)/source/execute.h $(TRUNKDIR)/source/reswords.h $(TRUNKDIR)/source/be_runtime.h
$(BUILDDIR)/libobj/back/be_main.o: $(TRUNKDIR)/source/be_execute.h $(TRUNKDIR)/source/be_alloc.h $(TRUNKDIR)/source/be_rterror.h
$(BUILDDIR)/libobj/back/be_main.o: $(TRUNKDIR)/source/be_w.h
$(BUILDDIR)/libobj/back/be_pcre.o: $(TRUNKDIR)/source/alldefs.h $(TRUNKDIR)/source/global.h $(TRUNKDIR)/source/object.h $(TRUNKDIR)/source/symtab.h
$(BUILDDIR)/libobj/back/be_pcre.o: $(TRUNKDIR)/source/execute.h $(TRUNKDIR)/source/reswords.h $(TRUNKDIR)/source/be_alloc.h
$(BUILDDIR)/libobj/back/be_pcre.o: $(TRUNKDIR)/source/be_runtime.h $(TRUNKDIR)/source/be_pcre.h $(TRUNKDIR)/source/pcre/pcre.h
$(BUILDDIR)/libobj/back/be_pcre.o: $(TRUNKDIR)/source/be_machine.h
$(BUILDDIR)/libobj/back/be_rterror.o: $(TRUNKDIR)/source/alldefs.h $(TRUNKDIR)/source/global.h $(TRUNKDIR)/source/object.h $(TRUNKDIR)/source/symtab.h
$(BUILDDIR)/libobj/back/be_rterror.o: $(TRUNKDIR)/source/execute.h $(TRUNKDIR)/source/reswords.h $(TRUNKDIR)/source/be_rterror.h
$(BUILDDIR)/libobj/back/be_rterror.o: $(TRUNKDIR)/source/be_runtime.h $(TRUNKDIR)/source/be_task.h $(TRUNKDIR)/source/be_w.h
$(BUILDDIR)/libobj/back/be_rterror.o: $(TRUNKDIR)/source/be_machine.h $(TRUNKDIR)/source/be_execute.h $(TRUNKDIR)/source/be_symtab.h
$(BUILDDIR)/libobj/back/be_rterror.o: $(TRUNKDIR)/source/be_alloc.h $(TRUNKDIR)/source/be_syncolor.h $(TRUNKDIR)/source/be_debug.h
$(BUILDDIR)/libobj/back/be_runtime.o: $(TRUNKDIR)/source/alldefs.h $(TRUNKDIR)/source/global.h $(TRUNKDIR)/source/object.h $(TRUNKDIR)/source/symtab.h
$(BUILDDIR)/libobj/back/be_runtime.o: $(TRUNKDIR)/source/execute.h $(TRUNKDIR)/source/reswords.h $(TRUNKDIR)/source/be_alloc.h
$(BUILDDIR)/libobj/back/be_runtime.o: $(TRUNKDIR)/source/be_runtime.h $(TRUNKDIR)/source/be_machine.h $(TRUNKDIR)/source/be_inline.h
$(BUILDDIR)/libobj/back/be_runtime.o: $(TRUNKDIR)/source/be_w.h $(TRUNKDIR)/source/be_callc.h $(TRUNKDIR)/source/be_task.h
$(BUILDDIR)/libobj/back/be_runtime.o: $(TRUNKDIR)/source/be_rterror.h $(TRUNKDIR)/source/be_coverage.h $(TRUNKDIR)/source/be_execute.h
$(BUILDDIR)/libobj/back/be_runtime.o: $(TRUNKDIR)/source/be_symtab.h
$(BUILDDIR)/libobj/back/be_socket.o: $(TRUNKDIR)/source/alldefs.h $(TRUNKDIR)/source/global.h $(TRUNKDIR)/source/object.h $(TRUNKDIR)/source/symtab.h
$(BUILDDIR)/libobj/back/be_socket.o: $(TRUNKDIR)/source/execute.h $(TRUNKDIR)/source/reswords.h $(TRUNKDIR)/source/be_alloc.h
$(BUILDDIR)/libobj/back/be_socket.o: $(TRUNKDIR)/source/be_machine.h $(TRUNKDIR)/source/be_runtime.h $(TRUNKDIR)/source/be_socket.h
$(BUILDDIR)/libobj/back/be_symtab.o: $(TRUNKDIR)/source/alldefs.h $(TRUNKDIR)/source/global.h $(TRUNKDIR)/source/object.h $(TRUNKDIR)/source/symtab.h
$(BUILDDIR)/libobj/back/be_symtab.o: $(TRUNKDIR)/source/execute.h $(TRUNKDIR)/source/reswords.h $(TRUNKDIR)/source/be_execute.h
$(BUILDDIR)/libobj/back/be_symtab.o: $(TRUNKDIR)/source/be_alloc.h $(TRUNKDIR)/source/be_machine.h $(TRUNKDIR)/source/be_runtime.h
$(BUILDDIR)/libobj/back/be_syncolor.o: $(TRUNKDIR)/source/be_w.h $(TRUNKDIR)/source/global.h $(TRUNKDIR)/source/object.h $(TRUNKDIR)/source/symtab.h
$(BUILDDIR)/libobj/back/be_syncolor.o: $(TRUNKDIR)/source/execute.h $(TRUNKDIR)/source/alldefs.h $(TRUNKDIR)/source/reswords.h
$(BUILDDIR)/libobj/back/be_syncolor.o: $(TRUNKDIR)/source/be_alloc.h $(TRUNKDIR)/source/be_machine.h $(TRUNKDIR)/source/be_syncolor.h
$(BUILDDIR)/libobj/back/be_task.o: $(TRUNKDIR)/source/global.h $(TRUNKDIR)/source/object.h $(TRUNKDIR)/source/symtab.h $(TRUNKDIR)/source/execute.h
$(BUILDDIR)/libobj/back/be_task.o: $(TRUNKDIR)/source/reswords.h $(TRUNKDIR)/source/be_runtime.h $(TRUNKDIR)/source/be_task.h
$(BUILDDIR)/libobj/back/be_task.o: $(TRUNKDIR)/source/be_alloc.h $(TRUNKDIR)/source/be_machine.h $(TRUNKDIR)/source/be_execute.h
$(BUILDDIR)/libobj/back/be_task.o: $(TRUNKDIR)/source/be_symtab.h $(TRUNKDIR)/source/alldefs.h
$(BUILDDIR)/libobj/back/be_w.o: $(TRUNKDIR)/source/alldefs.h $(TRUNKDIR)/source/global.h $(TRUNKDIR)/source/object.h $(TRUNKDIR)/source/symtab.h
$(BUILDDIR)/libobj/back/be_w.o: $(TRUNKDIR)/source/execute.h $(TRUNKDIR)/source/reswords.h $(TRUNKDIR)/source/be_w.h $(TRUNKDIR)/source/be_machine.h
$(BUILDDIR)/libobj/back/be_w.o: $(TRUNKDIR)/source/be_runtime.h $(TRUNKDIR)/source/be_rterror.h $(TRUNKDIR)/source/be_alloc.h
$(BUILDDIR)/libobj/back/echoversion.o: $(TRUNKDIR)/source/version.h
$(BUILDDIR)/libobj/back/rbt.o: $(TRUNKDIR)/source/rbt.h