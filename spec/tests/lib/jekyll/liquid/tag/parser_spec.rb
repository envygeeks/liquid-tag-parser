# Frozen-string-literal: true
# Copyright: 2017 Jordon Bedwell - MIT License
# Encoding: utf-8

require "rspec/helper"

describe Liquid::Tag::Parser do
  it "support array's" do
    expect(described_class.new("a:1 a:2 b:1 b:2").args).to(eq({
      :a => [1, 2], :b => [1, 2]
    }))
  end

  #

  context "boolean" do
    it "works" do
      expect(described_class.new("@true").args).to(eq({
        :true => true
      }))
    end

    #

    it "should strip the @" do
      expect(described_class.new("@true").args.keys).to(eq([
        :true
      ]))
    end
  end

  #

  context "reverse boolean" do
    it "works" do
      expect(described_class.new("!false").args).to(eq({
        :false => false
      }))
    end

    #

    it "should strip the !" do
      expect(described_class.new("!false").args.keys).to(eq([
        :false
      ]))
    end
  end

  #

  it "supports deep hashes" do
    expect(described_class.new("a:b:c").args).to(eq({
      :a => {
        :b => "c"
      }
    }))
  end

  #

  it "supports escaping :" do
    expect(described_class.new("a:b\\:c\\:d").args).to(eq({
      :a => "b:c:d"
    }))
  end
end
