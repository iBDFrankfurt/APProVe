<div align="center">
  <h1>APProVe <sup>by iBDF</sup></h1>
</div>

APProVe is a software developed by the Interdisciplinary Biomaterials and Database Frankfurt (iBDF) for the convenient management of biosamples and clinical data in research projects. It provides researchers and iBDF employees with a clear means of handling and tracking project requests to the biobank, mapping the entire process from application submission to sample distribution and project completion.

[[_TOC_]]

<div align="center">
  <h4>A Project Proposal Management Software for Biobanks</h4>
</div>

<p align="center">
  <a href="#">
    <img src="https://gitlab.ibdf-frankfurt.de/uct/open-approve/-/raw/master/img/Project_management-APProVe_en.png" alt="Workflow" style="height: 120px; width: 120px">
  </a>
</p>

## System Requirements
- RAM: 6GB
- Multi-core processor (e.g., Intel i5)
- Hard disk space: 500 MB

## Features
APProVe is the first software to digitally and transparently map the application process and further follow-up of projects for all parties involved. The following functions have been integrated:

1. Online submission of project applications
2. User-related access/view of projects
3. Overview of all projects in which a user is involved
4. Tracking of the current project status
5. Email notification of project changes, project status, or new comments
6. Project-related communication via the comment function
7. Assignment of project-related to-dos for biobank members
8. Tabular summary of projects in tiles based on various criteria for a better overview

## Changelogs and Documentation
Each instance has its own Manual Service, containing useful information about managing and using APProVe, as well as the changelogs. If you don't have access to a running Manual Service, you can check the latest changelogs and documentation at: [Manual-Develop](https://backend.approved.ibdf-frankfurt.de/manual/updates/).

Please note that a few versions may be unreleased or still in testing and will be made public later.

## APProVe Installation
You can choose to install APProVe for testing purposes on a computer. For local installation, refer to this guide: [Local Setup](https://gitlab.ibdf-frankfurt.de/uct/open-approve/-/tree/master/complete-local-setup?ref_type=heads). If you want to install APProVe on a server environment with reverse proxying, use this guide instead: [Server Setup](https://gitlab.ibdf-frankfurt.de/uct/open-approve/-/tree/master/server-setup?ref_type=heads).

Further improvements will be based on feedback.

## Popular Documentation
For more information, visit our [iBDF Wiki](https://ibdf-frankfurt.de/wiki/Hauptseite).

## Credits
This software uses the following open-source packages:
- [Node.js](https://nodejs.org/)
- [moment.js](https://momentjs.com/)
- [jQuery.js](https://jquery.com/)
- [Bootstrap](https://getbootstrap.com/)
- [Keycloak](https://www.keycloak.org/about)

For installation guidance, please refer to the following links:
- [Docker Installation][docker]
- [Git Installation][git]

[docker]: <https://docs.docker.com/install>
[git]: <https://www.atlassian.com/git/tutorials/install-git>
