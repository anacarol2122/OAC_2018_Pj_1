.data
	
	
	filename: .asciiz "lena.bmp"
	men: .space 2
	.align 2
	men1: .space 52

.text

	
	la $a0, filename
	li $a1, 0
	jal open_file
	
	move $s0, $v0 #salva o descritor original do arquivo em $s0
	move $a0, $v0
	la $a1, men
	li $a2, 2
	jal read_file
	
	li $a2, 52
	la $a1, men1
	jal read_file
	
	
	lw $s1, 0($a1) # Tamanho do arquivo
	lw $s2, 8($a1) # Offset para comeÃ§o dos dados da imagem
	lw $s3, 16($a1) # Largura da imagem em pixels
	lw $s4, 20($a1) # Altura da imagem em pixels 

	move $t0, $zero
	li $t1, 0x10040000 #Prepara o endereÃ§o da memÃ³ria heap para armazenar a imagem
	
	show_original_image:
	
	beq $t0, $s1, exit_original_image
	sb $zero, 3($t1)
	li $a2, 3
	la $a1, men1
	jal read_file
	
	lbu $t2, 0($a1)
	sb $t2, 1($t1)
	lbu $t2, 1($a1)
	sb $t2, 2($t1)
	lbu $t2, 2($t1)
	sb $t2, 3($a1)
	addi $t0, $t0, 3 
	addi $t1, $t1, 4
	j show_original_image
	
	exit_original_image: 
	
	move $a0, $s0
	jal close_file
	j exit
	 
	
	
	open_file: #Funcao abre arquivo que recebe como argumento em $a0 o endereÃ§o onde esta armazenado o 
	# nome do arquivo e em $a1 a flag (0 - read, 1-write) e retorna em $v0 0 descritor do arquivo.
	
	li $v0, 13
	li $a2, 0
	syscall
	jr $ra
	
###################################################################
# vira a imagem para deixar ela na forma de visualização correta 
close_file: #Funcao fecha arquivo que recebe como argumento em $a0 o descritor do arquivo.
la $t0,0x10040000
addi $t1,$s3,-1 # sendo $s3 o uma das dimensões do arquivo 
mul $t1,$t1,4  # sendo multiplicado para achar o vavor do endereço correto
mul $t1,$t1,$s4 # sendo $s4 a altra dimensão do aquivo
add $t1,$t1,$t0 # somando com o endereço base para encontrar o endereço correto
div $t2,$s4,2 # dividindo a altura por dois para encontrar o ponto de parada 

loop2: # loop para virar a immagem
	lw $s5,($t0) # carregando os valores das words de forma equidistante em relação a horizontal
	lw $s6,($t1) # carregando os valores das words de forma equidistante em relação a horizontal
	sw $s6,($t0) # trocando
	sw $s5,($t1) # trocando
	addi $t0,$t0,4 # indo p próximo
	addi $t1,$t1,4 # indo p proximo
	addi $t3,$t3,1 # contado de largura 
	beq $t3,$s3,sai2 # ferificando se chegou ao vinda da largura
	j loop2
sai2:
	li $t3, 0 # carrega zero para a proxima linha da matriz de pixels 
	mul $t4,$s3,8 # tamanho em em bytes de dus linha de pixels 
	sub $t1,$t1,$t4 # subtrai de $t1 que se encontra no final da matriz de pixels
	addi $t5,$t5,1 # contador 
	beq $t5,$t2,sai3 # condição de parada da função de virar o arquivo
	j loop2
sai3:
###################################################################################	
	
	li $v0, 16
	syscall
	jr $ra
	
	read_file: #Funcao ler arquivo que recebe como argumento em $a0 o descritor do arquivo, em $a1 o endereÃ§o do buffer 
	# na memoria e em $a2 o numero de bytes a serem lidos e retorna em $v0 o numero de bytes lidos ou 0 caso final do arquivo.
	
	li $v0, 14
	syscall
	jr $ra
	
	exit: 
	li $v0, 10
	syscall 
