# Frozen-string-literal: true
# Copyright: 2017 - MIT License
# Encoding: utf-8

require "forwardable"
require "extras/hash"

module Liquid
  module Tag

    # --
    # Examples:
    #   - {% tag value argument:value %}
    #   - {% tag value "argument:value" %}
    #   - {% tag value argument:"I have spaces" %}
    #   - {% tag value argument:value\:with\:colon %}
    #   - {% tag value argument:"I can even escape \\: here too!" %}
    #   - {% tag value proxy:key:value %}
    # --
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
      def initialize(raw, defaults: {})
        @args = {}
        @defaults = defaults
        @raw = raw

        parse
      end

      # --
      def to_html(skip: [])
        @args.map do |k, v|
          next if k == :argv1 || skip.include?(k) || v == false || \
                  v.is_a?(Hash) || v.is_a?(Array)

          v == true ? k.to_s : "#{k}=\"#{v}\""
        end.flatten.compact.join("\s")
      end

      # --
      private
      def parse
        @args = @defaults.deep_merge(from_shellwords.each_with_index. \
        each_with_object({}) do |(k, i), h|

          nk = k.split(/\b(?<!\\):/).map do |v|
            o = v = v.gsub(/\b\\:/, ":")

            o = v.to_i if v =~ /^\d+$/
            o = v.to_f if v =~ /^\d+\.\d++$/
            o = false if v == "false"
            o = true if v == "true"

            o
          end

          nk[0] = nk[0].to_sym
          if i == 0 && nk.size == 1 && nk[0] !~ /^(@|!)/
            h[:argv1] = nk[0].to_s

          elsif nk.size > 2
            oh = h[nk[0]] ||= {}
            nk[1...-2].each do |v|
              oh = oh[v.to_sym] ||= {
                #
              }
            end

            oh[nk[-2].to_sym] = nk[-1]
          elsif nk.size == 2 && h[nk[0]]
            h[nk[0]] = [h[nk[0]]].flatten << nk[1]

          else
            h[nk[0]] = nk[1] if nk.size == 2
            h[$1.to_sym] = false if nk.size == 1 && nk[0] =~ /^(?<!\\)\!(.*)/
            h[nk[0].to_s.gsub(/^(?<!\\)\@/, "").to_sym] = true if nk.size == 1 \
              && nk[0] !~ /^(?<!\\)\!/
          end

          h
        end)
      end

      # --
      private
      def from_shellwords
        Shellwords.shellwords(@raw.gsub(/\b\\:/, "\\\\\\:"))
      end
    end
  end
end
