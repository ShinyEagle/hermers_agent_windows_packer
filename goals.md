Package a hermes-agent software bundle that can be used immediately after extraction, including all dependencies. In the release, except for the debug version, all packages not necessary for runtime must be removed.  

Check every hour whether Hermes has released a release that was not built after 00:00:00 UTC on August 1, 2026, and perform the build. Automatically build the release version's release. The debug version requires manual toggling for test releases, and debug versions can be packaged directly after installing hermes-agent.  

Naming conventions are:  
Release naming convention: hermes_agent-yyyyMMddhhmmss-{release or debug}-{version or branch-hash}  
The compressed package follows a similar pattern.