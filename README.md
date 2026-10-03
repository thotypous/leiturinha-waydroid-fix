# Fix do Leiturinha no Waydroid

Após instalar ou atualizar o XAPK do Leiturinha, execute:

```bash
~/leiturinha-waydroid-fix/aplicar-fix.sh
```

O Waydroid deve estar aberto e com o contêiner em execução. O script localiza a
instalação atual, extrai as bibliotecas ARM64 para o diretório consultado pelo
SoLoader do React Native, corrige as permissões e reinicia apenas o aplicativo.

Uma atualização ou reinstalação pode criar um novo diretório para o pacote;
por isso, o script redetecta o caminho a cada execução.

## Orientação e uso da tela inteira

O Leiturinha solicita orientação retrato na tela inicial. Em uma tela de
1366×736, o Android 13 aplica *letterboxing* por orientação fixa e limita essa
tela a uma faixa vertical central. O diagnóstico aparece no WindowManager
como:

```text
requestedOrientation=SCREEN_ORIENTATION_PORTRAIT
areBoundsLetterboxed=true
letterboxReason=FIXED_ORIENTATION
```

Foi ativado no Waydroid o override global que ignora solicitações de orientação:

```bash
sudo -i
waydroid shell -- wm set-ignore-orientation-request true
```

A tela inicial ainda pode permanecer em retrato. Ao abrir um livro, o aplicativo
muda seu estado de orientação e o leitor passa a ocupar a tela inteira.

Para consultar o estado atual:

```bash
sudo -i
waydroid shell -- wm get-ignore-orientation-request
```

Para reverter o override:

```bash
sudo -i
waydroid shell -- wm set-ignore-orientation-request false
```

Esse ajuste é global para o display do Waydroid e pode influenciar a orientação
de outros aplicativos Android.
