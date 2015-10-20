4.5.0 (2015/10/16)
==================

The main changes since release 4.4.0 are:


pvDataCPP (5.0.2)
-----------------

* New template versions of Structure::getField
* Printing of structure and union arrays modified
* minStep field added to Control
* Changes to access specifiers in Display and PVDisplay


pvAccessCPP (4.1.2)
-------------------

* Async RPC service.


normativeTypesCPP (0.1.2)
-------------------------

This is the first release of normativeTypesJava.

* This release provides support through wrapper classes and builders for the
following Normative Types:
    * NTScalar
    * NTScalarArray
    * NTEnum
    * NTMatrix
    * NTURI
    * NTNameValue
    * NTTable
    * NTAttribute
    * NTMultiChannel
    * NTNDArray
    * NTContinuum
    * NTHistogram
    * NTAggregate
    * NTUnion
    * NTScalarMultiChannel

* Release 0.1 therefore implements fully the
[16 Mar 2015 version](http://epics-pvdata.sourceforge.net/alpha/normativeTypes/normativeTypes_20150316.html)
 of the normativeTypes specification.
* Each type has a builder and a class for testing compatibility and wrapping
  existing structures.
* Utility classes NTField and NTPVField for standard structure fields and
  NTUtils and NTID for type IDs.
* Unit tests for all the implemented types and other classes, providing
  extensive coverage for all the Normative Types (except NTNDArray).


pvaClientJava (4.1.3)
--------------------

pvaClientJava is the successor to easyPVAJava, a synchronous API for pvAccess.

* pvaClient uses exceptions to report most problem instead
  of requiring the client to call status methods.


easyPVAJava (4.1.3)
--------------------

* EasyPVA automatically starts ChannelProvider for both Channel Access and pvAccess.
* EasyMultiChannel is now implemented
* Support for monitors is now available both for EasyChannel and EasyMultiChannel.


pvDatabaseJava (4.1.2)
---------------------

This is the first release of pvDatabaseJava, an EPICS V4 record/database framework for providing services over pvAccess.


directoryService (0.4.2)
-----------------------

(No significant changes)


exampleJava (4.0.5)
------------------

(No significant changes)
