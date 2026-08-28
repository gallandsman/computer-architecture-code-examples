;;; sdev.asm
;;; Demonstrating the standard deviation function using SSE/AVX
;;;   sdev = sqrt ((sum (x_i)^2)/n - (sum (x_i))^2/n)
;;;
;;; Programmer: Mayer Goldberg, 2026

section .data
sample:
	dq 12.7567, 80.6785, 38.4979, 25.5809
	dq 99.2153, 89.1932, 73.1718, 60.9881
	dq 63.5751, 27.8504, 67.9804, 74.9866
	dq 67.2299, 15.7943, 61.6628, 62.5492
	dq 21.7163, 83.8478, 60.7651, 50.9627
	dq 20.7451, 67.6474, 81.1785, 28.7442
	dq 69.5148, 86.9377, 58.6521, 29.4894
	dq 70.7146, 78.8364, 35.7978, 59.2285
	dq 21.4178, 93.7213, 86.9747, 84.6704
	dq 66.4558, 55.9662, 42.8877, 85.2384
	dq 56.3416, 89.6338, 92.5953, 49.3383
	dq 56.5091, 27.3342, 24.6505, 26.3363
	dq 48.7431, 89.8911, 91.4547, 55.4419
	dq 56.7622, 14.3683, 74.7872, 40.1324
	dq 16.1153, 25.5572, 96.3246, 17.1823
	dq 70.9497, 86.3067, 73.2716, 83.7514
        dq 13.3044, 88.9475, 10.5728, 47.7192
        dq 60.1799, 17.3599, 49.7649, 29.2834
        dq 78.3695, 65.1767, 16.1382, 42.4695
        dq 34.1846, 31.9914, 34.4178, 27.8526
        dq 45.6267, 21.4609, 15.9138, 50.8321
        dq 77.7549, 90.2378, 98.9639, 16.4445
        dq 51.8977, 44.9735, 58.8071, 72.5379
        dq 35.8724, 50.4568, 49.9156, 78.4696
        dq 70.3638, 21.7617, 76.5842, 15.6671
        dq 11.8031, 73.3283, 23.6018, 57.4999
        dq 14.5927, 93.4886, 31.2606, 86.8568
        dq 48.6059, 47.4624, 80.6854, 33.1866
        dq 13.3881, 26.5829, 49.3157, 54.4936
        dq 34.4001, 94.5774, 88.7957, 68.1369
        dq 59.2294, 30.1329, 35.7348, 90.2432
        dq 69.9121, 52.7796, 40.3943, 92.8107
        dq 73.6849, 37.2772, 32.4009, 65.4848
        dq 32.2929, 70.4639, 81.5465, 46.9074
        dq 45.9173, 51.9159, 55.3908, 22.4655
        dq 21.8142, 14.9566, 76.1419, 29.9408
        dq 73.1554, 14.3688, 57.3162, 65.2922
        dq 19.7722, 51.1682, 95.7296, 69.9513
        dq 63.8605, 29.2636, 67.1347, 30.2622
        dq 98.1059, 88.4107, 65.2256, 97.6399
        dq 10.3531, 42.1047, 81.1824, 89.3406
        dq 47.7718, 40.1701, 94.9699, 74.9835
        dq 89.4068, 26.7087, 47.8999, 64.8582
        dq 54.4832, 13.1075, 99.8717, 21.6319
        dq 79.9616, 74.9513, 79.8356, 77.6772
        dq 44.8489, 67.6278, 24.6221, 43.2115
        dq 39.8842, 42.9826, 90.6179, 71.8128
        dq 93.3456, 70.5589, 62.1663, 22.4629
N:
	dq ($ - sample) >> 3
fmt_output:
	db `σₙ = %g\n\0`

section .bss

extern printf
global main
section .text
main:
	push rbp
	mov rbp, rsp
	and rsp, -16

	mov rcx, qword [N]	; size of sample
        shr rcx, 2              ; # of groups of 4
	mov rdx, 0		; displacement
	vxorpd ymm0, ymm0, ymm0	; for sigma x_i
	vxorpd ymm1, ymm1, ymm1	; for sigma (x_i)^2

.Loop:
	vmovupd ymm2, [sample + rdx]
	vaddpd ymm0, ymm0, ymm2	; update sigma x_i
	vmulpd ymm2, ymm2, ymm2 ; compute squares
	vaddpd ymm1, ymm1, ymm2	; update sigma (x_i)^2
	add rdx, 8*4		; update displacement
	loopnz .Loop

        ; adding the components of ymm0: packed double --> scalar double
	vextractf128 xmm2, ymm0, 1
	vaddpd xmm0, xmm0, xmm2
	movapd xmm2, xmm0
	unpckhpd xmm2, xmm2
	addsd xmm0, xmm2

        ; adding the components of ymm1: packed double --> scalar double
	vextractf128 xmm2, ymm1, 1
	vaddpd xmm1, xmm1, xmm2
	movapd xmm2, xmm1
	unpckhpd xmm2, xmm2
	addsd xmm1, xmm2

        ; dividing by the same size N
	cvtsi2sd xmm2, qword [N]
	divsd xmm0, xmm2
	divsd xmm1, xmm2

        ; computing sqrt ((sum (x_i)^2)/n - (sum (x_i))^2/n)
	mulsd xmm0, xmm0
        vsubsd xmm0, xmm1, xmm0
	sqrtsd xmm0, xmm0

        ; printing
	mov rdi, fmt_output
	mov rax, 1
	call printf

	mov rax, 0
	mov rsp, rbp
	pop rbp
	ret

section .note.GNU-stack noalloc noexec
