
#Abrir o site Tesouro direto e retirar informações dos valores dos titulos. 
## Pacotes para execução das funções
library(Hmisc)
library(date)
library(zoo)
memory.limit(size = 4000)
library(sqldf)
library(stringr)
library(XML)
library(kulife)
library(xml2)
library(foreign)
library(rvest)

# 1 jeito
#movie<- read_html("http://www.tesouro.fazenda.gov.br/tesouro-direto-precos-e-taxas-dos-titulos")
#movie %>% html_node(".camposTesouroDireto:nth-child(1)") %>% html_text()
#movie %>% html_node(".camposTesouroDireto:nth-child(2)") %>% html_text()
#movie %>% html_node(".camposTesouroDireto:nth-child(3)") %>% html_text()
#ou

# 2 jeito e mais interessante

url="http://www.tesouro.fazenda.gov.br/tesouro-direto-precos-e-taxas-dos-titulos"
#setwd("C:/Users/angelo/GitAngelo/R/Titulos Publicos")
setwd("C:/Users/ajzan/Documents/GitHub/Tesouro-Direto/DataBase")

page = read_html(url)
Tesouro.nodes = html_nodes(page,'.camposTesouroDireto')

tam<-length(Tesouro.nodes)

idnome<-1
iddata<-2
idtaxacompra<-3
idtaxavenda<-4
idvalorcompra<-5
idvalorvenda<-6

i<-1
while(i<=tam){
	nome<-substr(xml_find_all(Tesouro.nodes[i], ".//td")[idnome], str_locate(xml_find_all(Tesouro.nodes[i], ".//td")[idnome], "listing0")[,2]+3,str_locate(xml_find_all(Tesouro.nodes[i], ".//td")[idnome], "</td>")[,1]-1)
	data<-substr(xml_find_all(Tesouro.nodes[i], ".//td")[iddata], str_locate(xml_find_all(Tesouro.nodes[i], ".//td")[iddata], "listing")[,2]+3,str_locate(xml_find_all(Tesouro.nodes[i], ".//td")[iddata], "</td>")[,1]-1)
	taxacompra<-substr(xml_find_all(Tesouro.nodes[i], ".//td")[idtaxacompra], str_locate(xml_find_all(Tesouro.nodes[i], ".//td")[idtaxacompra], "listing taxaprecos")[,2]+3,str_locate(xml_find_all(Tesouro.nodes[i], ".//td")[idtaxacompra], "</td>")[,1]-1)
	taxavenda<-substr(xml_find_all(Tesouro.nodes[i], ".//td")[idtaxavenda], str_locate(xml_find_all(Tesouro.nodes[i], ".//td")[idtaxavenda], "listing taxaprecos")[,2]+3,str_locate(xml_find_all(Tesouro.nodes[i], ".//td")[idtaxavenda], "</td>")[,1]-1)
	valorcompra<-substr(xml_find_all(Tesouro.nodes[i], ".//td")[idvalorcompra], str_locate(xml_find_all(Tesouro.nodes[i], ".//td")[idvalorcompra], "listing taxaprecos")[,2]+3,str_locate(xml_find_all(Tesouro.nodes[i], ".//td")[idvalorcompra], "</td>")[,1]-1)
	valorvenda<-substr(xml_find_all(Tesouro.nodes[i], ".//td")[idvalorvenda], str_locate(xml_find_all(Tesouro.nodes[i], ".//td")[idvalorvenda], "listing taxaprecos")[,2]+3,str_locate(xml_find_all(Tesouro.nodes[i], ".//td")[idvalorvenda], "</td>")[,1]-1)
	if(i==1){
		tituloini<-cbind(nome, data, taxacompra, taxavenda, valorcompra, valorvenda)
		titulo<-tituloini
	} else {
		titulopos<-cbind(nome, data, taxacompra, taxavenda, valorcompra, valorvenda)
		titulo<-rbind(titulo,titulopos)
	}
	i=i+1
}

titulo<-as.data.frame(titulo)
tamdata<-nchar(as.character(titulo$data))
datatit<-0
reduz<-0
i=1
while(i<=tam){
	if(tamdata[i]==11){
		reduz[i]<-0
	}else{
		reduz[i]<-1
	}
#titulo$data[i]<-paste(substring(titulo$data[i],2-reduz[i],3-reduz[i]),substring(titulo$data[i],5-reduz[i],6-reduz[i]),substring(titulo$data[i],8-reduz[i],11-reduz[i]),sep="/")
	datatit[i]<-format(as.Date(paste(substring(titulo$data[i],8-reduz[i],11-reduz[i]),substring(titulo$data[i],5-reduz[i],6-reduz[i]),substring(titulo$data[i],2-reduz[i],3-reduz[i]),sep="-")), format="%d%m%Y")
	i=i+1
}
titulo$data<-datatit

titulo$taxacompra<-as.numeric(as.character(gsub(",",".",gsub("[R$]","",gsub("[.]","",gsub(" ","",titulo$taxacompra))))))
titulo$taxavenda<-as.numeric(as.character(gsub(",",".",gsub("[R$]","",gsub("[.]","",gsub(" ","",titulo$taxavenda))))))
titulo$valorcompra<-as.numeric(as.character(gsub(",",".",gsub("[R$]","",gsub("[.]","",gsub(" ","",titulo$valorcompra))))))
titulo$valorvenda<-as.numeric(as.character(gsub(",",".",gsub("[R$]","",gsub("[.]","",gsub(" ","",titulo$valorvenda))))))

titulo[is.na(titulo)] <- "-"

