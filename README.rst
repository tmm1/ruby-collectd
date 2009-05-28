collectd Data Model
-------------------

Collectd groups data by *six categories:* hostname, plugin,
plugin-instance, type, type-instance, values

* *hostname* is grabbed from `hostname -f`
* *plugin* is a constant defined in Stats on the programs' side
  (application name)
* *plugin-instance* is passed from the programs' side with the
  programs instance identifier, useful if you're running the same
  script twice (PIDs are quite too random)
* *type* is the kind of data you are measuring and must be defined in
  [types.db](http://collectd.org/documentation/manpages/types.db.5.shtml)
  for collectd to understand
* *type-instance* provides further distinction and have no relation to
  other type-instances. Multiple type-instances are only rendered into
  one graph by collection3 if defined with module GenericStacked.
* *values* are one or more field names and types belonging
  together. The exact amount of fields and their corresponding names
  (useful to collection3) are specified in collectd's
  [types.db](http://collectd.org/documentation/manpages/types.db.5.shtml).

A value can be either of *two types:*

* *COUNTER* is for increasing counters where you want to plot the
  delta. Network interface traffic counters are a good example.
* *GAUGE* is values that go up and down to be plotted as-is, like a
  temperature graph.


Usage
-----

    gem 'astro-collectd'
    require 'collectd'

First of all, specify a server to send data to:

    Collectd.add_server(interval, addr='ff18::efc0:4a42', port=25826)

interval of 10 is quite reasonable. Because of UDP and some buffering
in collectd, an interval of 1 seconds shouldn't hurt either.

All the identifiers from above can be given free form with some
method_missing stuff. Like this:

    # Set gauge absolutely
    Collectd.plugin(:plugin_instance).type(:type_instance).gauge = 23
    # Increase counter relatively (collectd caches counters)
    Collectd.plugin(:plugin_instance).type(:type_instance).count! 5
    # Set counter absolutely
    Collectd.plugin(:plugin_instance).type(:type_instance).counter = 42

For convenience, define yourself a global *shortcut*, like:

    Stats = Collectd.my_zombie(RAILS_ENV)

To automatically collect *memory and CPU statistics* of your Ruby
process, do:

    Stats.with_full_proc_stats

You can also have the library *poll* for your data, if you feel
comfortable with that, eg:

    Stats.counter(:seconds_elapsed).polled_counter do
      Time.now.to_i
    end

