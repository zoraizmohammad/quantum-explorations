﻿// Solutions for Lab 11: Steane's Error Correction Code
// Copyright 2021 The MITRE Corporation. All Rights Reserved.

namespace QSharpExercises.Solutions.Lab11 {

    open Microsoft.Quantum.Arrays;
    open Microsoft.Quantum.Canon;
    open Microsoft.Quantum.Convert;
    open Microsoft.Quantum.Intrinsic;
    open Microsoft.Quantum.Math;
    open Microsoft.Quantum.Measurement;


    /// # Summary
    /// In this exercise, you are provided with an original qubit in an
    /// unknown state a|0> + b|1>. You are also provided with 6 blank qubits,
    /// all of which are in the |0> state. Your goal is to construct a
    /// "logical qubit" from these 7 qubits that acts like a single qubit, but
    /// can protect against a single bit-flip error and a single phase-flip
    /// error on any of the actual qubits. The bit-flip and phase-flip may be
    /// on different qubits.
    /// 
    /// # Input
    /// ## original
    /// A qubit that you want to protect from bit flips. It will be in the
    /// state a|0> + b|1>.
    /// 
    /// ## spares
    /// A register of 6 spare qubits that you can use to add error correction
    /// to the original qubit. All of them are in the |0> state.
    operation Exercise1 (original : Qubit, spares : Qubit[]) : Unit
    is Adj {
        ApplyToEachA(H, spares[3 .. 5]);
        ApplyToEachA(CNOT(original, _), spares[0 .. 1]);
        ApplyToEachA(CNOT(spares[5], _), [original, spares[0], spares[2]]);
        ApplyToEachA(CNOT(spares[4], _), [original, spares[1], spares[2]]);
        ApplyToEachA(CNOT(spares[3], _), spares[0 .. 2]);
    }


    /// # Summary
    /// In this exercise, you are provided with a logical qubit, represented
    /// by an error-protected register that was encoded with your Exercise 1
    /// implementation. Your goal is to perform a bit-flip syndrome
    /// measurement on the register, to determine if any of the bits have been
    /// flipped.
    /// 
    /// # Input
    /// ## register
    /// A 7-qubit register representing a single error-protected logical
    /// qubit. Its state  is unknown, and it may have suffered a bit-flip
    /// and/or a phase-flip error.
    /// 
    /// # Output
    /// An array of the 3 syndrome measurement results that the Steane code
    /// produces.
    operation Exercise2 (register : Qubit[]) : Result[] {
        use syndromeQubits = Qubit[3];

        ApplyToEach(
            CNOT(_, syndromeQubits[0]),
            register[0 .. 2 .. 6]
        );
        ApplyToEach(
            CNOT(_, syndromeQubits[1]),
            register[1 .. 2] + register[5 .. 6]
        );
        ApplyToEach(
            CNOT(_, syndromeQubits[2]),
            register[3 .. 6]
        );

        let result = MultiM(syndromeQubits);

        ResetAll(syndromeQubits);

        return Reversed(result);
    }


    /// # Summary
    /// In this exercise, you are provided with a logical qubit, represented
    /// by an error-protected register that was encoded with your Exercise 1
    /// implementation. Your goal is to perform a phase-flip syndrome
    /// measurement on the register, to determine if any of the qubits have
    /// suffered a phase-flip error.
    /// 
    /// # Input
    /// ## register
    /// A 7-qubit register representing a single error-protected logical
    /// qubit. Its state is unknown, and it may have suffered a bit-flip
    /// and/or a phase-flip error.
    /// 
    /// # Output
    /// An array of the 3 syndrome measurement results that the Steane code
    /// produces.
    operation Exercise3 (register : Qubit[]) : Result[] {
        use syndromeQubits = Qubit[3];

        ApplyToEach(H, syndromeQubits);
        ApplyToEach(
            CNOT(syndromeQubits[0], _),
            register[0 .. 2 .. 6]
        );
        ApplyToEach(
            CNOT(syndromeQubits[1], _),
            register[1 .. 2] + register[5 .. 6]
        );
        ApplyToEach(
            CNOT(syndromeQubits[2], _),
            register[3 .. 6]
        );
        ApplyToEach(H, syndromeQubits);

        let result = MultiM(syndromeQubits);

        ResetAll(syndromeQubits);

        return Reversed(result);
    }