#formatar a base em formato para salvar 
Taxacompra<-as.data.frame(cbind(as.data.frame(titulo$nome), titulo$data,titulo$taxacompra))
Taxavenda<-as.data.frame(cbind(as.data.frame(titulo$nome), titulo$data,titulo$taxavenda))
Valorcompra<-as.data.frame(cbind(as.data.frame(titulo$nome), titulo$data,titulo$valorcompra))
Valorvenda<-as.data.frame(cbind(as.data.frame(titulo$nome), titulo$data,titulo$valorvenda))

datahoje<-format(Sys.Date(), format="%d%m%Y")
datahoje2<-page %>% html_nodes("b")
datahoje2<-format(paste(substring(datahoje2[13],10,13),substring(datahoje2[13],7,8),substring(datahoje2[13],4,5),sep="-"), format="%d%m%Y")
if(datahoje!=datahoje2){
	datahoje<-datahoje2
}

names(Taxacompra) <-  c("Nome", "DataVenc", paste("dt",datahoje,sep=""))
names(Taxavenda) <-  c("Nome", "DataVenc", paste("dt",datahoje,sep=""))
names(Valorcompra) <-  c("Nome", "DataVenc", paste("dt",datahoje,sep=""))
names(Valorvenda) <-  c("Nome", "DataVenc", paste("dt",datahoje,sep=""))

#ler a base em txt antiga
Taxacompraantigo<-read.table(file=paste(getwd(),"Taxa_Compra.txt", sep="/"), sep="\t", dec=",", header=TRUE)
Taxavendaantigo<-read.table(file=paste(getwd(),"Taxa_Venda.txt", sep="/"), sep="\t", dec=",", header=TRUE)
Valorcompraantigo<-read.table(file=paste(getwd(),"Valor_Compra.txt", sep="/"), sep="\t", dec=",", header=TRUE)
Valorvendaantigo<-read.table(file=paste(getwd(),"Valor_Venda.txt", sep="/"), sep="\t", dec=",", header=TRUE)

#Se eu estiver pegando as informações do mesmo dia novamente, não devemos alterar o arquivo final. Pois gera redundancia
if((names(Taxacompra[ncol(Taxacompra)])!=names(Taxacompraantigo[ncol(Taxacompraantigo)]))){
	#se não tiver o primeiro arquivo, não executar merge
	if(exists("Taxacompraantigo")==TRUE){
		#ajustar a data do arquivo baixado, pois está retirando o zero a esquerda
		tamdataantigo<-nchar(as.character(Taxacompraantigo$DataVenc))
		i=1
		tam<-nrow(Taxacompraantigo)
		while(i<=tam){
			if(tamdataantigo[i]==7){
				Taxacompraantigo$DataVenc[i]<-paste("0",Taxacompraantigo$DataVenc[i],sep="")
				Taxavendaantigo$DataVenc[i]<-paste("0",Taxavendaantigo$DataVenc[i],sep="")
				Valorcompraantigo$DataVenc[i]<-paste("0",Valorcompraantigo$DataVenc[i],sep="")
				Valorvendaantigo$DataVenc[i]<-paste("0",Valorvendaantigo$DataVenc[i],sep="")
			}
			i=i+1
		}
		#Agrupar as tabelas
		Taxacompraantigo<-merge(Taxacompraantigo, Taxacompra, by.x = c("Nome","DataVenc"), by.y = c("Nome","DataVenc"), all = TRUE)
		Taxavendaantigo<-merge(Taxavendaantigo, Taxavenda, by.x = c("Nome","DataVenc"), by.y = c("Nome","DataVenc"), all = TRUE)
		Valorcompraantigo<-merge(Valorcompraantigo, Valorcompra, by.x = c("Nome","DataVenc"), by.y = c("Nome","DataVenc"), all = TRUE)
		Valorvendaantigo<-merge(Valorvendaantigo, Valorvenda, by.x = c("Nome","DataVenc"), by.y = c("Nome","DataVenc"), all = TRUE)

		Taxacompraantigo[is.na(Taxacompraantigo)] <- "-"
		Taxavendaantigo[is.na(Taxavendaantigo)] <- "-"
		Valorcompraantigo[is.na(Valorcompraantigo)] <- "-"
		Valorvendaantigo[is.na(Valorvendaantigo)] <- "-"
	} else {
		Taxacompraantigo<-Taxacompra
		Taxavendaantigo<-Taxavenda
		Valorcompraantigo<-Valorcompra
		Valorvendaantigo<-Valorvenda
	}

	#salvar as tabelas
	write.table(Taxacompraantigo, file=paste(getwd(),"Taxa_Compra.txt", sep="/"), sep="\t", dec=",",row.names = FALSE, col.names = TRUE, quote = FALSE)
	write.table(Taxavendaantigo, file=paste(getwd(),"Taxa_Venda.txt", sep="/"), sep="\t", dec=",",row.names = FALSE, col.names = TRUE, quote = FALSE)
	write.table(Valorcompraantigo, file=paste(getwd(),"Valor_Compra.txt", sep="/"), sep="\t", dec=",",row.names = FALSE, col.names = TRUE, quote = FALSE)
	write.table(Valorvendaantigo, file=paste(getwd(),"Valor_Venda.txt", sep="/"), sep="\t", dec=",",row.names = FALSE, col.names = TRUE, quote = FALSE)
}
#################### termino dos titulos publicos ##########################
#Verificar juros futuro
url="http://www2.bmf.com.br/pages/portal/bmfbovespa/boletim1/BoletimOnline1.asp?caminho=&pagetype=pop&Acao=BUSCA&cboMercadoria=DI1"
page = read_html(url)

#Juros.nodes = html_nodes(page,'tabConteudo')
#verificar o que tem na pesquisa focus e no relatorio do bacen de taxa de juros