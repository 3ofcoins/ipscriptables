The IPScriptables Cookbook
==========================

This cookbook installs
[IPScriptables](https://github.com/3ofcoins/ipscriptables/) as a Chef
gem and adds an `ipscriptables` call to recipe DSL to easily configure
your firewall.

Usage
-----

Add `ipscriptables` cookbook to your cookbook's dependencies (or
`recipe[ipscriptables::load]`, or (currently empty)
`recipe[ipscriptables]` to your run list). Then, in recipe code, you
can use following call:

```ruby
ipscriptables do
  # …IPScriptables DSL…
end
```

If you need low-level access to an underlying resource, you can call
it directly and add some layers of syntactic cruft:

```ruby
ipscriptables_rules "useless name" do
  rules do
    # …IPScriptables DSL…
  end
end
```

The LWRP does not execute the rules as it goes, but evaluates them at
converge time in a single IPScriptables runtime (like one
IPScriptables CLI call evaluating multiple files). It installs
a report handler that, at the end of a successful Chef run, applies
the rules (in whyrun mode it's a dry run).

Attributes
----------

 - `node['ipscriptables']['gem_version']` (default: `"latest"`) --
   version of the IPScriptables gem to install. If left as *latest*,
   the gem is upgraded to newest available version (`:upgrade`
   action). If set to `nil` or `false`, the gem is `:install`ed at
   newest version, but not upgraded if it has already been installed.

Outstanding Issues
------------------

 - [ ] The cookbook should install init script and save rules to be
   applied on reboot.
