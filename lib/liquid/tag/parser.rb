# Frozen-string-literal: true
# Copyright: 2017 - MIT License
# Encoding: utf-8

require "forwardable"
require "extras/hash"
require "liquid"

module Liquid
  class Tag
    class Parser
      attr_reader :args, :raw_args
      extend Forwardable

      def_delegator :@args, :each
      def_delegator :@args, :to_enum
      def_delegator :@args, :key?
      def_delegator :@args, :to_h
      def_delegator :@args, :map
      def_delegator :@args, :[]=
      def_delegator :@args, :[]

      # --
      BOOLEAN_REGEXP = /^(?<!\\)(\!|@)/
      NEGATIVE_BOOLEAN_REGEXP = /^(?<!\\)\!/
      POSITIVE_BOOLEAN_REGEXP = /^(?<!\\)\@/
      KEY_REGEXP = /\b(?<!\\):/

      # --
      def initialize(raw, defaults: {}, sep: "=")
        @sep = sep
        @rsep = Regexp.escape(sep)
        @escaped_sep_regexp = /\\#{@rsep}/
        @sep_regexp = /\b(?<!\\)#{@rsep}/
        @escaped_sep = "\\#{@sep}"
        @defaults = defaults
        @args = {}
        @raw = raw

        parse
      end

      # --
      def to_html(skip: [])
        @args.each_with_object([]) do |(k, v), a|
          next if k == :argv1 || skip.include?(k) ||
            v == false || v.is_a?(Hash) ||
            v.is_a?(Array)


          a << (v == true ? k.to_s : "#{k}=\"#{v}\"")
        end.join(" ")
      end

      # --
      private
      def parse
        args, hash = from_shellwords, {}
        if args.first !~ BOOLEAN_REGEXP && args.first !~ KEY_REGEXP \
        && args.first !~ @sep_regexp

          hash = {
            :argv1 => args.delete_at(0)
          }
        end

        @args = @defaults.deep_merge(args.each_with_object(hash) do |k, h, out = h|
          keys, _, val = k.rpartition(@sep_regexp)
          keys = keys.split(KEY_REGEXP).map(&:to_sym)
          val  = val.gsub(@escaped_sep_regexp, @sep)

          # @true, @false will not split or map right.
          if keys.size == 0 && val =~ BOOLEAN_REGEXP
            keys = [
              val
            ]

          elsif keys.size > 1
            h = h[keys[0]] ||= {}
            keys[1...-1].each do |sk|
              h = h[sk] ||= {}
            end
          end

          val = false if val == "false"
          val = val.to_f if val =~ /^\d+\.\d+$/
          val = false if val =~ NEGATIVE_BOOLEAN_REGEXP
          val = true  if val =~ POSITIVE_BOOLEAN_REGEXP
          val = val.to_i if val =~ /^\d+$/
          val = true if val == "true"

          key = keys.last.to_s.gsub(BOOLEAN_REGEXP, "").to_sym
          h[key] << val if h[key].is_a?(Array)
          h[key] = [h[key]] << val if h[key]
          h[key] = val unless h[key]

          out
        end)
      end

      # --
      private
      def from_shellwords
        Shellwords.shellwords(@raw.gsub(/('|")([^\1]+)\1/) do |v|
          v.gsub(@sep_regexp, @escaped_sep)
        end)
      end
    end
  end
end
