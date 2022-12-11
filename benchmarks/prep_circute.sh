#!/bin/bash

PTAU_FILE=../ptau/powersOfTau28_hez_final_14.ptau

# TODO:
# ADD FILES FOLDER TO GITIGNORE
# ADD C++ FOLDER TO GITIGNORE

circuit_name=${1%.*}
root="$circuit_name"_benchmark_files
circom_source_code=../test/circuits/$1

if ! -d "./$root"
then
    mkdir $root
    echo $root

    echo "~~~COMPILING CIRCUIT~~~"
    circom "$circom_source_code" --r1cs --sym --c --output ./"$root"
    cd $root

    echo "~~~GENERATING WITNESS FOR~~~"
    set -x
    cd "$circuit_name"_cpp 
    make 
    ./"$circuit_name" ../../inputs/bench_poseidon.json ../"$circuit_name"_witness.wtns > ../log.out
    cd ..

    echo "~~~GENERATING ZKEY 0~~~"
    node --trace-gc --trace-gc-ignore-scavenger --max-old-space-size=2048000 --initial-old-space-size=2048000 --no-global-gc-scheduling --no-incremental-marking --max-semi-space-size=1024 --initial-heap-size=2048000 --expose-gc /home/ubuntu/monia/benchmark/platforms/node_modules/snarkjs/cli.js zkey new ./"$circuit_name".r1cs "$PTAU_FILE" ./"$circuit_name"_0.zkey

    echo "~~~GENERATING FINAL ZKEY~~~"
    node --trace-gc --trace-gc-ignore-scavenger --max-old-space-size=2048000 --initial-old-space-size=2048000 --no-global-gc-scheduling --no-incremental-marking --max-semi-space-size=1024 --initial-heap-size=2048000 --expose-gc /home/ubuntu/monia/benchmark/platforms/node_modules/snarkjs/cli.js zkey beacon ./"$circuit_name"_0.zkey ./"$circuit_name".zkey 0102030405060708090a0b0c0d0e0f101112231415161718221a1b1c1d1e1f 10 -n="Final Beacon phase2"

    echo "~~~VERIFYING FINAL ZKEY~~~"
    node --trace-gc --trace-gc-ignore-scavenger --max-old-space-size=2048000 --initial-old-space-size=2048000 --no-global-gc-scheduling --no-incremental-marking --max-semi-space-size=1024 --initial-heap-size=2048000 --expose-gc /home/ubuntu/monia/benchmark/platforms/node_modules/snarkjs/cli.js zkey verify ./"$circuit_name".r1cs "$PTAU_FILE" ./"$circuit_name".zkey

    echo "~~~EXPORTING VERIFICATION KEY~~~"
    node --trace-gc --trace-gc-ignore-scavenger --max-old-space-size=2048000 --initial-old-space-size=2048000 --no-global-gc-scheduling --no-incremental-marking --max-semi-space-size=1024 --initial-heap-size=2048000 --expose-gc /home/ubuntu/monia/benchmark/platforms/node_modules/snarkjs/cli.js zkey export verificationkey ./"$circuit_name".zkey ./"$circuit_name"_vkey.json
fi

echo "~~~GENERATING PROOF FOR SAMPLE INPUT~~~"
start=$(date +%s%N)
npx snarkjs groth16 prove ./"$circuit_name".zkey ./"$circuit_name"_witness.wtns ./"$circuit_name"_proof.json ./"$circuit_name"_public.json
end=$(date +%s%N)
echo "Elapsed time: $(($(($end-$start))/1000)) ms"

echo "~~~VERIFYING PROOF FOR SAMPLE INPUT~~~"
start=$(date +%s%N)
npx snarkjs groth16 verify ./"$circuit_name"_vkey.json ./"$circuit_name"_public.json ./"$circuit_name"_proof.json
end=$(date +%s%N)
echo "Elapsed time: $(($(($end-$start))/1000)) ms"
