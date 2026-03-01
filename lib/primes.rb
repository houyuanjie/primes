# frozen_string_literal: true

require_relative '../zig-out/lib/libprimes_ruby.so'

module Primes
  def self.theta(max_limit)
    find(max_limit)
      .map { |n| Math.log(n) }
      .sum
  end
end
