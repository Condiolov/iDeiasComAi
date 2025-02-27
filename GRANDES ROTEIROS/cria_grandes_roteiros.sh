#!/bin/bash

NOME_JSON="temp.json"
MODELO="llama3.2"

>"historia_final.txt"

[[ $@ == "" ]] && echo "coloque numero de capitulo e tema" && exit

TEMA="$@"
[[ "$@" =~ [0-9]+ ]] && numero=${BASH_REMATCH[0]}
# exit

gera_json() {
   [[ $numero > 10 ]] && prompt="PROMPT100.txt" || prompt="PROMPT.txt"

   ollama run gemma2 "$(cat $prompt) $TEMA" >temp.json
   sed -i '/^```json$/d; /^```$/d' $NOME_JSON
   json_content=$(cat $NOME_JSON)
}

# Carrega o conteúdo do arquivo JSON em uma variável
gera_json

for ((x = 1; ; x++)); do
   if ! echo "$json_content" | jq empty >/dev/null 2>&1; then
      echo "JSON ainda não esta bom, gerando outro..."
      gera_json
   else
      break
   fi
done
ollama stop gemma2
# Extrai e printa o resumo
RESUMO=$(echo "$json_content" | jq -r '.Resumo')
# echo "Resumo: $resumo"
# echo
sleep 5
# Loop for para printar os capítulos
for ((capitulo_numero = 1; ; capitulo_numero++)); do
   RESUMO_CAPITULO=$(echo "$json_content" | jq -r --arg cap "capitulo$capitulo_numero" '.[$cap]')

   # Verifica se o capítulo existe
   if [[ "$RESUMO_CAPITULO" == "null" ]]; then
      #       echo "Fim dos capítulos."
      break
   fi

   #    echo "RESUMO----> $RESUMO"
   #    echo "RESUMO_CAPITULO----> $RESUMO_CAPITULO"
   #    PROMPT_CAPITULO=$(sed -e "s/{RESUMO}/$RESUMO/g" -e "s/{RESUMO_CAPITULO}/$RESUMO_CAPITULO/g" PROMPT_CAPITULO.txt)
   PROMPT_CAPITULO=$(awk -v RESUMO="$RESUMO" -v RESUMO_CAPITULO="$RESUMO_CAPITULO" '
    { gsub(/{RESUMO}/, RESUMO); gsub(/{RESUMO_CAPITULO}/, RESUMO_CAPITULO); print }
' PROMPT_CAPITULO.txt)
   echo "capitulo_numero----> $capitulo_numero"
   ollama run $MODELO "$(echo $PROMPT_CAPITULO)" >>"historia_final.txt"

   # Printa o capítulo
   #    echo "--->Capítulo $capitulo_numero: $capitulo"
   #    echo
   #    exit
done

ollama stop $MODELO
