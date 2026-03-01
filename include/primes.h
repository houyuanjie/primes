#pragma once

#include <stddef.h>
#include <stdint.h>

enum find_primes_error {
  find_primes_success = 0,
  find_primes_error_invalid_params,
  find_primes_error_memory_allocation_failed,
};

enum find_primes_error find_primes(uint64_t max_limit, uint64_t **output_primes,
                                   size_t *output_primes_count);
