# Development

Concertim Visualisation App (aka `ct-visualisation-app` or `ct-vis-app`) is one
of two apps that form the Concertim UI; the other is [metric reporting
daemon](https://github.com/alces-flight/concertim-metric-reporting-daemon).

## Vagrant machine

Development of both apps takes place on a Vagrant virtual machine, which is
provisioned with the use of an ansible playbook.  The vagrant file and the
ansible playbook can be found in the
[concertim-ansible-playbook](https://github.com/alces-flight/concertim-ansible-playbook)
repo.

That repo contains details on how to build the vagrant machine and provision it
for Concertim development.  Including expectations on where the source code
should be checked out.

## Architecture and legacy background

The code in `ct-vis-app` is highly influenced by its predecessor
[concertim-emma](https://github.com/alces-flight/concertim-emma) (aka
`ct-emma`).  There is a working assumption that much of the funtionality in
`ct-emma` will or may be ported to `concertim-visualisation-app`.  To that end,
the architecture of `ct-vis-app` has been kept deliberately similar to
`ct-emma`.  In time, we may wish for the architecture to diverge.

### Non-standard rails application folders

`ct-vis-app` makes use of non-standard rails components, such as `cells`,
`facades`, `presenters`, `services` and `utilities`.

The following READMEs are worth reading:

* [cells README](/app/cells/README.md): encapsulate view components.
* [facades README](/app/facades/README): used to provide a simpler
  interface to the use of memcache as a data interchange.  This use of memcache
  should be removed and probably the use of facades too.
* [models README](/app/models/README.md): README on model expectations.
* [presenters README](/app/presenters/README): Used to simplify view
  logic.
* [services README](/app/services/README):  Encapsulates business logic.
* [utility README](/app/utility/README):  Utility classes.

Much of the above struture was written to manage the complexity of the legacy
and old-legacy code-bases.  They are perhaps not needed in the new simpler
code-base.  They remain as having them makes it simpler to port code from
`ct-emma` as needed.  Once, we have confidence that more functionality is
unlikely to be ported from `ct-emma` it would be good to reasses whether we
need all of these.

### JavaScript

The JavaScript in `ct-vis-app` has been ported from `ct-emma` and
[concertim-mia](https://github.com/alces-flight/concertim-mia) (aka `ct-mia`).
`ct-mia` is part of old-legacy and predates the Rails asset pipeline.

The porting process 1) converted the JavaScript from CoffeeScript; 2) replaced
the legacy bundling of the JavaScript with the asset pipeline and importmaps;
and 3) removed some of old JavaScript libraries such as Prototype.

It still has the following issues:

1. Old libraries such as mootools and MochiKit still remain.  These should
   probably be replaced or at least updated to their latest versions.
2. Many JavaScript libraries have been vendored in and should be updated at
   some point.  These include jQuery, modernizr and foundation.
3. Much of the source code was automatically ported from CoffeeScript to
   JavaScript by decaffeinate.  The resulting code could do with some love as
   documented in each source file.


### CSS

The CSS is written in SCSS and processed dartsass.  The legacy CSS was written
using the [Foundation CSS framework](https://get.foundation/).  I have
attempted to port over only the styles that are being used, but have likely
included other styles too.

An old version of Foundation is in use; it should be updated at some point.  As
the styling of Concertim is significantly different from our other projects,
perhaps this should wait until we are certain that the styling is appropriate.


### ActiveJob

[GoodJob](https://github.com/bensheldon/good_job) has been seleted as the
ActiveJob backend.  It is ran in its own process.


## Starting the servers

The rails server, `dartsass` and `good_job` can all be started by running
`bin/dev`.


## Running tests

Tests are to be ran on the vagrant vm.  First SSH into the VM (`vagrant ssh dev1`)
and then change to the app directory (`cd /opt/concertim/dev/ct-visualisation-app`).

- All tests:
  ```bash
  ./bin/bundle exec rspec
  ```

- Tests grouped by "type" e.g., models (see `rails -T spec` for more details):
  ```bash
  ./bin/bundle exec rspec spec/models
  ```

- Specific tests: see `./bin/bundle exec rspec -h`


## Developing a feature

1. Select available story in Pivotal tracker.
2. Implement it with test coverage on a feature branch.
3. Create PR https://github.com/alces-flight/concertim-ct-visualisation-app/pulls.
4. Update Pivotal tracker with PR details and mark story as finished.
