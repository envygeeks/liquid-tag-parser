# Frozen-string-literal: true
# Copyright: 2017 - MIT License
# Encoding: utf-8

require "extras/hash"
require "forwardable/extended"
require "liquid"

module Liquid
  class Tag
    class Parser
      attr_reader :args, :raw_args
      extend Forwardable::Extended

      rb_delegate :each,        to: :@args
      rb_delegate :to_enum,     to: :@args
      rb_delegate :key?,        to: :@args
      rb_delegate :to_h,        to: :@args
      rb_delegate :map,         to: :@args
      rb_delegate :[]=,         to: :@args
      rb_delegate :[],          to: :@args
      rb_delegate :merge,       to: :@args
      rb_delegate :merge!,      to: :@args
      rb_delegate :deep_merge,  to: :@args
      rb_delegate :deep_merge!, to: :@args
      rb_delegate :args_with_indifferent_access, to: :@args, \
        alias_of: :with_indifferent_access

      FLOAT_REGEXP = /^\d+\.\d+$/
      BOOLEAN_REGEXP = /^(?<!\\)(\!|@)/
      NEGATIVE_BOOLEAN_REGEXP = /^(?<!\\)\!/
      BOOLEAN_QUOTE_REGEXP = /^('|")((?<!\\)@|(?<!\\)\!)/
      BOOLEAN_QUOTE_REPLACEMENT = "\\1\\\\\\2"
      POSITIVE_BOOLEAN_REGEXP = /^(?<!\\)\@/
      DESCAPED_BOOLEAN_REGEXP = /\\(@|\!)/
      KEY_REGEXP = /\b(?<!\\):/
      INT_REGEXP = /^\d+$/

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
      def to_html(skip: [], hash: false)
        out = @args.each_with_object(hash ? {} : []) do |(k, v), o|
          next if k == :argv1 || skip.include?(k) ||
            v == false || v.is_a?(Hash) ||
            v.is_a?(Array)

          o[k] = v if hash
          unless hash
            o << (v == true ? k.to_s : "#{k}=\"#{v}\"")
          end
        end

        hash ? out : out.join(" ")
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

          val  = val.gsub(@escaped_sep_regexp, @sep)
          if keys.empty? && val =~ BOOLEAN_REGEXP
            # @true, @false will not map right.
            keys = val.gsub(BOOLEAN_REGEXP, "")
          end

          keys, val = val, nil if keys.empty?
          keys = keys.split(KEY_REGEXP).map(&:to_sym)
          if keys.size > 1
            h = h[keys[0]] ||= {}
            keys[1...-1].each do |sk|
              h = h[sk] ||= {}
            end
          end


          val = false if val == "false"
          val = val.to_f if val =~ FLOAT_REGEXP
          val = false if val =~ NEGATIVE_BOOLEAN_REGEXP
          val = true  if val =~ POSITIVE_BOOLEAN_REGEXP
          val = val.to_i if val =~ INT_REGEXP
          val = true if val == "true"

          if val.is_a?(String)
            then val = val.gsub(DESCAPED_BOOLEAN_REGEXP, "\\1")
          end

          key = keys.last.to_sym
          h[key] << val if h[key].is_a?(Array)
          h[key] = [h[key]].flatten << val if h[key] && !h[key].is_a?(Array)
          h[key] = val unless h[key]

          out
        end)
      end

      # --
      private
      def from_shellwords
        Shellwords.shellwords(@raw.gsub(/('|")([^\1]+)\1/) do |v|
          v.gsub(BOOLEAN_QUOTE_REGEXP, BOOLEAN_QUOTE_REPLACEMENT).
            gsub(@sep_regexp, @escaped_sep)
        end)
      end
    end
  end
end
