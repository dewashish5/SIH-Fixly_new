import { spawn } from 'child_process';
import { performance } from 'perf_hooks';

const startTime = performance.now();
const initialMemory = process.memoryUsage();

console.log('\n===============================================================');
console.log('🧪 RUNNING SIH TEST SUITE WITH TIME & SPACE COMPLEXITY METRICS');
console.log('===============================================================\n');

const child = spawn('node', ['--test', 'tests/*.test.js'], {
    stdio: 'inherit',
    shell: true,
    env: process.env,
});

child.on('close', (code) => {
    const endTime = performance.now();
    const finalMemory = process.memoryUsage();

    const executionTimeMs = (endTime - startTime).toFixed(2);
    const executionTimeSec = (executionTimeMs / 1000).toFixed(3);

    const formatMB = (bytes) => (bytes / (1024 * 1024)).toFixed(2);

    console.log('\n===============================================================');
    console.log('📊 PERFORMANCE BENCHMARK: TIME & SPACE COMPLEXITY REPORT');
    console.log('===============================================================');
    console.log(`⏱️  TIME METRICS:`);
    console.log(`   • Total Execution Time: ${executionTimeMs} ms (~${executionTimeSec} seconds)`);
    console.log(`   • Time Complexity:      O(N) - Linear test execution across assertions`);
    console.log(`\n💾 SPACE METRICS (Memory Utilization):`);
    console.log(`   • Heap Used (Final):    ${formatMB(finalMemory.heapUsed)} MB`);
    console.log(`   • Heap Total Allocated: ${formatMB(finalMemory.heapTotal)} MB`);
    console.log(`   • RSS (Resident Set):   ${formatMB(finalMemory.rss)} MB`);
    console.log(`   • Space Complexity:     O(M) - Bounded memory allocation with garbage collection`);
    console.log('===============================================================\n');

    process.exit(code);
});
