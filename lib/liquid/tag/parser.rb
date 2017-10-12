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

      FLOAT = /^\d+\.\d+$/
      BOOLEAN = /^(?<!\\)(\!|@)/
      NEGATIVE_BOOLEAN = /^(?<!\\)\!/
      BOOLEAN_QUOTE_REPLACEMENT = "\\1\\\\\\2"
      SHELLSPLIT = /\G\s*(?>([^\s\\\'\"]+)|'([^\']*)'|"((?:[^\"\\]|\\.)*)"|(\\.?)|(\S))(\s|\z)?/m
      BOOLEAN_QUOTE = /('|")((?<!\\)@|(?<!\\)\!)/
      POSITIVE_BOOLEAN = /^(?<!\\)\@/
      ESCAPED_BOOLEAN = /\\(@|\!)/
      KEY = /\b(?<!\\):/
      INT = /^\d+$/

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

      def to_html(skip: [], hash: false)
        out = @args.each_with_object(hash ? {} : []) do |(k, v), o|
          next if k == :argv1
          next if v.is_a?(Array)
          next if skip.include?(k)
          next if v.is_a?(Hash)
          next if v == false

          o[k] = v if hash
          unless hash
            o << (v == true ? k.to_s : "#{k}=\"#{v}\"")
          end
        end

        hash ? out : out.join(" ")
      end

      private
      def argv1(args)
        val = args[0]
        hash = {}

        # !"@true" && !"key1:key2=val" but "argv1 @true key1:key2=val"
        if val !~ BOOLEAN && val !~ KEY && val !~ @sep_regexp
          hash = {
            argv1: args.delete_at(0)
          }
        end

        return args, hash
      end

      private
      def parse
        args, hash = argv1(from_shellwords)
        @args = @defaults.deep_merge(args.each_with_object(hash) do |k, h, out = h|
          keys, _, val = k.rpartition(@sep_regexp)

          val  = val.gsub(@escaped_sep_regexp, @sep) # Unescape \\=
          keys = val.gsub(BOOLEAN, "") if keys.empty? && val =~ BOOLEAN # @true
          keys,  val = val, nil if keys.empty? # key val
          keys = keys.split(KEY).map(&:to_sym)

          if keys.size > 1
            h = h[keys[0]] ||= {}
            keys[1...-1].each do |sk|
              h = h[sk] ||= {}
            end
          end

          val = val.to_i if val =~ INT # key=1
          val = val.to_f if val =~ FLOAT # key=0.1
          val = false    if val == "false" # key=false
          val = false    if val =~ NEGATIVE_BOOLEAN # !false
          val = true     if val =~ POSITIVE_BOOLEAN # @true
          val = true     if val == "true" # key=true

          if val.is_a?(String)
            then val = val.gsub(ESCAPED_BOOLEAN, "\\1")
          end

          key = keys.last.to_sym
          h[key] << val if h[key].is_a?(Array)
          h[key] = [h[key]].flatten << val if h[key] && !h[key].is_a?(Array)
          h[key] = val unless h[key]

          out
        end)
      end

      private
      def from_shellwords
        shellsplit(@raw.gsub(/('|")([^\1]+)\1/) do |v|
          v.gsub(BOOLEAN_QUOTE, BOOLEAN_QUOTE_REPLACEMENT).gsub(@sep_regexp, @escaped_sep)
        end)
      end

      # Because Shellwords.shellwords on < 2.4 has problems
      # with quotes and \\, we ported this back, this pretty
      # much the same thing except we replace some of the
      # questionable code like `String.new`
      private
      def shellsplit(line)
        out, field = [], ""

        line.scan(SHELLSPLIT) do |w, s, d, e, g, se|
          raise ArgumentError, "Unmatched double quote: #{line.inspect}" if g
            field = field + (w || s || (d && d.gsub(/\\([$`"\\\n])/, '\\1')) \
            || e.gsub(/\\(.)/, '\\1'))

          if se
            out << field
            field = ""
          end
        end

        out
      end
    end
  end
end
