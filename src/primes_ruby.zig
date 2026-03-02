const std = @import("std");
const c = std.c;

const ruby = @cImport(
    @cInclude("ruby.h"),
);
const primes = @cImport(
    @cInclude("primes.h"),
);

fn findPrimes(...) callconv(.c) ruby.VALUE {
    var va_list = @cVaStart();
    defer @cVaEnd(&va_list);

    _ = @cVaArg(&va_list, ruby.VALUE);
    const max_limit_rb_number = @cVaArg(&va_list, ruby.VALUE);
    const max_limit = ruby.RB_NUM2ULONG(max_limit_rb_number);

    var results: [*c]u64 = null;
    var results_count: usize = 0;

    const err = primes.find_primes(max_limit, &results, &results_count);
    if (err == primes.find_primes_error_invalid_params) {
        ruby.rb_raise(ruby.rb_eArgError, "invalid parameters");
    } else if (err == primes.find_primes_error_memory_allocation_failed) {
        ruby.rb_raise(ruby.rb_eNoMemError, "memory allocation failed");
    }

    const results_rb_array = ruby.rb_ary_new_capa(@intCast(results_count));

    for (0..results_count) |i| {
        const prime = results[i];
        _ = ruby.rb_ary_push(results_rb_array, ruby.RB_ULONG2NUM(prime));
    }

    c.free(results);

    return results_rb_array;
}

export fn Init_libprimes_ruby() void {
    const primes_rb_module = ruby.rb_define_module("Primes");
    ruby.rb_define_module_function(primes_rb_module, "find", findPrimes, 1);
}
