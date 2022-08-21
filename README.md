# Akkoma-Docker (Unofficial)

[Akkoma](https://akkoma.dev/) (A Pleroma fork) is a selfhosted social network that uses ActivityPub.

This repository dockerizes it for easier deployment.

This repository was heavily based on sn0w's work on [pleroma-docker](https://memleak.eu/sn0w/pleroma-docker)

#### Differences:

* Runs Akkoma instead of Pleroma
* Enviroment variable based configuration
* Autogenerating secrets
* Additional scripts
* Default frontends (pleroma-fe + admin-fe)


## Docs:

To limit the size of this document, the documentation has been split up into several different documents.<br>
A summary and link to those can be found here:

- Installation guide: A starting guide on how to use this setup [[link]](doc/INSTALLATION.md)

- Maintenance guide: Tips and Common maintenance tasks [[link]](doc/MAINTENANCE.md)

- Customization guide: How to go about customizing your setup [[link]](doc/CUSTOMIZATION.MD)


<hr>

```cpp
#include <LICENSE>

/*
 * This repository comes with ABSOLUTELY NO WARRANTY
 *
 * I will happily help you with issues related to this script,
 * but I am not responsible for burning servers, angry users, fedi drama,
 * thermonuclear war, or you getting fired because your boss saw your NSFW posts.
 *
 * Please do some research if you have any concerns about the
 * included features or software *before* using it.
 */
```

<hr>

### Attribution

Great thanks to sn0w for publishing their [pleroma-docker](https://memleak.eu/sn0w/pleroma-docker) repository on what this is based on.