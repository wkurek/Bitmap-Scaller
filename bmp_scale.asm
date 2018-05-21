section .bss
input_buffer resb 240000
output_buffer resb 240000
header resb 54

section .data
output_filename db 'scaled_image.bmp', 0

section .text
global func
func:
  push rbp
  mov rbp, rsp

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

  mov r10, 0
  mov r10d, dword [header+18] ;read input file width
  mov dword [header+18], r8d ;alter width of image in header

  mov r11, 0
  mov r11d, dword [header+22] ;read input file height
  mov dword [header+22], r9d ;alter height of image in header

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
  mov dword [header+34], eax ;alter size of data array in header

  push r11 ;preserve value in r11

  ;open output file
  mov rdi, output_filename
  mov rsi, 0102o
  mov rax, 2 ;open file
  mov rdx, 0666o
  syscall

  mov r15, rax ;output file descriptor

  ;write header to output file
  mov rdx, 54 ;length
  mov rsi, header ;buffer
  mov rdi, r15 ;ouput file handler
  mov rax, 1 ;write to file
  syscall

  pop r11 ;restore r11 from stack

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
  idiv r9
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
  push r11 ;preserve value in r11
  push rcx ;preserve value in r11

  ;read row from input file
  mov rax, 0
  mov rdi, r14
  mov rsi, input_buffer
  mov rdx, r13
  syscall

  pop rcx ;restore rcx from stack
  pop r11 ;restore r11 from stack

  dec rcx
  mov rax, rbx
  mul r11
  shr rax, 16

  cmp rax, rcx
  jne read_loop

end_read_loop:
  push rbx
  mov r9, 0
  cmp r9, r8
  jge write_row
fill_buffer_loop:
  mov rax, r10
  mul r9
  shr rax, 16

  mov rdi, 3
  mul rdi
  add rax, input_buffer
  mov rsi, rax ;rsi = address of pixel in input_buffer

  mov rax, r9
  mul rdi
  add rax, output_buffer
  mov rbx, rax ;rbx = address of pixel in output file

  mov rax, rsi
  mov dl, byte [eax] ;read first byte of pixel from input_buffer

  mov rax, rbx
  mov byte [eax], dl ;write first byte of pixel to output_buffer

  inc rsi
  inc rbx

  mov rax, rsi
  mov dl, byte [eax] ;read second byte of pixel from input_buffer

  mov rax, rbx
  mov byte [eax], dl ;write second byte of pixel to output_buffer

  inc rsi
  inc rbx

  mov rax, rsi
  mov dl, byte [eax] ;read third byte of pixel from input_buffer

  mov rax, rbx
  mov byte [eax], dl ;write third byte of pixel to output_buffer

  inc r9
  cmp r9, r8
  jl fill_buffer_loop

write_row:
  push r11 ;preserve r11 value
  push rcx ;preserve value of rcx

  ;write row to output file
  mov rax, 1
  mov rdx, r12
  mov rsi, output_buffer
  mov rdi, r15
  syscall

  pop rcx ;restore rcx from stack
  pop r11 ;restore r11 from stack

  pop rbx
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

  mov rsp, rbp
  pop rbp
  ret
