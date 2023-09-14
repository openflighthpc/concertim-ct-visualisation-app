# Sys scripts

A collection of (typically) PHP scripts providing very simple functionality.
These have been inherited from legacy.  They were used there as the Ruby
application servers used by legacy has poor concurrency support.  So simple,
commonaly called functionality was written in PHP to avoid having to use up the
limited concurrency of the Rails processes.

It may be the case that our current Ruby application server (Puma) has
sufficient concurrency to have these scripts ported to Ruby.  However, that
currently doesn't seem worth the effort.

For each script here, it is likely that configuration of the web server (Apache
or Nginx) is required.
