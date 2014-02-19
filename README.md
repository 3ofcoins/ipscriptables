# Ipscriptables

Ruby-driven IPTables

## Installation

Add this line to your application's Gemfile:

    gem 'ipscriptables'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install ipscriptables

## Usage

TODO: write real instructions.

Write a script a bit like this (ip6tables work too):

```ruby
iptables do
  table :nat do
    inherit(:DOCKER)
    inherit(:PREROUTING, :OUTPUT) { |rule| rule.target == 'DOCKER' }
    inherit(:POSTROUTING) { |rule| rule.target == 'MASQUERADE' }
  end

  table :filter do
    inherit(:INPUT) { |rule| rule.target == 'FWR' || rule.target == 'LXC' }
    inherit(:FORWARD) { |rule| rule[:i] == 'docker0' || rule[:o] == 'docker0' }
    inherit(:LXC)
    chain :FWR do
      rule :i => ['lo', 'docker0'], :j => 'ACCEPT'
      rule '-m state --state RELATED,ESTABLISHED -j ACCEPT'
      rule '-p icmp -j ACCEPT'
      rule '-p tcp -m tcp --dport', [22, 80, 443], '-j ACCEPT'
      rule '-p tcp -m tcp --tcp-flags SYN,RST,ACK SYN -j REJECT --reject-with icmp-port-unreachable'
      rule '-p udp -j REJECT --reject-with icmp-port-unreachable'
    end
  end
end
```

Run `ipscriptables path/to/script.rb`, review diff, run `ipscriptables
--apply path/to/script.rb`.

## Contributing

See the [CONTRIBUTING.md](CONTRIBUTING.md) file
