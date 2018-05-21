section .bss
input_buffer resb 240000
output_buffer resb 240000
header resb 54

section .data
output_filename db 'scaled_image.bmp', 0

section .text
global func
func:
  push ebp
  mov ebp, esp

  mov r8, rsi ;output file witdth
  mov r9, rdx ;output file height

  ;open input file
  mov rsi, 0
  mov rax, 2 ;open file
  syscall

  mov r14, rax ;input file descriptor

  ;read input file header
  mov rax, 0 ;read from file
  mov rdi, r14 ;file handler
  mov rsi, header ;buffer
  mov rdx, 54 ;length
  syscall

  mov r10, dword [header+18] ;read input file width
  mov dword [header+18], r8 ;alter width of image in header

  mov r11, dword [header+22] ;read input file height
  mov dword [header+22], r9 ;alter height of image in header

  ;calculate number of bytes in output file row
  mov rbx, 24
  mov rax, r8
  mul rbx
  add rax, 31
  shr rax, 5
  shl rax, 2
  mov r12, rax ;number of bytes in output file row

  ;calculate number of bytes in input file row
  mov rbx, 24
  mov rax, r10
  mul rbx
  add rax, 31
  shr rax, 5
  shl rax, 2
  mov r13, rax ;number of bytes in input file row

  ;calculate size of data array in output file
  mov rax, r9
  mul r12
  mov dword [header+34], rax ;alter size of data array in header

  ;open output file
  mov rdi, output_filename
  mov rsi, 0
  mov rax, 2 ;open file
  syscall

  mov r15, rax ;output file descriptor

  ;write header to output file
  mov rdx, 54 ;length
  mov rsi, header ;buffer
  mov rdi, r15 ;ouput file handler
  mov rax, 1 ;write to file
  syscall

  ;init scaling loop values
  mov rbx, r9 ;j = destHeight -1
  dec rbx

  mov rcx, r11 ;currentRow = srcHeight

  ;calculate ratios
  mov rax, r10
  shl rax, 16
  mov rdx, 0
  idiv r8
  mov r10, rax ;ratioX

  mov rax, r11
  shl rax, 16
  mov rdx, 0
  idiv r11
  mov r11, rax ;ratioY

  cmp rbx, 0
  jl exit

scalling_loop:
  mov rax, rbx
  mul r11
  shr rax, 16
  cmp rax, rcx
  je end_read_loop

read_loop:
  ;read row from input file
  mov rax, 0
  mov rdi, r14
  mov rsi, input_buffer
  mov rdx, r13
  syscall

  dec rcx
  mov rax, rbx
  mul r11
  shr rax, 16
  cmp rax, rcx
  jne read_loop

end_read_loop:
  mov r9, 0
  cmp r9, r8
  jge write_row
fill_buffer_loop:
  mov rax, r10
  mul r9
  shr rax, 16

  mov rbx, r9
  mov rsi, rax
  mul 3
  add rax, input_buffer
  mov rdi, byte [eax]
  mov rax, rbx
  mul 3
  add rax, output_buffer
  mov byte [eax], rdi
  inc rsi
  inc rbx
  mov rax, rsi
  mul 3
  add rax, input_buffer
  mov rdi, byte [eax]
  mov rax, rbx
  mul 3
  add rax, output_buffer
  mov byte [eax], rdi
  inc rsi
  inc rbx
  mov rax, rsi
  mul 3
  add rax, input_buffer
  mov rdi, byte [eax]
  mov rax, rbx
  mul 3
  add rax, output_buffer
  mov byte [eax], rdi

  inc r9
  cmp r9, r8
  jl fill_buffer_loop

write_row:
  ;write row to output file
  mov rax, 1
  mov rdx, r12
  mov rsi, output_buffer
  mov rdi, r15

  dec rbx
  cmp rbx, 0
  jge scalling_loop

exit:
  ;close input file
  mov rdi, r14
  mov rax, 3
  syscall

  ;close output file
  mov rdi, r15
  mov rax, 3
  syscall
