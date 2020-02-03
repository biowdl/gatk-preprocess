Changelog
==========

<!--

Newest changes should be on top.

This document is user facing. Please word the changes in such a way
that users understand how the changes affect the new version.
-->

version 2.0.0-dev
-----------------
+ Remove structs from input and output.
+ Added inputs overview to the docs.
+ Added parameter_meta.
+ Added wdl-aid to linting.
+ Added miniwdl to linting.

version 1.1.0
---------------------------
+ Update tasks so they pass the correct memory requirements to the 
  execution engine. Memory requirements are set on a per-task (not
  per-core) basis.

version 1.0.0
---------------------------
+ fixed the md5sum key in gatheredBam (md5 -> md5sum)
+ Updated documentation to reflect latest changes
