# asm-linear-regression-model

A **from-scratch linear regression implementation written entirely in x86-64 assembly (NASM)** for Linux.

This project was built to deeply understand what machine learning models *actually do under the hood* — from math, to memory, to CPU instructions — without relying on any libraries or runtime support.

No libc.  
No ML frameworks.  
Just syscalls, floating-point math, and gradient descent.

---

## What this project does

- Implements **linear regression**:  
  \[
  y = wx + b
  \]

- Trains the model using **batch gradient descent**
- Uses **Mean Squared Error (MSE)** as the loss function
- Randomly initializes parameters using the Linux `getrandom` syscall
- Prints intermediate loss values during training
- Prints model parameters before and after training

All of this is done manually in assembly.

---

## Why assembly?

This project is *not* about performance or practicality.

It exists to answer questions like:
- What does gradient descent really look like at the machine level?
- How are floating-point operations actually performed?
- How much work do ML libraries hide from you?
- How do math, memory layout, and control flow connect?

Writing this in assembly forces complete understanding — there is nowhere to hide.

---

## Project structure

```
├── main.asm ; program entry point and training setup
├── model.asm ; model definition, prediction, and training logic
├── loss.asm ; MSE loss + number printing utilities
├── puts.asm ; minimal string printing helper
├── makefile
```

### main.asm
- Defines the dataset
- Initializes the model
- Trains it for a fixed number of epochs
- Prints initial and final weights, bias, and loss

### model.asm
- Random parameter initialization
- Forward prediction (`y = wx + b`)
- Gradient computation
- Parameter updates using gradient descent

### loss.asm
- Mean Squared Error calculation
- Integer and floating-point printing (no libc)

### puts.asm
- Minimal `puts`-style helper using raw syscalls
- Uses return-address string trick for inline strings

---

## Example output

You’ll see output similar to:

Initial weight:
-0.73
Initial bias:
0.12

epoch 0 loss: 8.41
epoch 100 loss: 0.03
epoch 200 loss: 0.0001
```

End weight:
1.99
End bias:
-0.50
```


(The exact values vary due to random initialization.)

---

## Building and running

### Requirements
- Linux (x86-64)
- NASM
- GCC (used only as a linker driver)

### Build
```sh
make
```
### Run
```sh
./lr
```
