@echo off
rem -------------------------------
pushd CumulativeJournal
call Import
popd
rem -------------------------------
pushd EmployeeCaseValues
call Import
popd
rem -------------------------------
pushd EmployeesXml
call Import
popd
rem -------------------------------
pushd Regulation
call Import
popd
rem -------------------------------
pushd RegulationsSimple
call Import
popd
rem -------------------------------
pushd TenantsSimple
call Import
popd
rem -------------------------------
pushd UsersSimple
call Import
popd
