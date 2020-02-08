# Minimum version required
# Project name
project('osqp', 'c', 'd', version : '0.1', default_options : ['default_library=static'])
#add_project_arguments('-lxc++', language: 'd')
add_project_arguments(['-dip25','-dip1000','-dip1008',], language: 'd')

c_compiler = meson.get_compiler('c')

d_module_versions = []

conf_data = configuration_data({
  'UNITTESTS' : get_option('UNITTESTS'),
  'PRINTING' : get_option('PRINTING'),
  'PROFILING' : get_option('PROFILING'),
  'CTRLC' : get_option('CTRLC'),
  'DFLOAT': get_option('DFLOAT'),
  'DLONG': get_option('DLONG'),
  'DEBUG': get_option('DEBUG'),
  'NDEBUG': get_option('NDEBUG'),
  'COVERAGE': get_option('COVERAGE'),
  'ENABLE_MKL_PARDISO': get_option('ENABLE_MKL_PARDISO'),  
  'EMBEDDED': get_option('USE_EMBEDDED'),
  'OSQP_CUSTOM_MEMORY': get_option('OSQP_CUSTOM_MEMORY'),
  'OSQP_CUSTOM_MEMORY_HEADER': get_option('OSQP_CUSTOM_MEMORY_HEADER'),
  'MATLAB': get_option('MATLAB'),
  'PYTHON': get_option('PYTHON'),
  'R_LANG': get_option('R_LANG'),
  'PYTHON_INCLUDE_DIRS': get_option('PYTHON_INCLUDE_DIRS'),
  'FORTRAN': get_option('FORTRAN')
})

# Set options
# ----------------------------------------------
# Are unittests generated?
# Is the code generated for embedded platforms?
embedded = get_option('EMBEDDED')
#   0 :   Default. Not for embedded platforms.
#   1 :   Yes. Matrix update not allowed.
#   2 :   Yes. Matrix update allowed.

if embedded == '0'
  message(['STATUS', 'Embedded is OFF'])
  conf_data.set('USE_EMBEDDED', false)
else
  message(['STATUS', 'Disabling printing for embedded'])
  conf_data.set('PRINTING', false)
  message(['STATUS', 'Disabling profiling for embedded'])
  conf_data.set('PROFILING', false)
  message(['STATUS', 'Disabling user interrupt for embedded'])
  conf_data.set('CTRLC', false)
  conf_data.set('USE_EMBEDDED', true)

  if embedded == '1'
    conf_data.set('EMBEDDED', 1)    
    # todo : review it
    d_module_versions += 'EMBEDDED'
    d_module_versions += 'EMBEDDED_1'
  else
    conf_data.set('EMBEDDED', 2)
    # todo : review it
    d_module_versions += 'EMBEDDED'
    d_module_versions += 'EMBEDDED_2'
  endif
endif
message(['STATUS', 'User interrupt is @0@'.format(get_option('CTRLC'))])

# Use floats instead of integers
message(['STATUS', 'Floats are @0@'.format(get_option('DFLOAT'))])

if get_option('DEBUG')
  conf_data.set('DEBUG', true)
  message(['STATUS', 'Debug mode is ON'])
endif
# Add code coverage
# message(['STATUS', 'Code coverage is ${COVERAGE}'])
# Memory allocators
# ----------------------------------------------
#Report on custom user header options.  This is intended to allow
#users to provide definitions of their own memory functions
# The header should define the functions as follows
#
# define c_malloc mymalloc
# define c_calloc mycalloc
# define c_realloc myrealloc
# define c_free myfree
if get_option('OSQP_CUSTOM_MEMORY')
  message(['STATUS', 'User custom memory management header: @0@'.format(get_option('OSQP_CUSTOM_MEMORY_HEADER'))])
   
  # TODO: make sure of correct quotes
  conf_data.set('OSQP_CUSTOM_MEMORY', get_option('OSQP_CUSTOM_MEMORY'))
  conf_data.set('OSQP_CUSTOM_MEMORY_HEADER', get_option('OSQP_CUSTOM_MEMORY_HEADER'))  
