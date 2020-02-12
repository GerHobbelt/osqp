
# Add qdldl
qdldl_interface_src = ['qdldl_interface.d']
# todo : EMBEDDED also requires these files
#if embedded == '0'
  amd_sources = ['amd/include/amd_internal.d',
                 'amd/src/amd_1.d',
                 'amd/src/amd_2.d',
                 'amd/src/amd_aat.d',
                 'amd/src/amd_control.d',
                 'amd/src/amd_defaults.d',
                 'amd/src/amd_info.d',
                 'amd/src/amd_order.d',
                 'amd/src/amd_post_tree.d',
                 'amd/src/amd_postorder.d',
                 'amd/src/amd_preprocess.d',
                 'amd/src/amd_valid.d',
                 'amd/src/SuiteSparse_config.d']

  qdldl_interface_src += amd_sources
#endif


# Create object library for linear system solver interface
message ('making object library linsys_qdldl_lib ...')
linsys_qdldl_lib = library('linsys_qdldl', 
                            qdldl_interface_src,
                            include_directories: ['../../../include', '../../../configure', 'amd/include', 'qdldl_sources/include',
                                                 'amd/src', 'amd/include', '../../../src', 'qdldl_sources/src'  # for D modules
                            ],
                            d_module_versions: d_module_versions
                            )

# Generate header file with the global options
# ---------------------------------------------
conf_qdldl = configuration_data()

# numeric types
if conf_data.get('DFLOAT')
  conf_qdldl.set('QDLDL_FLOAT_TYPE', 'float')
else
  conf_qdldl.set('QDLDL_FLOAT_TYPE', 'double')
endif
if conf_data.get('DLONG')
  #conf_qdldl.set('QDLDL_INT_TYPE', 'long long')
  conf_qdldl.set('QDLDL_INT_TYPE', 'long')
  conf_qdldl.set('QDLDL_INT_MAX', 'LLONG_MAX')
else
  conf_qdldl.set('QDLDL_INT_TYPE', 'int')
  conf_qdldl.set('QDLDL_INT_MAX', 'INT_MAX')
endif
#boolean type is always unsigned char
#for now, since _Bool does not exist in
#C89 and we want to avoid interoperability
#problems when calling QDLDL from C++
#conf_qdldl.set('QDLDL_BOOL_TYPE', 'unsigned char')
conf_qdldl.set('QDLDL_BOOL_TYPE', 'ubyte')

#configure_file(input : 'qdldl_sources/configure/qdldl_types.h.in',
#  output : 'qdldl_types.h',
#  configuration : conf_qdldl)
#configure_file(input : 'qdldl_sources/configure/qdldl_types.d.in',
#  output : 'qdldl_types.d',
#  configuration : conf_qdldl)

# todo : get build directory name here
#run_command('cp', '../../../build/lin_sys/direct/qdldl/qdldl_types.h', 'qdldl_sources/include/qdldl_types.h')
#run_command('cp', '../../../build/lin_sys/direct/qdldl/qdldl_types.d', 'qdldl_sources/src/qdldl_types.d')


# Set sources
# ----------------------------------------------
qdldl_src = 'qdldl_sources/src/qdldl.d'
qdldl_headers = ['qdldl_sources/include/qdldl.h']

# Create object library
# ----------------------------------------------
message ('making object library qdldlobject_lib ...')
qdldlobject_lib = library('qdldlobject', 
                          qdldl_src, 
						              qdldl_headers,
                          include_directories: ['qdldl_sources/include', 'qdldl_sources/src'],
                          d_module_versions: d_module_versions,
						              c_args: c_args)

# Give same name to static library output
# set_target_properties(['qdldlstatic', 'PROPERTIES', 'OUTPUT_NAME', 'qdldl'])
# Install Static Library
# install(['TARGETS', 'qdldlstatic', 'EXPORT', project_name, 'ARCHIVE', 'DESTINATION', '${CMAKE_INSTALL_LIBDIR}', 'LIBRARY', 'DESTINATION', '${CMAKE_INSTALL_LIBDIR}', 'RUNTIME', 'DESTINATION', '${CMAKE_INSTALL_BINDIR}'])

# Create qdldl shared library
# ----------------------------------------------
message ('making library qdldl_lib ...')
qdldl_lib = library('qdldl', 
                           qdldl_src, 
                           qdldl_headers,
                           include_directories: ['qdldl_sources/include', 'qdldl_sources/src'],
                           dependencies: [gcov_lib],
                           d_module_versions: d_module_versions,
                           c_args: c_args)
# Install qdldl shared library
# install(['TARGETS', 'qdldl', 'EXPORT', project_name, 'LIBRARY', 'DESTINATION', '${CMAKE_INSTALL_LIBDIR}', 'ARCHIVE', 'DESTINATION', '${CMAKE_INSTALL_LIBDIR}', 'RUNTIME', 'DESTINATION', '${CMAKE_INSTALL_BINDIR}'])
