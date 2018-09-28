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
	
	
	lw $s1, 0($a1) # Tamanho do arquivo com cabecalho
	lw $s2, 8($a1) # Offset para comeÃ§o dos dados da imagem
	lw $s3, 16($a1) # Largura da imagem em pixels
	lw $s4, 20($a1) # Altura da imagem em pixels 
	sub $s1, $s1, $s2 #tamanho do arquivo sem cabeçalho (tamanho da imagem)
	

	move $t0, $zero
	li $t1, 0x10040000 #Prepara o endereÃ§o da memoria heap para armazenar a imagem
	
	load_image:
	
	beq $t0, $s1, exit_load_image
	sb $zero, 3($t1)
	li $a2, 3
	la $a1, men1
	jal read_file
	
	lbu $t2, 0($a1)
	sb $t2, 0($t1)
	lbu $t2, 1($a1)
	sb $t2, 1($t1)
	lbu $t2, 2($a1)
	sb $t2, 2($t1)
	addi $t0, $t0, 3 
	addi $t1, $t1, 4
	j load_image
	
	exit_load_image: 
	
	move $a0, $s0
	jal close_file
	jal turn_image
	li $a0, 0x10040000
	move $a1, $s1 
	jal save_original_image
	move $a0, $fp
	move $a1, $s1
	jal show_original_image
	j exit
	 
	
	
	open_file: #Funcao abre arquivo que recebe como argumento em $a0 o endereÃ§o onde esta armazenado o 
	# nome do arquivo e em $a1 a flag (0 - read, 1-write) e retorna em $v0 0 descritor do arquivo.
	
	li $v0, 13
	li $a2, 0
	syscall
	jr $ra

	read_file: #Funcao ler arquivo que recebe como argumento em $a0 o descritor do arquivo, em $a1 o endereÃ§o do buffer 
	# na memoria e em $a2 o numero de bytes a serem lidos e retorna em $v0 o numero de bytes lidos ou 0 caso final do arquivo.
	
	li $v0, 14
	syscall
	jr $ra
	
	close_file:#Funcao fecha arquivo que recebe como argumento em $a0 o descritor do arquivo.
		
	li $v0, 16
	syscall
	jr $ra
	
	
###################################################################
# vira a imagem para deixar ela na forma de visualização correta 
turn_image: 
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

jr $ra
###################################################################################	

save_original_image: #Funcao que recebe como parametros: 1) o endereço da memoria onde foi carregada a imagem em $a0(memoria heap 0x10040000)
#2) o tamanho da imagem em bytes em $a1($s1). Esta funcao decrementa $gp de acordo com o tamanho da imagem(largura*altura*4(word))pega 
#os bytes da imagem original carregada na memoria heap e salva na pilha depois carrega o valor de $gp em $fp e retorna $fp como uma 
#barreira para que demais procedimentos nao ultrapasse $fp e extravie os dados referentes a imagem original.

	add $t0, $0,$0
	move $t1, $a0 #Endereço da memoria heap
	
	#Decrementando a pilha com um tamanho da imagem
	move $t2, $sp
	div $t3, $a1, 3 #$a1/3 == Quantidade de pixels da imagem
	add $t3, $t3, $a1 #$t3 = 4vezes a quantidade de pixels(tamanho da imagem na memoria heap)(pois cada pixel possui 4 bytes, ou uma word)
	sub $sp, $sp, $t3 #Abre o espaço na pilha

	Loop_save_image:#Loop que carrega word da memoria heap e salva na pilha de cima para baixo
		beq $t0, $a1, end_save_original_image
		lw $t3, 0($t1)
		sw $t3, 0($t2)
		addi $t2, $t2, -4
		addi $t1, $t1, 4
		addi $t0, $t0, 3
		j Loop_save_image
end_save_original_image:
	move $fp, $sp #Carrega em $fp o limite onde começa os dados da imagem original na pilha
	jr $ra


show_original_image: # Funcao que recebe como parametros: 1) O endereço de delimitador $fp da pila onde se encontra a imagem original em $a0
#2) o tamanho da imagem em bytes em $a1($s1). Esta funcao carrega a imagem original na memoria heap para ser mostrada no bitmap display


	move $t0, $a0
	
	#Soma o endereço de base da memoria heap com o tamanho da imagem original (abre espaço na memoria heap)
	li $t1, 0x10040000
	div $t2, $a1, 3
	add $t2, $t2, $a1
	add $t1, $t1, $t2
	move $t2, $zero
	Loop_show_image: #Loop que desempilha os pixels de tras pra frente e ja carrega na posicao correta na memoria heap
		beq $t2, $a1, exit_show_original_image
		lw $t3, 0($t0)
		sw $t3, 0($t1)
		addi $t0, $t0, 4
		addi $t1, $t1, -4
		addi $t2, $t2, 3
		j Loop_show_image
exit_show_original_image:
		jr $ra



#####################################################################################################################################



	
exit: 
	li $v0, 10
	syscall 