else
  conf_data.set('OSQP_CUSTOM_MEMORY', false)
endif

# Linear solvers dependencies
# ---------------------------------------------
if get_option('DFLOAT')
  message(['STATUS', 'Disabling MKL Pardiso Solver with floats'])
  conf_data.set('ENABLE_MKL_PARDISO', false)
elif embedded != '0'
  message(['STATUS', 'Disabling MKL Pardiso Solver for embedded'])
  conf_data.set('ENABLE_MKL_PARDISO', false)
endif
message(['STATUS', 'MKL Pardiso: @0@'.format(conf_data.get('ENABLE_MKL_PARDISO', false))])


if conf_data.get('UNITTESTS')
 # todo : add to args
 #d_unittest: true
endif
if conf_data.get('OSQP_CUSTOM_MEMORY')
  # todo : review it
  d_module_versions += 'OSQP_CUSTOM_MEMORY'
endif
if conf_data.get('PRINTING')
  d_module_versions += 'PRINTING'
endif
if conf_data.get('PROFILING')
  d_module_versions += 'PROFILING'
endif
if conf_data.get('CTRLC')
  d_module_versions += 'CTRLC'
endif
if conf_data.get('DFLOAT')
  d_module_versions += 'DFLOAT'
endif
if conf_data.get('DLONG')
  d_module_versions += 'DLONG'
endif
if conf_data.get('DEBUG')
  # todO : replace with something like d_debug: [3, 'DebugFeatureA'])
  d_module_versions += 'DEBUG'
endif
if conf_data.get('ENABLE_MKL_PARDISO')
  d_module_versions += 'ENABLE_MKL_PARDISO'
endif
if conf_data.get('MATLAB')
  d_module_versions += 'MATLAB'
endif
if conf_data.get('PYTHON')
  d_module_versions += 'PYTHON'
endif
if conf_data.get('R_LANG')
  d_module_versions += 'R_LANG'
endif

if conf_data.get('NDEBUG')
  d_module_versions += 'NDEBUG'
endif

message ('d_module_versions=@0@'.format(d_module_versions))


# Generate header file with the global options
# ---------------------------------------------
configure_file(input : 'configure/osqp_configure.d.in',
  output : 'osqp_configure.d',
  configuration : conf_data)

# todo : get build directory name here
run_command('cp', 'build/osqp_configure.d', 'include/osqp_configure.d')


# todo : configuration for C demo and test
configure_file(input : 'configure/osqp_configure.h.in',
  output : 'osqp_configure.h',
  configuration : conf_data)
# todo : get build directory name here
run_command('cp', 'build/osqp_configure.h', 'include/osqp_configure.h')



# Set Compiler flags
#d_compiler = meson.get_compiler('d')
# ----------------------------------------------
# todo : set some default CMAKE_C_FLAGS|CMAKE_FORTRAN_FLAGS|CMAKE_C_STANDARD_LIBRARIES
c_args = []
gcov_lib = []
rt_lib = []
m_lib = []
dl_lib = []

if c_compiler.get_id() != 'msvc'
  if conf_data.get('COVERAGE')
    c_args += '--coverage'
    gcov_lib = c_compiler.find_library('gcov')
    #c_args += '-fprofile-arcs -ftest-coverage --enable-profile -lgcov'
	  if conf_data.get('FORTRAN')
      #c_args += '--coverage'
	  endif
  endif

  if conf_data.get('DEBUG')
    c_args += '-O0 -g'
  else
    c_args += '-O3'
  endif

  # Include math
  #c_args += '-lm'
  m_lib = c_compiler.find_library('m')
  if target_machine.system() == 'linux'
    # Include real time library in linux
    #c_args += '-lrt -ldl'
    rt_lib = c_compiler.find_library('rt')
    dl_lib = c_compiler.find_library('dl')
  endif
