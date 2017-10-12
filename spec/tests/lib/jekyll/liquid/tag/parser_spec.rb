# Frozen-string-literal: true
# Copyright: 2017 Jordon Bedwell - MIT License
# Encoding: utf-8

require "rspec/helper"
describe Liquid::Tag::Parser do
  subject do
    described_class
  end

  describe "#to_html" do
    describe "hash: true" do
      it "should ship a hash" do
        expect(subject.new("a @b").to_html(hash: true)).to(eq({
          :b => true
        }))
      end
    end

    it "does not include negative booleans" do
      expect(subject.new("!a").to_html).to(eq(
        ""
      ))
    end

    it "does not include hashes or array's" do
      expect(subject.new("a=1 a=2 b:c=3").to_html).to(eq(
        ""
      ))
    end

    it "converts args to key val" do
      expect(subject.new("a=1").to_html).to(eq(
        "a=\"1\""
      ))
    end

    it "does not include argv1" do
      expect(subject.new("a").to_html).to(eq(
        ""
      ))
    end
  end

  #

  it "doesn't deep parse keys with quotes" do
    expect(subject.new("a='b=c'").args).to(eq({
      a: "b=c"
    }))
  end

  #

  it "support array's" do
    expect(subject.new("a=1 a=2 b=1 b=2").args).to(eq({
      a: [1, 2], b: [1, 2]
    }))
  end

  #

  context "boolean" do
    it "does not convert quoted @" do
      expect(subject.new("a=\"@true\"").args).to(eq({
        a: "@true"
      }))
    end

    it "works" do
      expect(subject.new("@true").args).to(eq({
        true: true
      }))
    end

    #

    it "should strip the @" do
      expect(subject.new("@true").args.keys).to(eq([
        :true
      ]))
    end

    #

    it "supports sub-booleans" do
      expect(subject.new("@key1:key2").args).to(eq({
        key1: {
          key2: true
        }
      }))
    end
  end

  #

  context "reverse boolean" do
    it "works" do
      expect(subject.new("!false").args).to(eq({
        false: false
      }))
    end

    #

    it "should strip the !" do
      expect(subject.new("!false").args.keys).to(eq([
        :false
      ]))
    end

    #

    it "supports sub-booleans" do
      expect(subject.new("!key1:key2").args).to(eq({
        key1: {
          key2: false
        }
      }))
    end
  end

  #

  it "supports deep hashes" do
    expect(subject.new("a:b=c").args).to(eq({
      a: {
        b: "c"
      }
    }))
  end

  #

  it "supports custom separators" do
    expect(subject.new("a:b:'c:d'", sep: ":").args).to(eq({
      a: {
        b: "c:d"
      }
    }))
  end

  #

  context "with argv1" do
    it "should make it argv1" do
      data = subject.new("a").args
      expect(data).to(have_key(:argv1))
      expect(data).to(eq({
        argv1: "a"
      }))
    end

    #

    it "does not use the val when it's key=val" do
      data = subject.new("a=1").args
      expect(data).to_not(have_key(:argv1))
      expect(data).to(eq({
        :a => 1
      }))
    end

    #

    context "booleans" do
      it "does not allow negative" do
        data = subject.new("!false").args
        expect(data).to_not(have_key(:argv1))
        expect(data).to(eq({
          false: false
        }))
      end
    end
  end

  context "with a nil value" do
    it "flips the value and the key" do
      expect(subject.new("argv1 key").args).to(eq({
        argv1: "argv1",
        key: nil,
      }))
    end
  end
end
