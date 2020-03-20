# Frozen-string-literal: true
# Copyright: 2017 - 2020 - ISC License
# rubocop:disable Lint/BooleanSymbol
# Author: Jordon Bedwell
# Encoding: utf-8

require 'rspec/helper'
require 'liquid/tag/parser'
describe Liquid::Tag::Parser do
  subject do
    described_class
  end

  context 'w/ url argv1' do
    context 'w/ //' do
      it 'works' do
        expect(subject.new('//hello.world').args).to eq({
          argv1: '//hello.world'
        })
      end
    end

    context 'w/ https?://' do
      it 'works' do
        expect(subject.new("'https://hello.world'").args).to eq({
          argv1: 'https://hello.world'
        })
      end
    end
  end

  describe '#to_h' do
    context 'w/ html: true' do
      it 'works' do
        expect(subject.new('a @b').to_h(html: true)).to eq({
          b: true
        })
      end
    end

    context 'w/ !bool' do
      it 'excludes' do
        expect(subject.new('!a').to_html).to eq(
          ''
        )
      end
    end

    context 'w/ hash' do
      it "doesn't include" do
        expect(subject.new('a=1 a=2 b:c=3').to_html).to eq(
          ''
        )
      end
    end

    context 'args' do
      it 'converts' do
        expect(subject.new('a=1').to_html).to eq(
          'a="1"'
        )
      end
    end

    context 'w/ argv1' do
      it 'excludes' do
        expect(subject.new('a').to_html).to eq(
          ''
        )
      end
    end
  end

  context "w/ '='" do
    it "doesn't parse" do
      expect(subject.new("a='b=c'").args).to(eq({
        a: 'b=c'
      }))
    end

    context 'argv1' do
      it "doesn't parse" do
        expect(subject.new("'a=b'").args).to eq({
          argv1: 'a=b'
        })
      end
    end
  end

  context 'w/ array' do
    it 'parses' do
      expect(subject.new('a=1 a=2 b=1 b=2').args).to(eq({
        a: [1, 2], b: [1, 2]
      }))
    end
  end

  context 'w/ boolean' do
    context 'w/ quotes' do
      it "doesn't convert" do
        expect(subject.new('a="@true"').args).to(eq({
          a: '@true'
        }))
      end
    end

    it 'works' do
      expect(subject.new('@true').args).to(eq({
        true: true
      }))
    end

    it 'strips @' do
      expect(subject.new('@true').args.keys).to(eq([
        :true
      ]))
    end

    context 'w/ sub' do
      it 'works' do
        expect(subject.new('@key1:key2').args).to(eq({
          key1: {
            key2: true
          }
        }))
      end
    end
  end

  context 'reverse boolean' do
    it 'works' do
      expect(subject.new('!false').args).to(eq({
        false: false
      }))
    end

    it 'strips !' do
      expect(subject.new('!false').args.keys).to(eq([
        :false
      ]))
    end

    context 'w/ sub' do
      it 'works' do
        expect(subject.new('!key1:key2').args).to(eq({
          key1: {
            key2: false
          }
        }))
      end
    end
  end

  context 'w/ deep hash' do
    it 'works' do
      expect(subject.new('a:b=c').args).to(eq({
        a: {
          b: 'c'
        }
      }))
    end
  end

  context 'w/ custom separator' do
    it 'works' do
      expect(subject.new("a:b:'c:d'", sep: ':').args).to(eq({
        a: {
          b: 'c:d'
        }
      }))
    end
  end

  context 'with argv1' do
    it 'works' do
      data = subject.new('a').args
      expect(data).to(have_key(:argv1))
      expect(data).to(eq({
        argv1: 'a'
      }))
    end

    context 'w/ k=v' do
      it 'skips' do
        data = subject.new('a=1').args
        expect(data).to_not(have_key(:argv1))
        expect(data).to(eq({
          a: 1
        }))
      end
    end

    context 'w/ bool' do
      it 'skips' do
        data = subject.new('!false').args
        expect(data).to_not(have_key(:argv1))
        expect(data).to(eq({
          false: false
        }))
      end
    end
  end

  context 'w/ nil' do
    it 'flips' do
      expect(subject.new('argv1 key').args).to(eq({
        argv1: 'argv1',
        key: nil
      }))
    end
  end
end