endif

d_args = ['-betterC', c_args]

#************************************************************************************
current_source_dir = meson.current_source_dir()
# Add the OSQP headers
osqp_headers = ['include/auxil.h', 
                'include/constants.h', 
                'include/error.h', 
                'include/glob_opts.h', 
                'include/lin_alg.h', 
                'include/osqp.h', 
                #'include/osqp_configure.h', 
                'include/proj.h', 
                'include/scaling.h', 
                'include/types.h', 
                'include/util.h']

# Add the OSQP sources
osqp_src = ['src/auxil.d',
            'src/error.d',
            'src/lin_alg.d',
            'src/osqp.d',
            'src/proj.d',
            'src/scaling.d',
            'src/util.d',            
            'include/glob_opts.d',
            'include/types.d']

# Add the KKT update only in normal mode and matrix-updating embedded mode (not mode 1)
# todo : EMBEDDED also requires these files
#if embedded != '1'
  osqp_src += 'src/kkt.d'
#endif
# Add more files that should only be in non-embedded code
# todo : EMBEDDED also requires these files
#if not conf_data.get('USE_EMBEDDED')
  osqp_src += ['src/cs.d', 'src/polish.d', 'src/lin_sys.d']
#endif
# Add the ctrl-c handler if enabled
if conf_data.get('CTRLC')
  osqp_src += 'src/ctrlc.d'
endif

#************************************************************************************
# Create Static Library

# ----------------------------------------------
# Add linear system solvers cumulative library
subdir('lin_sys')
# Static library
# '.' include directory is for generated osqp_configure.h
osqpstatic_lib = library('osqpstatic', 
                                osqp_src, 
                                osqp_headers,
                                include_directories: ['include', 'lin_sys/direct/qdldl', 'lin_sys/direct/qdldl/qdldl_sources/include', 'lin_sys/direct/pardiso', 'src',
                                      'lin_sys/direct/qdldl/qdldl_sources/src', 'lin_sys/direct/qdldl/amd/src', 'lin_sys/direct/qdldl/amd/include', 'lin_sys'], # for D modules
                                #dependencies: [c_compiler.find_library('m'), c_compiler.find_library('rt'), c_compiler.find_library('dl'), c_compiler.find_library('gcov')],
                                dependencies: [m_lib, rt_lib, dl_lib, gcov_lib],
                                #dependecies: dependency_list    # WARNING: Passed invalid keyword argument "dependecies". WARNING: This will become a hard error in the future.
                                link_with: linsys_solvers,
                                c_args: d_args,
                                d_module_versions: d_module_versions
                                )
# Give same name to static library output
# set_target_properties(['osqpstatic', 'PROPERTIES', 'OUTPUT_NAME', 'osqp'])
# ----------------------------------------------

# ----------------------------------------------
python = conf_data.get('PYTHON')
matlab = conf_data.get('MATLAB')
r_lang = conf_data.get('R_LANG')

if matlab
  # target_link_libraries(['osqpstatic', matlab_libraries])
