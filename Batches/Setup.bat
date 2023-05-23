@echo off
call Publish.Tools
call Pack.All %1
call Publish.Backend
call Publish.Clients
