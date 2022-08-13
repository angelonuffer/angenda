<template>
  <span class="q-gutter-y-md">
    <q-list bordered separator class="rounded-borders">
      <template v-for="[chave, valor] in Object.entries(objeto)" :key="chave">
        <valor :chave="chave" :valor="valor" @ver="ver($event.nome, $event.id)" @modificar="modificar(chave, $event)" @deletar="deletar(chave)" />
      </template>
    </q-list>
  </span>
  <adicionar-propriedade :ícones="ícones" ref="adicionarPropriedade" @adicionar="adicionar($event)" />
  <q-page-sticky position="bottom-right" :offset="[18, 18]">
    <q-btn fab icon="add" color="primary" @click="$refs.adicionarPropriedade.diálogo = true" />
  </q-page-sticky>
</template>

<script>
  import { ícones, objetoAtual, iniciado, obter, modificar, deletar } from '../bancoDeDados.js'
  import AdicionarPropriedade from './AdicionarPropriedade.vue'
  import Valor from './Valor.vue'

  export default {
    emits: ['ver'],
    components: {
      AdicionarPropriedade,
      Valor,
    },
    data() {
      return {
        ícones,
        objeto: {},
      }
    },
    created() {
      iniciado.then(() => obter(0).then(o => this.objeto = o))
    },
    methods: {
      adicionar(propriedade) {
        propriedade.valor = new window[propriedade.tipo]().valueOf()
        this.objeto[propriedade.nome] = propriedade.valor
        modificar(propriedade.nome, propriedade.valor).then(id => this.objeto[propriedade.nome].id = id)
      },
      modificar(chave, valor) { modificar(chave, valor) },
      deletar(chave) {
        delete this.objeto[chave]
        deletar(chave)
      },
      ver(nome, id) {
        this.$emit('ver', {
          ícone: 'emoji_objects',
          nome,
          id,
        })
        this.verId(id)
        objetoAtual.id = id
      },
      verId(id) {
        obter(id).then(o => this.objeto = o)
      },
    },
  }
</script>
