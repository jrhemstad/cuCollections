/*
 * Copyright (c) 2020, NVIDIA CORPORATION.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#include <benchmark/benchmark.h>
#include <thrust/iterator/iterator_traits.h>
#include <thrust/reduce.h>
#include <thrust/sort.h>
#include <cuco/insert_only_hash_array.cuh>
#include "../synchronization/synchronization.hpp"

template <typename KeyRandomIterator, typename ValueRandomIterator>
void thrust_reduce_by_key(KeyRandomIterator keys_begin,
                          KeyRandomIterator keys_end,
                          ValueRandomIterator values_begin) {
  using Key = typename thrust::iterator_traits<KeyRandomIterator>::value_type;
  using Value =
      typename thrust::iterator_traits<ValueRandomIterator>::value_type;

  // Exact size of output is unknown (number of unique keys), but upper bounded by the number of keys
  auto maximum_output_size = thrust::distance(keys_begin, keys_end);
  thrust::device_vector<Key> output_keys(maximum_output_size);
  thrust::device_vector<Value> output_values(maximum_output_size);

  thrust::sort_by_key(keys_begin, keys_end, values_begin);
  thrust::reduce_by_key(keys_begin, keys_end, values_begin, output_keys.begin(),
                        output_values.end());
}

static void BM_thrust(::benchmark::State& state) {
  thrust::device_vector<int32_t> keys(state.range(0));
  thrust::device_vector<int32_t> values(state.range(0));
  for (auto _ : state) {
    cuda_event_timer t{state, true};
    thrust_reduce_by_key(keys.begin(), keys.end(), values.begin());
  }
}
BENCHMARK(BM_thrust)
    ->UseManualTime()
    ->Unit(benchmark::kMillisecond)
    ->RangeMultiplier(10)
    ->Range(100'000, 1'000'000'000);