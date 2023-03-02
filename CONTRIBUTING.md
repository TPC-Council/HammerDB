# Welcome to the HammerDB contributing guide 
 
Thank you for investing your time in contributing to HammerDB! Any contribution you make will be reflected on [github.com/TPC-Council/HammerDB](https://github.com/TPC-Council/HammerDB) :sparkles:.  

HammerDB is the most trusted Free and open source database benchmarking application to the global database industry, and you can learn more about HammerDB and access the most up-to-date documentation at [www.hammerdb.com](https://www.hammerdb.com)

HammerDB is hosted by the [TPC](https://www.tpc.org) a non-profit corporation focused on developing data-centric benchmark standards and disseminating objective, verifiable data to the industry. HammerDB development is guided by [TPC Procedures](https://www.tpc.org/tpc_documents_current_versions/pdf/procedures_v1.0.0.pdf) and overseen by the TPC-OSS subcommittee that meets on a weekly basis and a quarterly face to face schedule.  

All pull requests are reviewed by the [HammerDB code maintenance team](https://github.com/orgs/TPC-Council/teams/hammerdb-code-maintenance-team) and all [releases](https://github.com/TPC-Council/HammerDB/releases) approved by the TPC-OSS subcommittee and the TPC.

HammerDB code is published under the [GPLv3](https://www.gnu.org/licenses/gpl-3.0.en.html) license and documentation under the [GNU Free Documentation License](https://www.gnu.org/licenses/fdl-1.3.en.html) with contributions required to adhere to or be compatible with these open source licenses.

Read our [Code of Conduct](./CODE_OF_CONDUCT.md) to keep our community approachable and respectable. 
 
In this guide you will get an overview of the contribution workflow from asking a discussion question, opening an issue, creating a PR, reviewing, and merging the PR. 
 
## Getting started 

To get an overview of the project, read the [README](README.md). 
 
The HammerDB focus provides independent and objective relational database benchmarks derived from the [TPC-C](https://www.tpc.org/tpcc/) transactional workload termed TPROC-C and [TPC-H](https://www.tpc.org/tpch/) analytic termed TPROC-H, with future development focus being towards developing a Hybrid HTAP TPROC-CH workload to which contributions are welcome.   

HammerDB provides both a GUI and CLI environment with the intention of making such database workloads easy to use and accessible both on-premise and in the cloud, thereby accelerating the dissemination of verifiable database performance data. 

HammerDB does not provide workloads dedicated to testing CPU, memory and storage independently of the database. 

A common contribution question is on extending HammerDB to support additional relational databases. Currently, HammerDB supports the most popular relational databases as defined by the [DB-Engines Ranking](https://db-engines.com/en/ranking) that run both on-premise and in the cloud and support multiple operating systems namely Oracle, MySQL, Microsoft SQL Server, PostgreSQL, IBM Db2 and MariaDB in ranking order. If considering extending HammerDB to additional databases, consideration should be given to the expected popularity and usage of such an extension and your ability and desire to provide ongoing maintenance and support. 

HammerDB is developed and supported on the Linux and Windows operating systems on the x86-64 architecture. If considering a contribution to extending HammerDB to support additional operating systems or architectures, a similar focus should be given to your willingness to give commitment to long-term development and support of such an extension.

Note that although HammerDB is developed on Linux and Windows on x86-64 it can connect to and run against a target database running on any platform supported by the database, and it is therefore an entirely reasonable contribution to add database specific enhancements for a particular platform where that differs from the default. 

The primary front-end development language of the HammerDB is [Tcl](https://www.tcl.tk/) to ensure a highly scalable GIL free multithreaded workload implementation. The back-end proportion of HammerDB is implemented in C with HammerDB providing the functionality to automatically build all C components from source on both Windows and Linux with potential for contributions by adding to and enhancing these components. 

All database interaction is implemented in SQL and stored procedures, and a front-end Python interface is provided for alternative CLI support. 
 
### Discussion Topics

Before raising Issues or submitting Pull Requests, [HammerDB Discussions](https://github.com/TPC-Council/HammerDB/discussions) is the forum for submitting general questions and answers on potential areas for code and documentation contributions, as well as general usability questions. Answering discussion questions as well as asking them is a good starting point for making a contribution to HammerDB. 

### Documentation 

HammerDB documentation is written in [Docbook format ](https://docbook.org/) meaning a potential contribution is to edit and update the documentation and submit changes via a GitHub Pull Request to the HammerDB project.

To get started, go to the HammerDB project under the Docbook directory.  Here you will find a docs.xml file containing the documentation in Docbook v5.1 standard and the images included in the HammerDB documentation. If you clone or download the project, you will already have a copy of the documentation and images that you need to start editing. There are many Docbook editors that you can use to edit the documentation, such as [XMLmind Personal Edition](https://www.xmlmind.com/) that is free to use for open source projects.  Once you have modified and saved your changes, you can submit the edited docs.xml and any new images via a Pull Request. 

### Issues 
 
HammerDB Issues fall into 2 broad categories. Bug Reports and Feature Requests. 

### Bug Reports 

A HammerDB Bug Report is submitted when something with HammerDB is not working as expected. If you spot a problem, firstly consult the [HammerDB documentation](https://www.hammerdb.com/document.html) in particular the release notes and then search [HammerDB Github Issues](https://github.com/TPC-Council/HammerDB/issues) for Issues with a Bug label to see if an existing Issue already exists. If a related issue doesn't exist, you can open a new issue using the Bug Report Issue template to provide further details to reproduce, diagnose and fix the Issue with a Pull Request. 

Once submitted, the HammerDB Code Maintenance team will assign a label to the Issue and potentially (but not always) assign the Issue to a developer. In addition to filing a Bug Report, you should consider if you can also submit the Pull Request to resolve the Issue. 

### Feature Requests

A HammerDB Feature Request is a request for new functionality and is given an enhancement label. The majority of HammerDB Issues are feature requests and may or may not receive attention by the core team. Therefore, enhancement Issues are the key area where code contributions can be made. 

Scan through our [existing issues](https://github.com/TPC-Council/HammerDB/issues) to find one that interests you and either ask a Discussion question for additional clarity or begin developing the enhancement described by the related Issue to be submitted via a Pull Request. Labels can be used to narrow down your search for Issues of interest, for example the docker related label is assigned to all related Issues for developing the Docker file and image for HammerDB. 

### Fork the repository, make and test changes locally 
 
1. Fork the repository, so that you can make your changes without affecting the original project until you're ready to merge them. 

2. Create a working branch and start making changes. Note that some functionality within HammerDB dynamically embeds multiple scripts within other scripts and does in-place editing of scripts dependent on white-space placement, and therefore caution should be given to widespread indenting of existing files without extensive testing to ensure that current functionality is not impacted. When ready, commit your changes and push them to your Fork of the HammerDB repository. 
 
5. Test your changes.  When you have made changes, you should test them to ensure compatibility remains in both Linux and Windows environments. From a local copy of your branch, build HammerDB from source using the Building HammerDB from Source guidelines in the documentation. This will build a copy of HammerDB with your changes that you can then test. 
 
### Pull Request 
 
When you're finished with the changes, create a pull request, also known as a PR. 
- Don't forget to link the PR to the Issue you are solving one and provide additional details in the related Issue if necessary. 
- Enable the checkbox to allow maintainer edits, so the branch can be updated for a merge. 
- Once you submit your PR, a HammerDB code maintenance team member will review your proposal. We may ask questions or request additional information in particular about your testing to ensure that any changes are fair to all databases, operating systems and platforms.  
- We may ask for changes to be made before a PR can be merged, using pull request comments. You can make any other changes in your fork, then commit them to your branch. These will then be automatically applied to the PR. 
- As you update your PR and apply changes, mark each conversation as resolved.
- Once your PR has been reviewed and approved by three members of the HammerDB code maintenance team, a committer will then Merge your PR. 
 
### Your PR is merged! 
 
Congratulations :tada::tada: The HammerDB team thanks you :sparkles:.  
 
Once your PR is merged, your contributions will be publicly visible on [HammerDB GitHub](https://github.com/TPC-Council/HammerDB).  
 
Now that you are part of the HammerDB community, see how else you can contribute.