endif
# If we are building Python/Matlab/R interface:
#   - do not build shared library
#   - do not build demo
if not python and not matlab and not r_lang and (embedded == '0')
  # Create osqp shared library
  # NB: Add all the linear system solvers here

  osqp_lib = library('osqp', 
                            osqp_src, 
                            osqp_headers,
                            include_directories: ['include', 'lin_sys/direct/qdldl/', 'lin_sys/direct/qdldl/qdldl_sources/include', 'lin_sys/direct/pardiso',
                            'src', 'lin_sys/direct/qdldl/qdldl_sources/src', 'lin_sys/direct/qdldl/amd/src', 'lin_sys/direct/qdldl/amd/include', 'lin_sys'], # for D modules
                            #dependencies: [c_compiler.find_library('m'), c_compiler.find_library('rt'), c_compiler.find_library('dl'), gcov_lib],
                            dependencies: [m_lib, rt_lib, dl_lib, gcov_lib],
                            #dependecies: dependency_list    # WARNING: Passed invalid keyword argument "dependecies". WARNING: This will become a hard error in the future.                            
                            link_with: linsys_solvers,
                            c_args: d_args,
                            d_module_versions: d_module_versions
                            )
  # Install osqp shared library
  # install(['TARGETS', 'osqp', 'EXPORT', project_name, 'LIBRARY', 'DESTINATION', '${CMAKE_INSTALL_LIBDIR}', 'ARCHIVE', 'DESTINATION', '${CMAKE_INSTALL_LIBDIR}', 'RUNTIME', 'DESTINATION', '${CMAKE_INSTALL_BINDIR}'])

  message('Create demo executable (linked to static library)')

  d_library_src = ['include/glob_opts.d',
          'include/constants.d',
          'lin_sys/direct/qdldl/amd/src/SuiteSparse_config.d',
          'lin_sys/direct/qdldl/amd/include/amd.d',
          'lin_sys/direct/qdldl/amd/src/amd_1.d',
          'lin_sys/direct/qdldl/amd/src/amd_2.d',
          'lin_sys/direct/qdldl/amd/src/amd_aat.d',
          'lin_sys/direct/qdldl/amd/src/amd_control.d',
          'lin_sys/direct/qdldl/amd/src/amd_defaults.d',
          'lin_sys/direct/qdldl/amd/src/amd_info.d',
          'lin_sys/direct/qdldl/amd/src/amd_order.d',
          'lin_sys/direct/qdldl/amd/src/amd_post_tree.d',
          'lin_sys/direct/qdldl/amd/src/amd_postorder.d',
          'lin_sys/direct/qdldl/amd/src/amd_preprocess.d',
          'lin_sys/direct/qdldl/amd/src/amd_valid.d',
          'lin_sys/direct/qdldl/amd/include/amd_internal.d']
  
  demo_src = ['examples/osqp_demo.c', d_library_src]

  osqp_demo_exe = executable('osqp_demo', 
                            demo_src,
                            include_directories: ['include', 'lin_sys/direct/qdldl/amd/src', 'lin_sys/direct/qdldl/amd/include'],
                            dependencies: [gcov_lib],
                            link_with: osqp_lib,
                            #link_with: osqpstatic_lib,
                            c_args: c_args,
                            d_module_versions: d_module_versions
                            )
  test('osqp_demo', osqp_demo_exe)
endif

# ----------------------------------------------
# Add custom command to generate tests
if conf_data.get('UNITTESTS')

  subdir('tests')

  # Generating tests.stamp so that the test data are not always generated
  # set(data_timestamp ${PROJECT_SOURCE_DIR}/tests/tests_data.stamp)
  tester_src = ['tests/osqp_tester.c', d_library_src]

  osqp_tester_exe = executable('osqp_tester', 
                               tester_src,
                               include_directories: ['include', 'lin_sys/direct/qdldl/amd/src', 'lin_sys/direct/qdldl/amd/include', 'tests', test_include_dirs],
                               dependencies: [gcov_lib],
                               link_with: osqpstatic_lib,
                               c_args: c_args,
                               d_module_versions: d_module_versions
                               )
  
  # Add custom memory target
  tester_memory_src = ['tests/osqp_tester.c', 'tests/custom_memory/custom_memory.c', d_library_src]
  osqp_tester_custom_memory_exe = executable('osqp_tester_custom_memory', 
                                            tester_memory_src,
                                            include_directories: ['include', 'lin_sys/direct/qdldl/amd/src', 'lin_sys/direct/qdldl/amd/include', 'tests', test_include_dirs],
                                            dependencies: [gcov_lib],
                                            link_with: osqpstatic_lib,
                                            c_args: c_args,
                                            d_module_versions: d_module_versions
                                            )

  test('osqp_tester', osqp_tester_exe)
  test('osqp_tester_custom_memory', osqp_tester_custom_memory_exe)
endif
