#include "primes.h"
#include <stdint.h>
#include <stdlib.h>

enum find_primes_error find_primes(uint64_t max_limit, uint64_t **output_primes,
                                   size_t *output_primes_count) {
  /*
   * 检查 limit 是否达到或超过 SIZE_MAX
   * 防止 limit + 1 计算时发生 size_t 溢出，确保 calloc 安全
   */
  if (SIZE_MAX <= max_limit) {
    return find_primes_error_invalid_params;
  }

  /* 验证输出指针有效性，防止空指针解引用导致崩溃 */
  if (output_primes == NULL || output_primes_count == NULL) {
    return find_primes_error_invalid_params;
  }

  /* 初始化输出状态，确保错误发生时调用者不会读取旧数据 */
  *output_primes = NULL;
  *output_primes_count = 0;

  /* 处理小于 2 的边界情况，2 是最小的素数 */
  if (max_limit < 2) {
    return find_primes_success;
  }

  /*
   * 分配筛法数组，标记每个数是否为合数
   * 使用 uint8_t 确保每个数占用 1 字节
   * 初始化：calloc 默认为 0，初始假设所有数都是素数 (0=素数，1=合数)
   */
  uint8_t *is_composite = calloc((size_t)(max_limit + 1), sizeof(uint8_t));
  if (is_composite == NULL) {
    return find_primes_error_memory_allocation_failed;
  }

  /* 0 和 1 不是素数，当作合数处理 */
  is_composite[0] = 1;
  is_composite[1] = 1;

  /*
   * 埃拉托斯特尼筛法
   */
  for (uint64_t current = 2; current <= max_limit / current; current++) {
    /* 如果 current 未被标记为合数，则它是素数 */
    if (is_composite[current] == 0) {
      /*
       * 从 current 的平方开始标记倍数
       * 小于平方的倍数 (如 2*3) 已被更小的素数 (如 2) 标记过
       */
      for (uint64_t multiple_num = current * current;
           multiple_num <= max_limit;) {
        // 每个倍数都是合数
        is_composite[multiple_num] = 1;

        if (max_limit - current < multiple_num) {
          break;
        }
        multiple_num += current;
      }
    }
  }

  /* 第一次遍历，统计素数总个数，以便精确分配结果数组 */
  size_t primes_count = 0;
  for (uint64_t i = 2; i <= max_limit; i++) {
    if (is_composite[i] == 0) {
      primes_count++;
    }
  }

  /* 检查 primes_count 是否超过最大可分配元素个数 */
  if (SIZE_MAX / sizeof(uint64_t) < primes_count) {
    free(is_composite);
    return find_primes_error_memory_allocation_failed;
  }

  /* 分配最终结果数组，存储找到的素数 */
  uint64_t *results = malloc(primes_count * sizeof(uint64_t));
  if (results == NULL) {
    free(is_composite);
    return find_primes_error_memory_allocation_failed;
  }

  /* 第二次遍历，将素数收集到结果数组中 */
  for (uint64_t i = 2, j = 0; i <= max_limit; i++) {
    if (is_composite[i] == 0) {
      results[j++] = i;
    }
  }

  /* 清理临时筛法数组，输出最终结果指针和计数 */
  free(is_composite);
  *output_primes = results;
  *output_primes_count = primes_count;

  return find_primes_success;
}
