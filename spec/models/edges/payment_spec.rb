# frozen_string_literal: true

require 'json'

require_relative '../../../controllers/payment/all'

require_relative '../../../models/edges/payment'
require_relative '../../../models/satoshis'

require_relative '../../../ports/dsl/lighstorm/errors'

RSpec.describe Lighstorm::Models::Payment do
  describe 'all' do
    let(:data) do
      Lighstorm::Controllers::Payment::All.data do |fetch|
        VCR.tape.replay("Controllers::Payment.all/#{secret_hash}") do
          data = fetch.call
          data[:list_payments] = [
            data[:list_payments].find { |payment| payment[:payment_hash] == secret_hash }
          ]
          data
        end
      end
    end

    let(:payment) { described_class.new(data[:data][0]) }

    context 'no invoice' do
      let(:fetch_options) do
        {
          get_node_info: false,
          lookup_invoice: false,
          decode_pay_req: false,
          get_chan_info: false
        }
      end

      let(:data) do
        Lighstorm::Controllers::Payment::All.data(fetch: fetch_options) do |fetch|
          VCR.tape.replay("Controllers::Payment.all/#{secret_hash}", fetch: fetch_options) do
            data = fetch.call
            data[:list_payments] = [
              data[:list_payments].find { |payment| payment[:payment_hash] == secret_hash }
            ]
            data
          end
        end
      end

      let(:secret_hash) { '8e798fbcca7baccab5029f70717fea13d86de2534ab8c7669472813b8da3da16' }

      let(:from) do
        { channel: '850181973150531585', target: nil, exit: nil }
      end

      let(:to) do
        { channel: '850181973150531585', target: 'icebaker/old-stone', entry: nil }
      end

      let(:amount) do
        Lighstorm::Models::Satoshis.new(millisatoshis: 1000)
      end

      let(:to_h_contract) { '6dcda9e6ac664ea873f8072c8176f2a2f6ad0befb279dcd82ce050a04b95cf2e' }

      it 'models' do
        expect(data[:meta][:calls][:decode_pay_req]).to be_nil
        expect(data[:meta][:calls][:get_chan_info]).to be_nil
        expect(data[:meta][:calls][:get_node_info]).to be_nil
        expect(data[:meta][:calls][:list_channels]).to be_nil
        expect(data[:meta][:calls][:lookup_invoice]).to be_nil

        expect(payment._key.size).to eq(64)

        expect(payment.status).to eq('succeeded')
        expect(payment.created_at).to be_a(Time)
        expect(payment.created_at.utc.to_s).to eq('2023-02-13 23:45:51 UTC')
        expect(payment.settled_at).to be_a(Time)
        expect(payment.settled_at.utc.to_s).to eq('2023-02-13 23:45:59 UTC')
        expect(payment.purpose).to eq('self-payment')
        expect(payment.fee.millisatoshis).to eq(0)
        expect(payment.fee.satoshis).to eq(0.0)

        expect(payment.request._key.size).to eq(64)

        expect(payment.request.code).to eq('lnbc10n1p374ja0pp53eucl0x20wkv4dgznac8zll2z0vxmcjnf2uvwe55w2qnhrdrmgtqdq0gd5x7cm0d3shgegcqzpgxqyz5vqsp5s5e5gfehafdhx0wvfle05qhhfkuhp0xdj3lwlv8k8tv4m8jrmj4q9qyyssqqr2575r8c4hthdkhgkyj2a6ttvpa35umndlfzncz8mtkxwcvfcj97shyeh88t8yjdeaaj5ah9f9z2qleq8jrn5u63ap2qkrpyg8w4lqqh8med5')
        expect(payment.request.amount.millisatoshis).to eq(amount.millisatoshis)
        expect(payment.request.amount.satoshis).to eq(amount.satoshis)
        expect(payment.request.secret.preimage.class).to eq(String)
        expect(payment.request.secret.preimage.size).to eq(64)
        expect(payment.request.secret.hash).to eq('8e798fbcca7baccab5029f70717fea13d86de2534ab8c7669472813b8da3da16')
        expect(payment.request.address.class).to eq(String)
        expect(payment.request.address.size).to eq(64)
        expect(payment.request.description.memo).to be_nil
        expect(payment.request.description.hash).to be_nil

        expect(payment.hops.size).to eq(2)

        expect(payment.from.first?).to be(true)
        expect(payment.from.last?).to be(false)
        expect(payment.from.hop).to eq(1)
        expect(payment.from.amount.millisatoshis).to eq(amount.millisatoshis)
        expect(payment.from.amount.satoshis).to eq(amount.satoshis)
        expect(payment.from.fee.millisatoshis).to eq(0)
        expect(payment.from.fee.satoshis).to eq(0)
        expect(payment.from.channel._key.size).to eq(64)
        expect(payment.from.channel.id).to eq(from[:channel])
        expect(payment.from.channel.target.alias).to eq(from[:target])
        expect(payment.from.channel.target.public_key.size).to eq(66)
        expect(payment.from.channel.target._key.size).to eq(64)

        expect(payment.hops[0].channel.id).to eq(from[:channel])

        expect(payment.from.channel.exit.alias).to eq(from[:exit])
        expect(payment.from.channel.exit.public_key.size).to eq(66)
        expect(payment.from.channel.exit._key.size).to eq(64)
        expect(payment.from.channel.entry).to be_nil

        expect(payment.to.first?).to be(false)
        expect(payment.to.last?).to be(true)
        expect(payment.to.hop).to eq(2)
        expect(payment.to.amount.millisatoshis).to eq(amount.millisatoshis)
        expect(payment.to.amount.satoshis).to eq(amount.satoshis)
        expect(payment.to.fee.millisatoshis).to eq(0)
        expect(payment.to.fee.satoshis).to eq(0)
        expect(payment.to.channel._key.size).to eq(64)
        expect(payment.to.channel.id).to eq(to[:channel])
        expect(payment.to.channel.target.alias).to eq(to[:target])
        expect(payment.to.channel.target.public_key.size).to eq(66)
        expect(payment.to.channel.target._key.size).to eq(64)

        expect(payment.hops[1].channel.id).to eq(to[:channel])

        expect(payment.to.channel.entry.alias).to eq(to[:entry])
        expect(payment.to.channel.entry.public_key.size).to eq(66)
        expect(payment.to.channel.entry._key.size).to eq(64)

        expect(payment.to.channel.exit).to be_nil

        Contract.expect(payment.to_h, to_h_contract) do |actual, expected|
          expect(actual.hash).to eq(expected.hash)
          expect(actual.contract).to eq(expected.contract)
        end
      end
    end

    context 'self-payment' do
      let(:secret_hash) { '8e798fbcca7baccab5029f70717fea13d86de2534ab8c7669472813b8da3da16' }

      let(:from) do
        { channel: '850181973150531585', target: 'icebaker/old-stone', exit: 'BCash_Is_Trash' }
      end

      let(:to) do
        { channel: '850181973150531585', target: 'icebaker/old-stone', entry: 'BCash_Is_Trash' }
      end

      let(:amount) do
        Lighstorm::Models::Satoshis.new(millisatoshis: 1000)
      end

      let(:to_h_contract) { '8a70db00b67dfbb7957833de0caf6db2d1b77a53b9e672b4df0537e06f3b4cd7' }

      it 'models' do
        expect(data[:meta][:calls].keys).to eq(
          %i[fee_report decode_pay_req lookup_invoice get_chan_info get_node_info list_channels]
        )

        expect(payment._key.size).to eq(64)

        expect(payment.status).to eq('succeeded')
        expect(payment.created_at).to be_a(Time)
        expect(payment.created_at.utc.to_s).to eq('2023-02-13 23:45:51 UTC')
        expect(payment.settled_at).to be_a(Time)
        expect(payment.settled_at.utc.to_s).to eq('2023-02-13 23:45:59 UTC')
        expect(payment.purpose).to eq('self-payment')
        expect(payment.fee.millisatoshis).to eq(0)
        expect(payment.fee.satoshis).to eq(0.0)

        expect(payment.request._key.size).to eq(64)
        expect(payment.request.code).to eq('lnbc10n1p374ja0pp53eucl0x20wkv4dgznac8zll2z0vxmcjnf2uvwe55w2qnhrdrmgtqdq0gd5x7cm0d3shgegcqzpgxqyz5vqsp5s5e5gfehafdhx0wvfle05qhhfkuhp0xdj3lwlv8k8tv4m8jrmj4q9qyyssqqr2575r8c4hthdkhgkyj2a6ttvpa35umndlfzncz8mtkxwcvfcj97shyeh88t8yjdeaaj5ah9f9z2qleq8jrn5u63ap2qkrpyg8w4lqqh8med5')
        expect(payment.request.amount.millisatoshis).to eq(amount.millisatoshis)
        expect(payment.request.amount.satoshis).to eq(amount.satoshis)
        expect(payment.request.secret.preimage.class).to eq(String)
        expect(payment.request.secret.preimage.size).to eq(64)
        expect(payment.request.secret.hash).to eq(secret_hash)
        expect(payment.request.address.class).to eq(String)
        expect(payment.request.address.size).to eq(64)
        expect(payment.request.description.memo).to eq('Chocolate')
        expect(payment.request.description.hash).to be_nil

        expect(payment.hops.size).to eq(2)

        expect(payment.from.first?).to be(true)
        expect(payment.from.last?).to be(false)
        expect(payment.from.hop).to eq(1)
        expect(payment.from.amount.millisatoshis).to eq(amount.millisatoshis)
        expect(payment.from.amount.satoshis).to eq(amount.satoshis)
        expect(payment.from.fee.millisatoshis).to eq(0)
        expect(payment.from.fee.satoshis).to eq(0)
        expect(payment.from.channel._key.size).to eq(64)
        expect(payment.from.channel.id).to eq(from[:channel])
        expect(payment.from.channel.target.alias).to eq(from[:target])
        expect(payment.from.channel.target.public_key.size).to eq(66)
        expect(payment.from.channel.target._key.size).to eq(64)

        expect(payment.hops[0].channel.id).to eq(from[:channel])

        expect(payment.from.channel.exit.alias).to eq(from[:exit])
        expect(payment.from.channel.exit.public_key.size).to eq(66)
        expect(payment.from.channel.exit._key.size).to eq(64)
        expect(payment.from.channel.entry).to be_nil

        expect(payment.to.first?).to be(false)
        expect(payment.to.last?).to be(true)
        expect(payment.to.hop).to eq(2)
        expect(payment.to.amount.millisatoshis).to eq(amount.millisatoshis)
        expect(payment.to.amount.satoshis).to eq(amount.satoshis)
        expect(payment.to.fee.millisatoshis).to eq(0)
        expect(payment.to.fee.satoshis).to eq(0)
        expect(payment.to.channel._key.size).to eq(64)
        expect(payment.to.channel.id).to eq(to[:channel])
        expect(payment.to.channel.target.alias).to eq(to[:target])
        expect(payment.to.channel.target.public_key.size).to eq(66)
        expect(payment.to.channel.target._key.size).to eq(64)

        expect(payment.hops[1].channel.id).to eq(to[:channel])

        expect(payment.to.channel.entry.alias).to eq(to[:entry])
        expect(payment.to.channel.entry.public_key.size).to eq(66)
        expect(payment.to.channel.entry._key.size).to eq(64)

        expect(payment.to.channel.exit).to be_nil

        Contract.expect(payment.to_h, to_h_contract) do |actual, expected|
          expect(actual.hash).to eq(expected.hash)
          expect(actual.contract).to eq(expected.contract)
        end
      end
    end

    context 'payment' do
      let(:secret_hash) { '9b674ed7ebe54c5395f9e1f7ccb51f4bf9931e5c308e1e1fd25c3195be565d16' }

      let(:from) do
        { channel: '850111604344029185', target: 'deezy.io ⚡✨', exit: 'deezy.io ⚡✨' }
      end

      let(:to) do
        { channel: '825908054838018049', target: 'yalls.org yalls-tor', entry: nil }
      end

      let(:amount) do
        Lighstorm::Models::Satoshis.new(millisatoshis: 150_000)
      end

      let(:to_h_contract) { 'ab8d440c7f84cffe16bbf7ca7b64decb4505f74f84b035243552cdd77efc718d' }

      it 'models' do
        expect(payment._key.size).to eq(64)
        expect(payment.status).to eq('succeeded')
        expect(payment.created_at).to be_a(Time)
        expect(payment.created_at.utc.to_s).to eq('2023-01-25 17:16:07 UTC')
        expect(payment.settled_at).to be_a(Time)
        expect(payment.settled_at.utc.to_s).to eq('2023-01-25 17:16:10 UTC')
        expect(payment.purpose).to eq('payment')
        expect(payment.fee.millisatoshis).to eq(0)
        expect(payment.fee.satoshis).to eq(0.0)

        expect(payment.request._key.size).to eq(64)
        expect(payment.request.code).to eq('lnbc1500n1p3azc70pp5ndn5a4ltu4x9890eu8muedglf0uex8juxz8pu87jtscet0jkt5tqdpa2fjkzep6ypyx7aeqw3hjqatnv5syyctvv9hxxe20vefkzar0wd5xjueqw3hjqcqzysxqr23ssp555e7ddtclkjy9skq2a78gaa0ydt3y6a8dctrzxxls754jqwa2k5s9qyyssqh6t6rzzstjy8dd0n8anjh89jlelkvvtm3nfupj6tt8cm9aww9228hqefagz70mcp995v30hd07g3yklhzl560y64zyzpfyymmxjr6zqpd88jh3')
        expect(payment.request.amount.millisatoshis).to eq(amount.millisatoshis)
        expect(payment.request.amount.satoshis).to eq(amount.satoshis)
        expect(payment.request.secret.preimage.class).to eq(String)
        expect(payment.request.secret.preimage.size).to eq(64)
        expect(payment.request.secret.hash).to eq(secret_hash)
        expect(payment.request.address.class).to eq(String)
        expect(payment.request.address.size).to eq(64)
        expect(payment.request.description.memo).to eq('Read: How to use BalanceOfSatoshis to ')
        expect(payment.request.description.hash).to be_nil

        expect(payment.hops.size).to eq(2)

        expect(payment.from.first?).to be(true)
        expect(payment.from.last?).to be(false)
        expect(payment.from.hop).to eq(1)
        expect(payment.from.amount.millisatoshis).to eq(amount.millisatoshis)
        expect(payment.from.amount.satoshis).to eq(amount.satoshis)
        expect(payment.from.fee.millisatoshis).to eq(0)
        expect(payment.from.fee.satoshis).to eq(0)
        expect(payment.from.channel._key.size).to eq(64)
        expect(payment.from.channel.id).to eq(from[:channel])
        expect(payment.from.channel.target.alias).to eq(from[:target])
        expect(payment.from.channel.target.public_key.size).to eq(66)
        expect(payment.from.channel.target._key.size).to eq(64)

        expect(payment.hops[0].channel.id).to eq(from[:channel])

        expect(payment.from.channel.exit.alias).to eq(from[:exit])
        expect(payment.from.channel.exit.public_key.size).to eq(66)
        expect(payment.from.channel.exit._key.size).to eq(64)
        expect(payment.from.channel.entry).to be_nil

        expect(payment.to.first?).to be(false)
        expect(payment.to.last?).to be(true)
        expect(payment.to.hop).to eq(2)
        expect(payment.to.amount.millisatoshis).to eq(amount.millisatoshis)
        expect(payment.to.amount.satoshis).to eq(amount.satoshis)
        expect(payment.to.fee.millisatoshis).to eq(0)
        expect(payment.to.fee.satoshis).to eq(0)
        expect(payment.to.channel._key.size).to eq(64)
        expect(payment.to.channel.id).to eq(to[:channel])
        expect(payment.to.channel.target.alias).to eq(to[:target])
        expect(payment.to.channel.target.public_key.size).to eq(66)
        expect(payment.to.channel.target._key.size).to eq(64)

        expect(payment.hops[1].channel.id).to eq(to[:channel])

        expect(payment.to.channel.entry).to be_nil
        expect(payment.to.channel.exit).to be_nil

        Contract.expect(payment.to_h, to_h_contract) do |actual, expected|
          expect(actual.hash).to eq(expected.hash)
          expect(actual.contract).to eq(expected.contract)
        end
      end
    end

    context 'p2p' do
      let(:secret_hash) { 'b0c63d4ac56e17818c68d516357629351b35df4ec5605495659a200c184801ed' }

      let(:from) do
        { channel: '850111604344029185', target: 'deezy.io ⚡✨', exit: 'deezy.io ⚡✨' }
      end

      let(:to) do
        { channel: '850111604344029185', target: 'deezy.io ⚡✨', entry: nil }
      end

      let(:amount) do
        Lighstorm::Models::Satoshis.new(millisatoshis: 3_050_000_000)
      end

      let(:to_h_contract) { '4e5d1fcf0fea6cabb1a17185cad0135f0871a07162a6b45dd88ea301b58b9482' }

      it 'models' do
        expect(payment._key.size).to eq(64)
        expect(payment.status).to eq('succeeded')
        expect(payment.created_at).to be_a(Time)
        expect(payment.created_at.utc.to_s).to eq('2023-01-23 11:05:45 UTC')
        expect(payment.settled_at).to be_a(Time)
        expect(payment.settled_at.utc.to_s).to eq('2023-01-23 11:05:47 UTC')
        expect(payment.purpose).to eq('peer-to-peer')
        expect(payment.fee.millisatoshis).to eq(0)
        expect(payment.fee.satoshis).to eq(0.0)

        expect(payment.request._key.size).to eq(64)
        expect(payment.request.code).to eq('lnbc30500u1p3uu6sppp5krrr6jk9dctcrrrg65tr2a3fx5dnth6wc4s9f9t9ngsqcxzgq8ksdycd9nzqurpd9jzqer9v4a8jgrhd9kxcgrnv4hxggpnxq6r2wpexvs8xct5wvsxzapqxys8xct5wvhhvc3qw3hjqcnrx9chq7tevdcnxvmcw9j85mtcd3skuvmwxv6k66psx4c8xutwwdcr26r3xvmxuarecqzpgxqyp2xqsp54dvval2wjxz4rwql30rvn5yf5vxe53upnnwchjh7dwhh5hvp27hs9qyyssq6z6ue9f37g6vf3unf82tmmln9e4pc5nxs2sxk9gjhshgrv23rn2z3ku0vq25gy5gwce7q85h7405zt69k3aqxxuyfhd638hd7tjk65gqpm0t56')
        expect(payment.request.amount.millisatoshis).to eq(amount.millisatoshis)
        expect(payment.request.amount.satoshis).to eq(amount.satoshis)
        expect(payment.request.secret.preimage.class).to eq(String)
        expect(payment.request.secret.preimage.size).to eq(64)
        expect(payment.request.secret.hash).to eq(secret_hash)
        expect(payment.request.address.class).to eq(String)
        expect(payment.request.address.size).to eq(64)
        expect(payment.request.description.memo).to eq('if paid deezy will send 3045893 sats at 1 sats/vb to bc1qpyycq33xqdzmxlan3n35mh05psqnsp5hq36nty')
        expect(payment.request.description.hash).to be_nil

        expect(payment.hops.size).to eq(1)

        expect(payment.from.first?).to be(true)
        expect(payment.from.last?).to be(true)
        expect(payment.from.hop).to eq(1)
        expect(payment.from.amount.millisatoshis).to eq(amount.millisatoshis)
        expect(payment.from.amount.satoshis).to eq(amount.satoshis)
        expect(payment.from.fee.millisatoshis).to eq(0)
        expect(payment.from.fee.satoshis).to eq(0)
        expect(payment.from.channel._key.size).to eq(64)
        expect(payment.from.channel.id).to eq(from[:channel])
        expect(payment.from.channel.target.alias).to eq(from[:target])
        expect(payment.from.channel.target.public_key.size).to eq(66)
        expect(payment.from.channel.target._key.size).to eq(64)

        expect(payment.hops[0].channel.id).to eq(from[:channel])

        expect(payment.from.channel.exit.alias).to eq(from[:exit])
        expect(payment.from.channel.exit.public_key.size).to eq(66)
        expect(payment.from.channel.exit._key.size).to eq(64)
        expect(payment.from.channel.entry).to be_nil

        expect(payment.to.first?).to be(true)
        expect(payment.to.last?).to be(true)
        expect(payment.to.hop).to eq(1)
        expect(payment.to.amount.millisatoshis).to eq(amount.millisatoshis)
        expect(payment.to.amount.satoshis).to eq(amount.satoshis)
        expect(payment.to.fee.millisatoshis).to eq(0)
        expect(payment.to.fee.satoshis).to eq(0)
        expect(payment.to.channel._key.size).to eq(64)
        expect(payment.to.channel.id).to eq(to[:channel])
        expect(payment.to.channel.target.alias).to eq(to[:target])
        expect(payment.to.channel.target.public_key.size).to eq(66)
        expect(payment.to.channel.target._key.size).to eq(64)

        expect(payment.to.channel.entry).to be_nil

        expect(payment.to.channel.exit.alias).to eq(from[:exit])
        expect(payment.to.channel.exit.public_key.size).to eq(66)
        expect(payment.to.channel.exit._key.size).to eq(64)

        Contract.expect(payment.to_h, to_h_contract) do |actual, expected|
          expect(actual.hash).to eq(expected.hash)
          expect(actual.contract).to eq(expected.contract)
        end
      end
    end

    context 'rebalance' do
      let(:secret_hash) { '697173cd5d0b97e6b047d37f30b8c96abbfab943880f606aedb2ab7b319cb7ec' }

      let(:from) do
        { channel: '850111604344029185', target: 'deezy.io ⚡✨', exit: 'deezy.io ⚡✨' }
      end

      let(:to) do
        { channel: '848916435345801217', target: 'icebaker/old-stone', entry: 'WalletOfSatoshi.com' }
      end

      let(:amount) do
        Lighstorm::Models::Satoshis.new(millisatoshis: 137_000)
      end

      let(:to_h_contract) { '5e363ce5f831457f586ca1acfb6b014c92c58980297f2a94aa92bd2a4f3afd48' }

      it 'models' do
        expect(payment._key.size).to eq(64)
        expect(payment.status).to eq('succeeded')
        expect(payment.created_at).to be_a(Time)
        expect(payment.created_at.utc.to_s).to eq('2023-02-03 01:49:13 UTC')
        expect(payment.settled_at).to be_a(Time)
        expect(payment.settled_at.utc.to_s).to eq('2023-02-03 01:49:18 UTC')
        expect(payment.purpose).to eq('rebalance')
        expect(payment.fee.millisatoshis).to eq(193)
        expect(payment.fee.satoshis).to eq(0.193)

        expect(payment.request._key.size).to eq(64)
        expect(payment.request.code).to eq('lnbc1370n1p3ac6qcpp5d9ch8n2apwt7dvz86dlnpwxfd2al4w2r3q8kq6hdk24hkvvuklkqdzv2fjkyctvv9hxxefqdanzqcmgv9hxuetvypmkjargypy5ggpcxsurjvfkxsen2ve5x5urqvfjxymscqzpgxqyz5vqsp5fnl94jxqsq655um4vhfjfn7sera70xc6mun3yastxf5u5jjju9gs9qyyssq0vl5dddf2x9avcr6nfj85qtl2nc854cx7ncwhp4cmdzqtqy7xqgxsukxgyw0ga0z9rf24sf9qmtjjplwuhqshq90n92tk9zkwrkkdaqpf3dhlz')
        expect(payment.request.amount.millisatoshis).to eq(amount.millisatoshis)
        expect(payment.request.amount.satoshis).to eq(amount.satoshis)
        expect(payment.request.secret.preimage.class).to eq(String)
        expect(payment.request.secret.preimage.size).to eq(64)
        expect(payment.request.secret.hash).to eq(secret_hash)
        expect(payment.request.address.class).to eq(String)
        expect(payment.request.address.size).to eq(64)
        expect(payment.request.description.memo).to eq('Rebalance of channel with ID 848916435345801217')
        expect(payment.request.description.hash).to be_nil

        expect(payment.hops.size).to eq(3)

        expect(payment.from.first?).to be(true)
        expect(payment.from.last?).to be(false)
        expect(payment.from.hop).to eq(1)
        expect(payment.from.amount.millisatoshis).to eq(137_041)
        expect(payment.from.amount.satoshis).to eq(137.041)
        expect(payment.from.fee.millisatoshis).to eq(152)
        expect(payment.from.fee.satoshis).to eq(0.152)
        expect(payment.from.channel._key.size).to eq(64)
        expect(payment.from.channel.id).to eq(from[:channel])
        expect(payment.from.channel.target.alias).to eq(from[:target])
        expect(payment.from.channel.target.public_key.size).to eq(66)
        expect(payment.from.channel.target._key.size).to eq(64)

        expect(payment.hops[0].channel.id).to eq(from[:channel])

        expect(payment.from.channel.exit.alias).to eq(from[:exit])
        expect(payment.from.channel.exit.public_key.size).to eq(66)
        expect(payment.from.channel.exit._key.size).to eq(64)
        expect(payment.from.channel.entry).to be_nil

        expect(payment.to.first?).to be(false)
        expect(payment.to.last?).to be(true)
        expect(payment.to.hop).to eq(3)
        expect(payment.to.amount.millisatoshis).to eq(amount.millisatoshis)
        expect(payment.to.amount.satoshis).to eq(amount.satoshis)
        expect(payment.to.fee.millisatoshis).to eq(0)
        expect(payment.to.fee.satoshis).to eq(0)
        expect(payment.to.channel._key.size).to eq(64)
        expect(payment.to.channel.id).to eq(to[:channel])
        expect(payment.to.channel.target.alias).to eq(to[:target])
        expect(payment.to.channel.target.public_key.size).to eq(66)
        expect(payment.to.channel.target._key.size).to eq(64)

        expect(payment.hops[2].channel.id).to eq(to[:channel])

        expect(payment.hops[1].channel.target.alias).to eq(to[:entry])

        expect(payment.to.channel.entry.alias).to eq(to[:entry])
        expect(payment.to.channel.entry.public_key.size).to eq(66)
        expect(payment.to.channel.entry._key.size).to eq(64)

        expect(payment.to.channel.exit).to be_nil

        Contract.expect(payment.to_h, to_h_contract) do |actual, expected|
          expect(actual.hash).to eq(expected.hash)
          expect(actual.contract).to eq(expected.contract)
        end
      end
    end

    context 'rebalance lost channel' do
      let(:secret_hash) { 'b116147b08e782b27be196811c6e56327a2728dcb4b95a94877e827cc48ba886' }

      let(:from) do
        { channel: '848962614654730241', target: 'BCash_Is_Trash', exit: 'BCash_Is_Trash' }
      end

      let(:to) do
        { channel: '848932927837175809', target: 'icebaker/old-stone', entry: 'deezy.io ⚡✨' }
      end

      let(:amount) do
        Lighstorm::Models::Satoshis.new(millisatoshis: 130_000_000)
      end

      let(:to_h_contract) { '15931cdb19a4c1aab740a5c84433d64eb0c17262716be334c6cbca05db863a24' }

      it 'models' do
        expect(payment._key.size).to eq(64)
        expect(payment.status).to eq('succeeded')
        expect(payment.created_at).to be_a(Time)
        expect(payment.created_at.utc.to_s).to eq('2023-01-15 22:47:51 UTC')
        expect(payment.settled_at).to be_a(Time)
        expect(payment.settled_at.utc.to_s).to eq('2023-01-15 22:48:01 UTC')
        expect(payment.purpose).to eq('rebalance')
        expect(payment.fee.millisatoshis).to eq(260)
        expect(payment.fee.satoshis).to eq(0.26)

        expect(payment.request._key.size).to eq(64)
        expect(payment.request.code).to eq('lnbc1300u1p3ufq5hpp5kytpg7cgu7pty7lpj6q3cmjkxfazw2xukju449y806p8e3yt4zrqdqqcqzpgxqzfvsp5p3r4jgfdthngnjcmupzxfjeff4zhlkqcj6ycxjc9j3xdj88jttaq9qyyssqvj5t0t6w3rt29yfjrdpqc62u4mjvt2fdz8x55tesw50wvadtj5lse6vkmj8r4r3khj4tlwlykz7n5k5fvgdj6qz3e9xghn4e4he5tpsplg3nqj')
        expect(payment.request.amount.millisatoshis).to eq(amount.millisatoshis)
        expect(payment.request.amount.satoshis).to eq(amount.satoshis)
        expect(payment.request.secret.preimage.class).to eq(String)
        expect(payment.request.secret.preimage.size).to eq(64)
        expect(payment.request.secret.hash).to eq(secret_hash)
        expect(payment.request.address.class).to eq(String)
        expect(payment.request.address.size).to eq(64)
        expect(payment.request.description.memo).to eq('')
        expect(payment.request.description.hash).to be_nil

        expect(payment.hops.size).to eq(4)

        expect(payment.from.first?).to be(true)
        expect(payment.from.last?).to be(false)
        expect(payment.from.hop).to eq(1)
        expect(payment.from.amount.millisatoshis).to eq(amount.millisatoshis)
        expect(payment.from.amount.satoshis).to eq(amount.satoshis)
        expect(payment.from.fee.millisatoshis).to eq(260)
        expect(payment.from.fee.satoshis).to eq(0.26)
        expect(payment.from.channel._key.size).to eq(64)
        expect(payment.from.channel.id).to eq(from[:channel])
        expect(payment.from.channel.target.alias).to eq(from[:target])
        expect(payment.from.channel.target.public_key.size).to eq(66)
        expect(payment.from.channel.target._key.size).to eq(64)

        expect(payment.hops[0].channel.id).to eq(from[:channel])

        expect(payment.from.channel.exit.alias).to eq(from[:exit])
        expect(payment.from.channel.exit.public_key.size).to eq(66)
        expect(payment.from.channel.exit._key.size).to eq(64)
        expect(payment.from.channel.entry).to be_nil

        expect(payment.to.first?).to be(false)
        expect(payment.to.last?).to be(true)
        expect(payment.to.hop).to eq(4)
        expect(payment.to.amount.millisatoshis).to eq(amount.millisatoshis)
        expect(payment.to.amount.satoshis).to eq(amount.satoshis)
        expect(payment.to.fee.millisatoshis).to eq(0)
        expect(payment.to.fee.satoshis).to eq(0)
        expect(payment.to.channel._key.size).to eq(64)
        expect(payment.to.channel.id).to eq(to[:channel])
        expect(payment.to.channel.target.alias).to eq(to[:target])
        expect(payment.to.channel.target.public_key.size).to eq(66)
        expect(payment.to.channel.target._key.size).to eq(64)

        expect(payment.hops[3].channel.id).to eq(to[:channel])

        expect(payment.to.channel.entry.alias).to eq(to[:entry])
        expect(payment.to.channel.entry.public_key.size).to eq(66)
        expect(payment.to.channel.entry._key.size).to eq(64)

        expect(payment.to.channel.exit).to be_nil

        Contract.expect(payment.to_h, to_h_contract) do |actual, expected|
          expect(actual.hash).to eq(expected.hash)
          expect(actual.contract).to eq(expected.contract)
        end
      end
    end
  end
end
