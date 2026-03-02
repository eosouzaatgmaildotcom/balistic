{ Projeto final  -  FNC 232 - Linguagens de Programacao Cientifica e
                              Tecnicas Eficientes de Programacao
                                                                     }

{$N+}

program trajetorias;

uses crt, graph;

type frase = string[65];
     formangulo = string[9];

const pi = 3.14159265359;

var massa, diametro, Vo,                     { Caracteristicas do projetil                   }
    alcance, epslon,                         { Alcance e erro desejado                       }
    ro, gravidade, Vsom,                     { Caracteristicas do meio                       }
    deltaT,                                  { Intervalo de tempo para calculo da trajetoria }
    teta1, teta2, tempo1, tempo2,            { Angulo e tempo totais resultantes             }
    maxescala,                               { Valor maximo nos eixos do grafico             }
    ku1, ku2, ku3, ku4, kv1, kv2, kv3, kv4,  { Parametros para o calculo dos Range-Kutta 4   }
    kx1, kx2, kx3, kx4, ky1, ky2, ky3, ky4,
    ltiro, letiro, mtiro:double;             { Alcance do ultimo, penultimo e melhor tiro    }
    last, lastest:real;                      { Angulo do ultimo e penultimo disparo          }
    graphdriver, graphmode, i:integer;       { Tipo de video grafico escolhido               }
    teclaespera :char;                       { Local de retorno para a funcao READKEY        }
    porcima, porbaixo:boolean;               { Sucesso da busca por cima e por baixo         }

{---------------------------------------------------------------------------}
procedure mensagem(mensagem:frase;beep:boolean);

{ Objetivo         : escrever mensagem no video, na linha adequada.
  Dados de Entrada : frase - string - frase a ser escrita
                     beep - boolean - toca o beep ou nao
  Dados de Saida   : -------                                                }

var temporizador:integer;       { Variavel para manter o sinal sonoro }

begin

   { produz sinal sonoro de alerta }
   if beep then
   begin
      for temporizador:=1 to 1000 do sound(600);
      nosound;
   end;

   { escreve mensagem }
   gotoxy(14,19); write('                                                                 ');
   gotoxy(14,19); write(mensagem);

end;

{---------------------------------------------------------------------------}
procedure desenhagrade;

{ Objetivo         : desenha grades para tracejamento das trajetorias.
  Dados de Entrada : -------
  Dados de Saida   : -------                                                }

begin

   { inicializa modo de video grafico }
   directvideo:=TRUE;
   detectgraph(graphdriver,graphmode);
   initgraph(graphdriver,graphmode,'');

   { seleciona fonte de caracteres : SMALL FONT = 2
                                     HORIZONTAL = 0
                                     TAMANHO    = 4 }
   settextstyle(2,0,4);

   { desenha eixos }
   line(15,14,15,189);
   line(15,189,470,189);
   outtextxy(362,190,'eixo X - Horizontal');
   outtextxy(0,0,'eixo Y - Vertical');
   outtextxy(200,0,'TRAJETORIAS DO PROJETIL');
   line(200,12,334,12);

   { desenha tabela de resultados }
   rectangle(475,0,639,151);
   line(475,36,639,36);
   line(475,71,639,71);
   line(475,106,639,106);
   outtextxy(495,3,'Angulos de Disparo');
   outtextxy(495,13,'Teta1 =');
   outtextxy(495,23,'Teta2 =');
   outtextxy(495,38,'Tempo de Voo');
   outtextxy(495,48,'Tempo1 =');
   outtextxy(495,58,'Tempo2 =');
   outtextxy(495,73,'Velocidade de Impacto');
   outtextxy(495,83,'Vel.1 =');
   outtextxy(495,93,'Vel.2 =');
   outtextxy(495,108,'Erro no alvo');
   outtextxy(495,118,'(+/- 10 min. em Teta)');
   outtextxy(495,128,'Erro1 =');
   outtextxy(495,138,'Erro2 =');

end;

{---------------------------------------------------------------------------}
function cd(ui,vi:double):double;

