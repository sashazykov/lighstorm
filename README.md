# Lighstorm

> ⚠️ Warning: Early-stage, breaking changes are expected.

API for interacting with a [Lightning Node](https://lightning.network).

![Lighstorm text written stylized with an illustration of a Graph connecting two Nodes.](https://raw.githubusercontent.com/icebaker/assets/main/lighstorm/lighstorm.png)

```ruby
Lighstorm::Channel.first.myself.node.alias
```

## Index

- [About](#about)
- [Usage](#usage)
  - [Installing](#installing)
  - [Credentials](#credentials)
  - [Documentation](#documentation)
    - [API](#api)
    - [Examples](#examples)
  - [Data Modeling](#data-modeling)
    - [Graph Theory](#graph-theory)
    - [Channel](#channel)
    - [Forward](#forward)
    - [Payment](#payment)
- [Development](#development)
  - [Publish to RubyGems](#publish-to-rubygems)

## About

_Lighstorm_ is an opinionated abstraction layer on top of the [lnd-client](https://github.com/icebaker/lnd-client).

It brings an [object-oriented](https://en.wikipedia.org/wiki/Object-oriented_programming) approach for interacting with a [Lightning Node](https://github.com/lightningnetwork/lnd), influenced by the [Active Record Pattern](https://www.martinfowler.com/eaaCatalog/activeRecord.html) and [Active Record Models](https://guides.rubyonrails.org/active_record_basics.html) conventions.

Although it tries to stay close to [Lightning's terminologies](https://docs.lightning.engineering/lightning-network-tools/lnd), it brings its own vocabulary and [data modeling](#data-modeling), optimizing for [programmer happiness](https://rubyonrails.org/doctrine).

## Usage

### Installing

Add to your `Gemfile`:

```ruby
gem 'lighstorm', '~> 0.0.1'
```

Run `bundle install`.

### Credentials

Set the following _Environment Variables_ or create a `.env` file:
```bash
LIGHSTORM_LND_ADDRESS=127.0.0.1:10009
LIGHSTORM_CERTIFICATE_PATH=/lnd/tls.cert
LIGHSTORM_MACAROON_PATH=/lnd/data/chain/bitcoin/mainnet/admin.macaroon
```

It will automatically load your credentials.

Alternatively, you can set the credentials at runtime:

```ruby
require 'lighstorm'

Lighstorm.config!(
  lnd_address: '127.0.0.1:10009',
  certificate_path: '/lnd/tls.cert',
  macaroon_path: '/lnd/data/chain/bitcoin/mainnet/admin.macaroon',
)

```

### Documentation

#### API

```ruby
Lighstorm::Node

Lighstorm::Node.myself
Lighstorm::Node.find_by_public_key(
  '02d3c80335a8ccb2ed364c06875f32240f36f7edb37d80f8dbe321b4c364b6e997'
)

node.to_h

node.channels

node.alias
node.public_key
node.color
node.myself?

node.platform.blockchain
node.platform.network
node.platform.lightning.implementation
node.platform.lightning.version

Lighstorm::Channel
Lighstorm::Channel.all
Lighstorm::Channel.first
Lighstorm::Channel.last
Lighstorm::Channel.find_by_id(850099509773795329)

channel.to_h

channel.id
channel.opened_at
channel.up_at
channel.active
channel.exposure

channel.accounting.capacity.milisatoshis
channel.accounting.sent.milisatoshis
channel.accounting.received.milisatoshis
channel.accounting.unsettled.milisatoshis

channel.partner.accounting.balance.milisatoshis
channel.partner.node.alias
channel.partner.node.public_key
channel.partner.node.color
channel.partner.policy.fee.base.milisatoshis
channel.partner.policy.fee.rate.parts_per_million

channel.myself.accounting.balance.milisatoshis
channel.myself.node.alias
channel.myself.node.public_key
channel.myself.node.color
channel.myself.policy.fee.base.milisatoshis
channel.myself.policy.fee.rate.parts_per_million

channel.myself.policy.fee.update(
  { rate: { parts_per_million: 25 } }, preview: true
)

channel.myself.policy.fee.update(
  { rate: { parts_per_million: 25 } }
)

Lighstorm::Forward
Lighstorm::Forward.all
Lighstorm::Forward.first
Lighstorm::Forward.last
Lighstorm::Forward.all(limit: 10)

forward.to_h

forward.id
forward.at

forward.fee.milisatoshis
forward.fee.parts_per_million(
  forward.in.amount.milisatoshis
)

forward.in.amount.milisatoshis

forward.in.channel.id
forward.in.channel.partner.node.alias
forward.in.channel.partner.node.public_key
forward.in.channel.partner.node.color

forward.out.channel.id
forward.out.channel.partner.node.alias
forward.out.channel.partner.node.public_key
forward.out.channel.partner.node.color

Lighstorm::Forward.group_by_channel(direction: :in, hours_ago: 24, limit: 5)

group.to_h

group.last_at
group.analysis.count
group.analysis.sums.amount.milisatoshis
group.analysis.sums.fee.milisatoshis
group.analysis.averages.amount.milisatoshis
group.analysis.averages.fee.milisatoshis
group.analysis.averages.fee.parts_per_million(
  group.analysis.averages.amount.milisatoshis
)

group.in.id
group.in.partner.node.alias
group.in.partner.node.public_key
group.in.partner.node.color

Lighstorm::Forward.group_by_channel(direction: :out)

group.to_h

group.last_at
group.analysis.count

group.out.id
group.out.partner.node.alias
group.out.partner.node.public_key
group.out.partner.node.color

Lighstorm::Payment
Lighstorm::Payment.all
Lighstorm::Payment.first
Lighstorm::Payment.last
Lighstorm::Payment.all(limit: 10, purpose: 'rebalance', hops: false)

payment.id
payment.hash
payment.created_at
payment.purpose
payment.status
payment.amount.milisatoshis
payment.fee.milisatoshis
payment.fee.parts_per_million(
  payment.amount.milisatoshis
)

payment.from.hop
payment.from.amount.milisatoshis
payment.from.fee.milisatoshis
payment.from.fee.parts_per_million(
  payment.from.amount.milisatoshis
)

payment.from.channel.id
payment.from.channel.partner.node.alias
payment.from.channel.partner.node.public_key
payment.from.channel.partner.node.color

payment.to.hop
payment.to.amount.milisatoshis
payment.to.fee.milisatoshis
payment.to.fee.parts_per_million(
  payment.to.amount.milisatoshis
)

payment.to.channel.id
payment.to.channel.partner.node.alias
payment.to.channel.partner.node.public_key
payment.to.channel.partner.node.color

payment.hops.size

payment.hops[0].hop
payment.hops[0].amount.milisatoshis
payment.hops[0].fee.milisatoshis
payment.hops[0].fee.parts_per_million(
  payment.hops[0].amount.milisatoshis
)

payment.hops[0].channel.id
payment.hops[0].channel.partner.node.alias
payment.hops[0].channel.partner.node.public_key
payment.hops[0].channel.partner.node.color

Lighstorm::Satoshis
Lighstorm::Satoshis.new(milisatoshis: 75621650)

satoshis.to_h

satoshis.milisatoshis
satoshis.satoshis
satoshis.bitcoins

satoshis.msats
satoshis.sats
satoshis.btc

reference_in_milisatoshis = 75_621_650_000
satoshis.parts_per_million(reference_in_milisatoshis)
```

#### Examples

```ruby
require 'lighstorm'

puts Lighstorm.version # => 0.0.1

Lighstorm::Satoshis.new(
  milisatoshis: 75621650
).satoshis # => 75621

Lighstorm::Node.myself.alias # => icebaker/old-stone
Lighstorm::Node.myself.public_key # => 02d3...e997

Lighstorm::Node.myself.to_h #> { ... }

Lighstorm::Node.myself.channels.count # => 5

Lighstorm::Channel.all.first.partner.node.alias

forward = Lighstorm::Forward.all(limit: 10).first

forward.in.amount.milisatoshis # => 75621650
forward.in.amount.satoshis # => 75621
forward.in.amount.bitcoins # => 0.0007562165
forward.in.channel.partner.node.alias
forward.out.channel.partner.node.alias

forward.to_h # => { ... }

payment = Lighstorm::Payment.all.first

payment.from.channel.id # => 850099509773795329
payment.to.channel.id # => 821539695188246532
payment.amount.sats # => 957262
payment.hops.size # => 4
payment.hops.first.channel.partner.node.alias
```

### Data Modeling

#### Graph Theory

[Graphs](https://en.wikipedia.org/wiki/Graph_theory) provide a great representation to abstract the [Lightning Network](https://lightning.network) data.

So, we are going to think in terms of _Edges_, _Nodes_, and _Connections_:

![This is an image describing Graphs and their terminologies.](https://raw.githubusercontent.com/icebaker/assets/main/lighstorm/graph-theory.png)

#### Channel

```ruby
channel = Lighstorm::Channel.first

channel.id

channel.accounting.capacity.milisatoshis

channel.partner.accounting.balance.milisatoshis
channel.partner.node.alias
channel.partner.policy.fee.rate.parts_per_million

channel.myself.accounting.balance.milisatoshis
channel.myself.node.alias
channel.myself.policy.fee.rate.parts_per_million
```

![This is an image representing Channel as a graph.](https://raw.githubusercontent.com/icebaker/assets/main/lighstorm/graph-channel.png)

#### Forward

```ruby
forward = Lighstorm::Forward.last

forward.at

forward.fee.parts_per_million

forward.in.amount.milisatoshis

forward.in.channel.id
forward.in.channel.partner.node.alias

forward.out.channel.id
forward.out.channel.partner.node.alias
```

![This is an image representing Forward as a graph.](https://raw.githubusercontent.com/icebaker/assets/main/lighstorm/graph-forward.png)

#### Payment

```ruby
payment = Payment.last

payment.hash
payment.amount.milisatoshis

payment.from.hop
payment.from.amount.milisatoshis
payment.from.fee.milisatoshis
payment.from.channel.id
payment.from.channel.partner.node.alias

payment.to.hop
payment.to.amount.milisatoshis
payment.to.fee.milisatoshis
payment.to.channel.id
payment.to.channel.partner.node.alias

payment.hops[0].hop
payment.hops[0].amount.milisatoshis
payment.hops[0].fee.milisatoshis
payment.hops[0].channel.id
payment.hops[0].channel.partner.node.alias
```

![This is an image representing Payment as a graph.](https://raw.githubusercontent.com/icebaker/assets/main/lighstorm/graph-payment.png)

## Development

```ruby
# Gemfile
gem 'lighstorm', path: '/home/user/lighstorm'

# demo.rb
require 'lighstorm'

puts Lighstorm.version # => 0.0.1
```

```sh
bundle
rubocop -A
```

### Publish to RubyGems

```sh
gem build lighstorm.gemspec

gem signin

gem push lighstorm-0.0.1.gem
```
