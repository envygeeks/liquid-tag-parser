# Frozen-string-literal: true
# Copyright: 2017 - 2018 - MIT License
# Author: Jordon Bedwell
# Encoding: utf-8

require 'extras/hash'
require 'liquid'

module Liquid
  class Tag
    class Parser
      attr_reader :args
      alias raw_args args
      extend Forwardable

      def_delegator :@args, :each
      def_delegator :@args, :key?
      def_delegator :@args, :to_h
      def_delegator :@args, :each_key
      def_delegator :@args, :each_with_object
      def_delegator :@args, :each_value
      def_delegator :@args, :values_at
      def_delegator :@args, :to_enum
      def_delegator :@args, :map
      def_delegator :@args, :[]=
      def_delegator :@args, :[]
      def_delegator :@args, :merge
      def_delegator :@args, :merge!
      def_delegator :@args, :deep_merge
      def_delegator :@args, :deep_merge!
      def_delegator :@args, :select

      def args_with_indifferent_access
        @args.send(
          :with_indifferent_access
        )
      end

      # --
      FALSE = '!'
      FLOAT = %r!\A\d+\.\d+\Z!.freeze
      QUOTE = %r!(["'])([^\1]*)(\1)!.freeze
      SPECIAL = %r{(?<!\\)([@!:=])}.freeze
      BOOL = %r{\A(?<!\\)([!@])([\w:]+)\z}.freeze
      UNQUOTED_SPECIAL = %r{(?<!\\)(://)}.freeze
      SPECIAL_ESCAPED = %r{\\([@!:=])}.freeze
      KEY = %r{\b(?<!\\):}.freeze
      INT = %r!^\d+$!.freeze
      TRUE = '@'

      def initialize(raw, defaults: {}, sep: '=')
        @sep = sep
        @unescaped_sep = sep
        @rsep = Regexp.escape(sep)
        @escaped_sep_regexp = %r!\\(#{@rsep})!
        @sep_regexp = %r{\b(?<!\\)(#{@rsep})}
        @escaped_sep = "\\#{@sep}"
        @args = defaults
        @raw = raw

        parse
      end

      #
      # Consumes a block and wraps around reusably on arguments.
      # @return [Hash<Symbol,Object>,Array<String>]
      #
      def skippable_loop(skip: [], hash: false)
        @args.each_with_object(hash ? {} : []) do |(k, v), o|
          skip_in_html?(k: k, v: v, skips: skip) ? next : yield([k, v], o)
        end
      end

      #
      # @param [Array<Symbol>] skip keys to skip.
      # Converts the arguments into an HTML attribute string.
      # @return [String]
      #
      def to_html(skip: [])
        skippable_loop(skip: skip, hash: false) do |(k, v), o|
          o << (v == true ? k.to_s : "#{k}=\"#{v}\"")
        end.join(' ')
      end

      #
      # @param [Array<Symbol>] skip keys to skip.
      # @param [true,false] html skip non-html values.
      # Converts arguments into an HTML hash (or to arguments).
      # @return [Hash<Object>,Array<String>]
      #
      def to_h(skip: [], html: false)
        return @args unless html

        skippable_loop(skip: skip, hash: true) do |(k, v), o|
          o[k] = v
        end
      end

      #
      # @param [String] k the key
      # @param [Object] v the value
      # @param [Array<Symbol>] skips personal skips.
      # Determines if we should skip in HTML.
      # @return [true,false]
      #
      private
      def skip_in_html?(k:, v:, skips: [])
        k == :argv1 || v.is_a?(Array) || skips.include?(k) \
          || v.is_a?(Hash) || v == false
      end

      #
      # @return [true,nil] a truthy value.
      # @param [Integer] idx the current iteration.
      # @param [String] keys the keys that will be split.
      # @param [String] val the value.
      #
      private
      def argv1(i:, k:, v:)
        if i.zero? && k.empty? && v !~ BOOL && v !~ @sep_regexp
          @args[:argv1] = unescape(convert(v))
        end
      end

      #
      # @return [Array<String,true|false>]
      # Allows you to flip a value based on condition.
      # @param [String] v the value.
      #
      private
      def flip_kv_bool(v)
        [
          v.gsub(BOOL, '\2'),
          v.start_with?(TRUE) ? true : false
        ]
      end

      #
      # @param [Array<Symbol>] keys the keys.
      # Builds a sub-hash or returns parent hash.
      # @return [Hash]
      #
      private
      def build_hash(keys)
        out = @args

        if keys.size > 1
          out = @args[keys[0]] ||= {}
          keys[1...-1].each do |sk|
            out = out[sk] ||= {}
          end
        end

        out
      end

      private
      def unescape(val)
        return unless val

        val.gsub(@escaped_sep_regexp, @unescaped_sep).gsub(
          SPECIAL_ESCAPED, '\1')
      end

      private
      def parse
        from_shellwords.each_with_index do |k, i|
          keys, _, val = k.rpartition(@sep_regexp)
          next if argv1(i: i, k: keys, v: val)

          val = unescape(val)
          keys, val = flip_kv_bool(val) if val =~ BOOL && keys.empty?
          keys, val = val, nil if keys.empty?
          keys = keys.split(KEY).map(&:to_sym)

          set_val(
            v: convert(val),
            hash: build_hash(keys),
            k: keys.last
          )
        end
      end

      # --
      private
      def set_val(k:, v:, hash:)
        hash[k] << v if hash[k].is_a?(Array)
        hash[k] = [hash[k]].flatten << v if hash[k] && !hash[k].is_a?(Array)
        hash[k] = v unless hash[k]
      end

      # --
      # @return [true,false,Float,Integer]
      # Convert a value to a native value.
      # --
      private
      def convert(val)
        return if val.nil?
        return val if [true, false].include?(val)
        return val.to_f if val =~ FLOAT
        return val.to_i if val =~ INT

        val
      end

      # --
      # Wraps into `#shellsplit`, and first substitutes some values.
      # @return [Array<String>]
      # --
      private
      def from_shellwords
        Shellwords.shellsplit(
          @raw.gsub(SPECIAL, '\1')
              .gsub(UNQUOTED_SPECIAL, '\1')
              .gsub(@sep_regexp, @escaped_sep))
      end
    end
  end
end
