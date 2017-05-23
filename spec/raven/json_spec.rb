# Raven sometimes has to deal with some weird JSON. This makes sure whatever
# JSON impl we use handles it in the way that we expect.

require 'spec_helper'

describe JSON do
  data = [
    OpenStruct.new(:key => 'foo', :val => 'bar', :enc_key => '"foo"', :enc_val => '"bar"'),
    OpenStruct.new(:key => :foo, :val => :bar, :enc_key => '"foo"', :enc_val => '"bar"'),
    OpenStruct.new(:key => 1, :val => 1, :enc_key => '"1"', :enc_val => '1')
  ]

  data.each do |obj|
    it "works with #{obj.key.class} keys" do
      expect(JSON.dump(obj.key => 'bar')).to eq "{#{obj.enc_key}:\"bar\"}"
    end

    it "works with #{obj.val.class} values" do
      expect(JSON.dump('bar' => obj.val)).to eq "{\"bar\":#{obj.enc_val}}"
    end

    it "works with an array of #{obj.val.class}s" do
      expect(JSON.dump('bar' => [obj.val])).to eq "{\"bar\":[#{obj.enc_val}]}"
    end

    it "works with a hash of #{obj.val.class}s" do
      expect(JSON.dump('bar' => { obj.key => obj.val })).to eq "{\"bar\":{#{obj.enc_key}:#{obj.enc_val}}}"
    end
  end

  it 'encodes anything that responds to to_s' do
    data = [
      :symbol,
      1 / 0.0,
      0 / 0.0
    ]
    expect(JSON.dump(data)).to eq "[\"symbol\",Infinity,NaN]"
  end

  it 'resolves large numbers to Infinity' do
    expect(JSON.parse("[123e090000000]")).to eq [+1.0 / 0.0]
  end

  if RUBY_VERSION.to_f >= 2.0 # 1.9 just hangs on this.
    it 'it raises the correct error on strings that look like incomplete objects' do
      expect { JSON.parse("{") }.to raise_error(JSON::ParserError)
      expect { JSON.parse("[") }.to raise_error(JSON::ParserError)
    end

    it "does not raise an error on bad UTF8 input" do
      expect do
        JSON.parse(%("invalid utf8 string goes here\255"))
      end.not_to raise_error(JSON::ParserError)
    end

    it "blows up on circular references" do
      data = {}
      data['data'] = data
      data['ary'] = []
      data['ary'].push('x' => data['ary'])
      data['ary2'] = data['ary']
      data['leave intact'] = { 'not a circular reference' => true }

      if RUBY_PLATFORM == 'java'
        expect { JSON.dump(data) }.to raise_error
      else
        expect { JSON.dump(data) }.to raise_error(SystemStackError)
      end
    end
  end
end
