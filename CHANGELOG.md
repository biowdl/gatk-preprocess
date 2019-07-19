Changelog
==========

<!--

Newest changes should be on top.

This document is user facing. Please word the changes in such a way
that users understand how the changes affect the new version.
-->

version 1.0.0-dev
---------------------------
+ Remove the ability to scatter. This massively simplifies the workflow. 
  Scattering was causing issues down the read for creating MultiQC reports.
  This change can be used as a stepping stone to integrate the tasks into main workflows. 
  Making the use of this as an extra sub-workflow redundant.
