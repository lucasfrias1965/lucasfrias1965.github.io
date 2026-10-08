#
# <@)
# (KU//
#  ""
# LUCAS FRIAS
# LAB 04 FOR EECS 210
# UNIVERSITY OF KANSAS
# DATE 22ND OF SEPT
# DESCRPTION: 
# A FAST MODULU EXPON
# NENTIATION LAB THAT
# TAKES USER INPUT AND
# RETURNS B^N MOD (M)
# WRITTEN IN X86 ASSEMBLY
# LINKING WITH GNU COREUTILS

.intel_syntax noprefix

.section .rodata


prompt_input:
    .string "Please input b, n, and m: "

out_err:
    .string "\nERROR!\nInput was malformed\nPlease input three numbers, seperated with spaces, between these ranges:\n 1 <= b <= 128, 1 <= n <= 512, 1 <= m <= 512.\n\nExample:\n\npardas@ku:~$ ./main\nPlease input b, n, and m: 23, 34, 57\nOutput is: 2\n0"

format:
    .string "%u ,%u ,%u"

out_format:       
    .string "Output is: %u\n"        


.section .bss 
    .lcomm num_b, 4
    .lcomm num_n, 4
    .lcomm num_m, 4
    .lcomm num_res, 4

.section .text
.globl main
.type main, @function

main:
    push rbp #set the current stack frame and pointer
    mov rbp, rsp #save it 

    #here are some extra stuff i have to save to stomp segfaults into dust
    push rbx     #we have to save this, even though we don't use it
    sub rsp, 8   #this sets our alginment to 16 bytes so we can just use gnucoreutils

    #printf(prompt)
    lea rdi, [rip + prompt_input] #do rip + prompt to get

    #the relative address of this instruction
    xor eax, eax #clear eax to prevent float bs
    call printf #syscall print

    #scanf for b,m,n
    lea rdi, [rip + format] #set our format
    lea rsi, [rip + num_b] #save the scanf to our num
    lea rdx, [rip + num_n] #we can store csv
    lea rcx, [rip + num_m] #because scanf implements it
 
    #okay sick we set our registers
    xor eax, eax
    call scanf

    #now we have to make sure we got 3 items exactly
    cmp eax, 3
    jne uh_oh

    #here's a large comparison block that makes sure
    #all the inputs are in range. jb is just if below
    #ja is jump if above
    cmp dword ptr [rip+num_b], 1
    jb uh_oh                       # b < 1?
    cmp dword ptr [rip+num_b], 128
    ja uh_oh                       # b > 128?
    cmp dword ptr [rip+num_n], 1  # n < 1?
    jb uh_oh
    cmp dword ptr [rip+num_n], 512 # n > 512?
    ja uh_oh
    cmp dword ptr [rip+num_m], 1 #m < 1?
    jb uh_oh
    cmp dword ptr [rip+num_m], 512 #m > 512
    ja uh_oh

    #now we move the n value to
    #our general purpose 32 bit
    #registers
    mov eax, [rip+num_b] #b
    mov ebx, [rip+num_n] #n
    mov ecx, [rip+num_m] #m
    #okay sick we set our variable registers
    #i'm basing this code on this method
    #https://math-sites.uncg.edu/sites/pauli/112/HTML/secfastexp.html
    #at the very bottom
   
    xor edx, edx #clear edx to remove garbage
    div ecx #in x86, when we use div,
    #certain registers are always used
    #eax is always the thing being divided (or dividend)
    #ecx is the thing being divided by (so m)
    #and edx is set to the remainder
    #the remainder is the modulus result
    #so this is b mod m

    mov eax, edx #now we set that as our base
    mov esi, 1 #set esi to the 1

    work_loop:
        #okay first we calculare the remainder of n (ebx)
        #mod 2 is either 0 or 1 and depends on the LSB's value and output
        #example 13 mod 2 is 1
        # we don't need to bitmask we can use test
        test ebx, ebx #is n == 0? we compare every bit and if a bit or a bit then its zero
        jz done #if n == 0 the zero flag is set
        #so we jump to done

        #now let's determine whether the LSB of 
        #n is set (or is n%2 == 1)
        test ebx, 1 
        jz square #jump to square if it is or not
       
        #okay we didn't jump which means this is a 0 bit

        push rax #push the full base register (tho we don't care about the upper 32 bits
        #to the stack to save when we do this operation

        #this is the part in the algorithm that calculates
        #the n == 0 part now

        mul esi #we multiply eax*esi and save it to edx
        #in our variable terms this is base*result = edx
        #or in the algorithm i linked to (a*c) 

        #now we have to get mod m. we do this by dividing by 
        #the value m and then the modulus is the remainder
        #at eax!!
        div ecx

        #here we divide by ecx. division is requried to be 64 bit
        #which kinda sucks but it's okay because eax SHOULD be zero
        #as we just multiplied, which sets edx to zero because the result
        #should not be negative

        #div ecx will divide eax/ecx (or in our case:

        # a*c (eax) / ecx (m) 
        # then the remainder is stored in edx
        # so edx = (a*c) mod m
        #edx has our new esi, our result
         
        mov esi, edx

        #returns the eax to what it should be
        pop rax

    square:

       #we need to set n to base^2 mod m
       #b^2 = eax^2 = eax * eax which mul does, edx is zero
       mul eax
       #now we divide eax by ecx, and store this at edx. 
       #same old same old. we store b^2 / m 's remainder 
       #(which is the modulus) at edx
       div ecx
       
       #this sets our new b (base). the url i sent
       #calls it c but it's just the thing we do
       #modulus for in our operations
       mov eax, edx #set our new b
       
       #shifts ebx down by 1, which essentially
       #divides it by two, nothing too suprising
       shr ebx, 1 
       jmp work_loop 

    done:
        mov [rip+num_res], esi        # save the result
        lea rdi, [rip + out_format]   # get the printf string arg
        #we're smarty pants so we already set esi to our result
        #to print later
        xor eax, eax                  # removing floating point stuff
        call printf                  

    xor eax, eax            #set our zero return
    #push back the normal spacing
    add rsp, 8
    #return rbx, rbp from all the stack
    pop rbx
    pop rbp
    #ret our program, we're done
    ret

uh_oh:

    lea rdi, [rip + out_err] 

    xor eax, eax 
    call printf 
    
    add rsp, 8
    mov eax, 1

    pop rbx
    pop rbp
    
    ret


