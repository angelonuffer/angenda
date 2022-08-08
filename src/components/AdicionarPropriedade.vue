<template>
  <q-dialog v-model="diálogo" @hide="">
    <q-card>
      <q-bar>
        <span>Adicionar propriedade</span>
      </q-bar>
        <q-card-section class="q-gutter-md">
          <q-input v-model="nome" label="Nome" autofocus />
          <q-list bordered separator>
            <template v-for="[tipo, nome] in Object.entries(nomes)">
              <q-item clickable v-ripple :active="tipo === tipoSelecionado" @click="tipoSelecionado = tipo">
                <q-item-section avatar>
                  <q-icon :name="ícones[tipo]" />
                </q-item-section>
                <q-item-section>{{ nome }}</q-item-section>
              </q-item>
            </template>
          </q-list>
        </q-card-section>
        <q-separator />
      <q-card-actions align="right">
        <q-btn flat color="primary" label="OK" v-close-popup @click="adicionar()" />
        <q-btn flat color="primary" label="CANCELAR" v-close-popup />
      </q-card-actions>
    </q-card>
  </q-dialog>
</template>

<script>
  import { ícones, nomes, adicionar } from '../bancoDeDados.js'

  export default {
    data() {
      return {
        ícones,
        nomes,
        nome: '',
        tipoSelecionado: 'Object',
        diálogo: false,
      }
    },
    methods: {
      adicionar() {
        this.$emit('adicionar', {
          nome: this.nome,
          tipo: this.tipoSelecionado,
        })
        this.nome = ''
        this.tipoSelecionado = 'Object'
      },
    },
  }
</script>