{ Objetivo         : fornece o CD correspondente a velocidade.
  Dados de Entrada : ui - double - componente horizontal da velocidade
                     vi - double - componente vertical da velocidade
  Dados de Saida   : cds - double - coeficiente de arrasto                    }


var m, cds:array [1..9] of double;  { Tabela de numero de MATCH e CDS, respectivamente }
    mn,                             { Numero de MATCH do projetil                      }
    v,                              { Velocidade instantanea do projetil               }
    cdaux:double;                   { Variavel auxiliar para busca do CD               }

begin

   { armazena tabela de valores MATCH x CD }
   m[1]:=0.0; m[2]:=0.5; m[3]:=0.75; m[4]:=1.0; m[5]:=1.25; m[6]:=1.5;
   m[7]:=2.0; m[8]:=2.5; m[9]:=3.0;
   cds[1]:=1.6; cds[2]:=1.8; cds[3]:=2.1; cds[4]:=4.8; cds[5]:=5.8; cds[6]:=5.4;
   cds[7]:=4.8; cds[8]:=4.2; cds[9]:=3.9;

   { define numero MATCH }
   v:=sqrt(sqr(ui)+sqr(vi));
   mn:=v/Vsom;

   { busca o valor de CD na tabela }
   i:=1;
   while (m[i]<mn) and (i<=9) do i:=i+1;
   if i=10 then cdaux:=cds[9]
           else if (m[i]-mn) > (mn-m[i-1]) then cdaux:=cds[i-1]
                                           else cdaux:=cds[i];
   cd:=cdaux;

end;

{---------------------------------------------------------------------------}
function f(a,b:double):double;

{ Objetivo         : auxilio no calculo dos K's.
  Dados de Entrada : a - double - componente horizontal da velocidade em pontos estrategicos
                     b - double - componente vertical da velocidade em pontos estrategicos
  Dados de Saida   : -------                                                }

begin
   f:=-(cd(a,b)*pi*sqr(diametro)*ro*sqrt(sqr(a)+sqr(b))*a)/(8*massa);
end;

{---------------------------------------------------------------------------}
function g(a,b:double):double;

{ Objetivo         : auxilio no calculo dos K's.
  Dados de Entrada : a - double - componente horizontal da velocidade em pontos estrategicos
                     b - double - componente vertical da velocidade em pontos estrategicos
  Dados de Saida   : -------                                                }

var area,           { Secao reta do projetil   }
    vseno:double;   { Componente da velocidade }

begin
   area:=sqr(diametro)*pi/4;
   vseno:=sqrt(sqr(a)+sqr(b))*b/2;
   g:=-gravidade-(cd(a,b)*area*ro*vseno/massa);
end;

{---------------------------------------------------------------------------}
procedure velocidades(var ui, vi:double; deltaT:double);

{ Objetivo         : calculo da velocidade num instante posterior
  Dados de Entrada : ui - double - componente horizontal da velocidade
                     vi - double - componente vertical da velocidade
                     deltaT - double - passo de incremento do instante
  Dados de Saida   : ui - double - componente horizontal da velocidade num instante posterior
                     vi - double - componente vertical da velocidade num instante posterior }