    /// # Summary
    /// In this exercise, you are provided with the 3-result array of syndrome
    /// measurements provided by the bit-flip or phase-flip measurement
    /// operations. Your goal is to determine the index of the broken qubit
    /// (if any) based on these measurements.
    /// 
    /// As a reminder, for Steane's code, the following table shows the
    /// relationship between the syndrome measurements and the index of the
    /// broken qubit:
    /// -----------------------
    /// 000 = No error
    /// 001 = Error or qubit 0
    /// 010 = Error on qubit 1
    /// 011 = Error on qubit 2
    /// 100 = Error on qubit 3
    /// 101 = Error on qubit 4
    /// 110 = Error on qubit 5
    /// 111 = Error on qubit 6
    /// -----------------------
    /// 
    /// # Input
    /// ## syndrome
    /// An array of the 3 syndrome measurement results from the bit-flip or
    /// phase-flip measurement operations. These will come from your
    /// implementations of Exercise 2 and Exercise 3.
    /// 
    /// # Output
    /// An Int identifying the index of the broken qubit, based on the
    /// syndrome measurements. If none of the qubits are broken, you should
    /// return -1.
    /// 
    /// # Remarks
    /// This is a "function" instead of an "operation" because it's a purely
    /// classical method. It doesn't have any quantum parts to it, just lots
    /// of regular old classical math and logic.
    function Exercise4 (syndrome : Result[]) : Int {
        return ResultArrayAsInt(Reversed(syndrome)) - 1;

        // Using bitwise operations
        // let syndrome0 = (syndrome[0] == One ? 1 | 0);
        // let syndrome1 = (syndrome[1] == One ? 1 | 0);
        // let syndrome2 = (syndrome[2] == One ? 1 | 0);
        //
        // mutable brokenIndex = 0;
        // set brokenIndex = brokenIndex ||| syndrome2;
        // set brokenIndex = brokenIndex ||| (syndrome1 <<< 1);
        // set brokenIndex = brokenIndex ||| (syndrome0 <<< 2);

        // return brokenIndex - 1;
    }


    /// # Summary
    /// In this exercise, you are given a logical qubit represented by an
    /// error-protected register of 7 physical qubits. This register was
    /// produced by your implementation of Exercise 1. It is in an unknown
    /// state, but one of its qubits may or may not have suffered a bit-flip
    /// error, and another qubit may or may not have suffered a phase-flip
    /// error. Your goal is to use your implementations of Exercises 2, 3, and
    /// 4 to detect and correct the bit-flip and/or phase-flip errors in the
    /// register.
    /// 
    /// # Input
    /// ## register
    /// A 7-qubit register representing a single error-protected logical
    /// qubit. Its state is unknown, and it may have suffered a bit-flip
    /// and/or a phase-flip error.
    /// 
    /// # Remarks
    /// This test may take a lot longer to run than you're used to, because it
    /// tests every possible combination of bit and phase flips on a whole
    /// bunch of different original qubit states. Don't worry if it doesn't
    /// immediately finish!
    operation Exercise5 (register : Qubit[]) : Unit {
        let bitFlipSyndrome = Exercise2(register);
        let phaseFlipSyndrome = Exercise3(register);

        let bitFlipIndex = Exercise4(bitFlipSyndrome);
        if bitFlipIndex >= 0 {
            X(register[bitFlipIndex]);
        }

        let phaseFlipIndex = Exercise4(phaseFlipSyndrome);
        if phaseFlipIndex >= 0 {
            Z(register[phaseFlipIndex]);
        }
    }
}