begin

   ku1:=0.0;ku2:=0.0;ku3:=0.0;ku4:=0.0;
   kv1:=0.0;kv2:=0.0;kv3:=0.0;kv4:=0.0;

   { calculo dos parametros K's }
   ku1:=f(ui,vi); kv1:=g(ui,vi);
   ku2:=f(ui+deltaT*ku1/2,vi+deltaT*kv1/2);
   kv2:=g(ui+deltaT*ku1/2,vi+deltaT*kv1/2);
   ku3:=f(ui+deltaT*ku2/2,vi+deltaT*kv2/2);
   kv3:=g(ui+deltaT*ku2/2,vi+deltaT*kv2/2);
   ku4:=f(ui+deltaT*ku3,vi+deltaT*kv3);
   kv4:=g(ui+deltaT*ku3,vi+deltaT*kv3);

   { calculo das velocidades posteriores }
   ui:=ui+deltaT*(ku1+2*ku2+2*ku3+ku4)/6;
   vi:=vi+deltaT*(kv1+2*kv2+2*kv3+kv4)/6;

end;

{---------------------------------------------------------------------------}
procedure xi(var x:double;u,deltaT:double);

{ Objetivo         : calculo da posicao x posterior do projetil.
  Dados de Entrada : x - double - posicao atual do projetil
                     u - double - velocidade horizontal do projetil
                     deltaT - double - incremento de tempo
  Dados de Saida   : x - double - posicao posterior do projetil              }

begin

   { calculo dos parametros K's }
   kx1:=0.0;kx2:=0.0;kx3:=0.0;kx4:=0.0;
   kx1:=u;
   kx2:=u+deltaT*kx1/2;
   kx3:=u+deltaT*kx2/2;
   kx4:=u+deltaT*kx3;

   { calculo da posicao posterior }
   x:=x+deltaT*(kx1+2*kx2+2*kx3+kx4)/6;

end;

{---------------------------------------------------------------------------}
procedure yi(var y:double;v,deltaT:double);

{ Objetivo         : calculo da posicao y posterior do projetil.
  Dados de Entrada : y - double - posicao atual do projetil
                     v - double - velocidade vertical do projetil
                     deltaT - double - incremento de tempo
  Dados de Saida   : y - double - posicao posterior do projetil              }

begin

   { calculo dos parametros K's }
   ky1:=0.0;ky2:=0.0;ky3:=0.0;ky4:=0.0;
   ky1:=v;
   ky2:=v+deltaT*ky1/2;
   ky3:=v+deltaT*ky2/2;
   ky4:=v+deltaT*ky3;

   { calculo da posicao posterior }
   y:=y+deltaT*(ky1+2*ky2+2*ky3+ky4)/6;

end;

{---------------------------------------------------------------------------}
function radxdeg(angulo:real):formangulo;

{ Objetivo         : converte um angulo de radianos para degrados (0 a 90).
  Dados de Entrada : angulo - real - angulo em radianos
  Dados de Saida   :        - string - string do angulo em degrados         }

type doischar = string[2];

var angs, graus, min, seg, resto:real;  { Variaveis para decomposicao do angulo }
    sgraus, smin, sseg:doischar;        { Strings dos numeros do angulo         }

begin

   { conversao do angulo }
   angs:=int(round(angulo*648000/pi));
   graus:=trunc(angs/3600);
   resto:=angs-graus*3600;
   min:=trunc(int(resto/60));
   seg:=resto-min*60;

   { transformacao em string }
   str(graus:2:0,sgraus);
   str(min:2:0,smin);
   str(seg:2:0,sseg);
   radxdeg:=sgraus+'o'+smin+'m'+sseg+'s';

end;

{---------------------------------------------------------------------------}
function trajetoria(teta:real; var tempototal:double):double;

{ Objetivo         : calculo da posicao de colisao com o eixo x.
  Dados de Entrada : teta - real - angulo de disparo
  Dados de Saida   : posicao - double - posicao de colisao com o eixo x       }

var maior,                      { Maior dos parametros H           }
    u, v, x, y:double;          { Posicao e velocidade do projetil }
    h:array [1..4] of double;   { Relacao de parametros H          }
    sx, sy:string[13];          { String dos valores da posicao    }

begin

   { chute inicial }
   deltaT:=Vo/massa;

   { busca do deltaT adequado }
   repeat

      { ajuste do deltaT }
      deltaT:=deltaT/2;

      { definicao da condicoes iniciais }
      u:=Vo*cos(teta); x:=0;
      v:=Vo*sin(teta); y:=0;

      { calculo dos parametros de avaliacao }
      xi(x,u,deltaT);
      yi(y,v,deltaT);
      velocidades(u,v,deltaT);
      if (ku2=ku1) then h[1]:=0
                   else h[1]:=abs(ku3-ku2)/abs(ku2-ku1);
      if (kv2=kv1) then h[2]:=0
                   else h[2]:=abs(kv3-kv2)/abs(kv2-kv1);
      if (kx2=kx1) then h[3]:=0
                   else h[3]:=abs(kx3-kx2)/abs(kx2-kx1);
      if (ky2=ky1) then h[4]:=0
                   else h[4]:=abs(ky3-ky2)/abs(ky2-ky1);


      { procura o maior h[i]: para escolha do passo }
      maior:=0;
      for i:=1 to 4 do if h[i] > maior then maior:=h[i];

   until (maior<=0.01);

   { calculo da trajetoria }
   mensagem('C�lculo da trajet�ria para �ngulo '+radxdeg(teta),FALSE);
   delay(1800);
   u:=Vo*cos(teta); x:=0;
   v:=Vo*sin(teta); y:=0;
   tempototal:=deltaT;

   { Se o angulo e igual a 90 nao ha necessidade de calcular }
   if teta<>last then
   begin

      { Procura enquanto nao atingi o solo e nao sobrevoa o alvo }
      while (y>=0) and ((x<alcance) or (abs(alcance-x)<epslon)) do
      begin
         x:=abs(x);
         str(x:13:6,sx);
         str(y:13:6,sy);
         mensagem('Posi��o : x,y = '+sx+'   '+sy,FALSE);
         xi(x,u,deltaT);
         yi(y,v,deltaT);
         velocidades(u,v,deltaT);
         tempototal:=tempototal+deltaT;
      end;

   end;

   trajetoria:=x;

end;

{---------------------------------------------------------------------------}
procedure traca(angulo:real;tempo:double;posicao:integer);

{ Objetivo         : desenha a trajetoria percorrida pelo projetil.
  Dados de Entrada : angulo - real - angulo de disparo
                     tempo  - double - tempo total de voo
                     posicao - integer - referencia a posicao de escrita dos
                                         resultados (ex:. Tempo1 ou Tempo2)
  Dados de Saida   : -------                                                }

var xt, yt, vxt, vyt,                     { Posicao e velocidade do projetil              }
    erro1, erro2:double;                  { Erros no alcance com 10 min de erro no angulo }
    stempo, svimpacto, serro:string[13];  { String dos valores resultantes do disparo     }

begin

   { define novo valor de escala do grafico, caso nao o esteja
     e desenha grades para tracejamento das trajetorias                       }
   if maxescala=0.0 then
   begin

      mensagem('Escolhendo par�metros do gr�fico ...',FALSE);

      { define intervalo de tempo de acordo com espaco disponivel (455 colunas)}
      deltaT:=tempo/455;

      xt:=0.0;
      yt:=0.0;
      vxt:=Vo*cos(angulo);
      vyt:=Vo*sin(angulo);

      { define parametros para escolha da escala }
      while yt>=0.0 do
      begin
         if xt>maxescala then maxescala:=xt;
         if yt>maxescala then maxescala:=yt;
         xi(xt,vxt,deltaT);
         yi(yt,vyt,deltaT);
         velocidades(vxt,vyt,deltaT);
       end;

       desenhagrade;

   end;

   { apresenta valores de TETA e TEMPO TOTAL de voo }
   str(tempo:13:6,stempo);
   outtextxy(545,13+posicao,radxdeg(angulo));
   outtextxy(545,48+posicao,stempo);

   { desenha trajetoria }
   xt:=0.0;
   yt:=0.0;
   vxt:=Vo*cos(angulo);
   vyt:=Vo*sin(angulo);
   while yt>=0 do
   begin
      str(sqrt(sqr(vxt)+sqr(vyt)):13:6,svimpacto);
      putpixel(round(xt*(455/maxescala))+15,189-round(yt*(175/maxescala)),1);
      xi(xt,vxt,deltaT);
      yi(yt,vyt,deltaT);
      velocidades(vxt,vyt,deltaT);
   end;
   outtextxy(545,83+posicao,svimpacto);

   { define erros para +/- 10 min. de erro no angulo de disparo }
   xt:=0.0;
   yt:=0.0;
   vxt:=Vo*cos(angulo+pi/10800);
   vyt:=Vo*sin(angulo+pi/10800);
   while yt>=0 do
   begin
      erro1:=abs(alcance-xt);
      xi(xt,vxt,deltaT);
      yi(yt,vyt,deltaT);
      velocidades(vxt,vyt,deltaT);
   end;
   xt:=0.0;
   yt:=0.0;
   vxt:=Vo*cos(angulo-pi/10800);
   vyt:=Vo*sin(angulo-pi/10800);
   while yt>=0 do
   begin
      erro2:=abs(alcance-xt);
      xi(xt,vxt,deltaT);
      yi(yt,vyt,deltaT);
      velocidades(vxt,vyt,deltaT);
   end;

   { escolhe o maior erro entre as diferencas }
   if erro1>erro2 then str(erro1:13:6,serro)
                  else str(erro2:13:6,serro);
   outtextxy(545,128+posicao,serro);

end;

{---------------------------------------------------------------------------}
function achangulo(angulo, passo:real; var resangle, elaptime:double):boolean;

{ Objetivo         : encontrar angulos de disparo possiveis para determinado alcance
  Dados de Entrada : angulo - real - angulo inicial para busca
                     passo - double - incremento do angulo na busca
                     resangle - double - angulo onde a busca terminou
                     elaptime - double - tempo total de voo com resangle
  Dados de Saida   :    - boolean - .T. = alcance atingido
                        - boolean - .F. = alcance nao atingido              }

var acertouem,         { Alcance do disparo             }
    vertiro:double;    { Alcance do tiro de verificacao }

begin

   { Realizacao de um disparo }
   acertouem:=trajetoria(angulo,elaptime);

   { Se acertou retorna verdadeiro e o angulo resultante }
   if (abs(acertouem-alcance)<epslon) then
   begin
      resangle:=angulo;
      achangulo:=TRUE;
   end
   else
   begin

      { Se a diferenca entre o tiro atual e o tiro mais proximo do alvo for
        muito pequena, nao sera possivel acerta-lo, pois nao conseguira avan-
        car muito mais                                                       }
      if (abs(acertouem-mtiro)<epslon/1000) then achangulo:=FALSE

           { Se ultrapassou o alvo, comeca o novo processo com o ultimo angulo
             e o passo divido pela metade                                    }
      else if acertouem>alcance then
           begin

              { Precaucao para o fato de se estar tentando com valores de fra-
                coes de segundo de arco.                                     }
              if radxdeg(angulo)=' 0o 0m 0s' then achangulo:=FALSE
              else
              begin
                 mensagem('Refinando passo e recome�ando com o �ltimo �ngulo.',FALSE);
                 last:=lastest;
                 ltiro:=letiro;
                 achangulo:=achangulo(last+passo/2,passo/2,resangle,elaptime)
              end
           end

                { Se ainda nao chegou no alvo, e maior que o ultimo tiro, incre-
                  menta o angulo e tenta novamente. O resultado do novo processo
                  a partir da nova tentativa sera o retornado pela funcao       }
           else if (acertouem<alcance) and (acertouem>ltiro) then
                begin
                   mensagem('Incrementando �ngulo e tentando novamente.',FALSE);
                   lastest:=last;
                   letiro:=ltiro;
                   last:=angulo;
                   ltiro:=acertouem;
                   mtiro:=acertouem;
                   achangulo:=achangulo(angulo+passo,passo,resangle,elaptime)
                end
                else
                begin

                   { Tiro de verificacao }
                   vertiro:=trajetoria(last+passo/2,elaptime);

                   { Se o o tiro atual teve menor alcance que o ultimo, faze-
                     mos um tiro de verificacao para averiguar se o ultimo an-
                     gulo usado nao esta no outro dominio de angulos. Se esti-
                     ver e seguro que o penultimo nao estara. O processo e re-
                     tomado com um dos dois angulos, e o valor devolvido por
                     este novo processo sera o retornado pela funcao          }
                   if vertiro>ltiro then
                   begin
                      mensagem('Retomando processo com o �ltimo �ngulo.',FALSE);
                      achangulo:=achangulo(last+passo/2,passo/2,resangle,elaptime);
                   end
                   else
                   begin
                      mensagem('Retomando processo com o pen�ltimo �ngulo.',FALSE);
                      achangulo:=achangulo(lastest+passo/2,passo/2,resangle,elaptime);
                   end;
                end;
   end;
end;

{---------------------------------------------------------------------------}
begin

   { Executa o programa ate que se forneca uma massa igual a zero. }
   repeat

      { Zera variaveis }
      massa:=0.0; diametro:=0.0; Vo:=0.0; alcance:=0.0; epslon:=0.0; ro:=0.0;
      gravidade:=0.0; Vsom:=0.0; teta1:=0.0; teta2:=0.0; tempo1:=0.0;
      tempo2:=0.0; maxescala:=0;

      { Desenha tela de entrada de dados. }
      clrscr;
      writeln('�����������������������������������������������������������������������������͸');
      writeln('�         Lan�amento de Proj�teis     -     PROJETO FINAL - FNC232            �');
      writeln('�����������������������������������������������������������������������������͵');
      writeln('�                                   �                                         �');
      writeln('�   Caracter�sticas do Proj�til     �     Caracter�sticas do Meio             �');
      writeln('�                                   �                                         �');
      writeln('�   Massa              =            �     Densidade          =                �');
      writeln('�   Di�metro           =            �     Velocidade do Som  =                �');
      writeln('�   Velocidade Inicial =            �     Gravidade          =                �');
      writeln('�                                   �                                         �');
      writeln('�����������������������������������������������������������������������������Ĵ');
      writeln('�                                   �                                         �');
      writeln('�   Caracter�sticas do Lan�amento   �                                         �');
      writeln('�                                   �                                         �');
      writeln('�   Alcance            =            �                                         �');
      writeln('�   Faixa de Erro      =            �                                         �');
      writeln('�                                   �                                         �');
      writeln('�����������������������������������������������������������������������������Ĵ');
      writeln('� MENSAGEM -                                                                  �');
      writeln('�����������������������������������������������������������������������������;');

      { Pede dados necessarios ao processo. }
      mensagem('Insira os dados do proj�til ...',TRUE);
      gotoxy(26,7); read(massa);

      { Se deseja encerrar nao continua a pedir os dados restantes. }
      if massa<>0.0 then
      begin

         gotoxy(26,8); read(diametro);
         gotoxy(26,9); read(Vo);
         mensagem('Insira os dados do lan�amento ...',TRUE);
         gotoxy(26,15); read(alcance);
         gotoxy(26,16); read(epslon);
         mensagem('Insira os dados do meio ...',TRUE);
         gotoxy(64,7); read(ro);
         gotoxy(64,8); read(Vsom);
         gotoxy(64,9); read(gravidade);

         mensagem('Buscando �ngulos ...',TRUE);

         { Busca angulo a partir de 90 graus. }
         last:=pi/2;
         lastest:=pi/2;
         ltiro:=-1;
         letiro:=-1;
         mtiro:=-1;
         porcima:=achangulo(pi/2,-pi/40,teta1,tempo1);

         { Busca angulo a partir de 0 graus. }
         last:=0.0;
         lastest:=0.0;
         ltiro:=-1.0;
         letiro:=-1.0;
         mtiro:=-1.0;
         porbaixo:=achangulo(0.0,pi/40,teta2,tempo2);

         { Da resposta do disparo. }
         if porcima then traca(teta1,tempo1,0);
         if porbaixo then traca(teta2,tempo2,10);
         if not (porcima or porbaixo) then mensagem('Alcance n�o pode ser atingido !',TRUE);

         { Espera usuario teclar qualquer coisa. }
         teclaespera:=readkey;
         closegraph;
         clrscr;

      end;

   until (massa=0.0);

end.