<template>
  <q-item :clickable="valor.constructor === Object" v-ripple="valor.constructor === Object" @click="$emit('ver', { nome: chave, id: valor.id })">
    <span class="coluna cresce">
      <span class="linha">
        <q-item-section avatar>
          <q-icon :name="ícones[valor.constructor.name]" />
        </q-item-section>
        <q-item-section style="flex-grow: 1">
          <q-item-label v-if="valor.constructor === Object">{{ chave }}</q-item-label>
          <q-item-label v-if="valor.constructor === Array">{{ chave }}</q-item-label>
          <q-input @click.stop v-model="valor" :label="chave" @update:model-value="$emit('modificar', $event)" v-if="valor.constructor === String" />
          <q-input type="number" @click.stop v-model.number="valor" :label="chave" @update:model-value="$emit('modificar', $event)" v-if="valor.constructor === Number" />
          <q-toggle v-model="valor" :label="chave" @update:model-value="$emit('modificar', $event)" v-if="valor.constructor === Boolean" />
        </q-item-section>
        <q-item-section side>
          <q-btn flat round icon="more_vert" @click.stop>
            <q-menu>
              <q-list>
                <q-item clickable v-ripple v-close-popup @click="$refs.adicionarItem.diálogo = true" v-if="valor.constructor === Array">
                  <q-item-section avatar>
                    <q-icon name="add" />
                  </q-item-section>
                  <q-item-section>
                    Adicionar
                  </q-item-section>
                </q-item>
                <q-item clickable v-ripple v-close-popup @click="$emit('deletar')">
                  <q-item-section avatar>
                    <q-icon name="delete" />
                  </q-item-section>
                  <q-item-section>
                    Deletar
                  </q-item-section>
                </q-item>
              </q-list>
            </q-menu>
          </q-btn>
        </q-item-section>
        <adicionar-item :ícones="ícones" ref="adicionarItem" @adicionar="adicionar($event)" />
        </span>
        <q-item-section>
        <template v-if="valor.constructor === Array">
          <q-item-label caption>
            <q-list bordered separator class="rounded-borders">
              <template v-for="(item, i) in valor" :key="i">
                <valor :chave="chave + '[' + i.toString() + ']'" :valor="item" @modificar="modificar(i, $event)" @deletar="deletar(i)" />
              </template>
            </q-list>
          </q-item-label>
        </template>
      </q-item-section>
    </span>
  </q-item>
</template>

<style scoped>
  .coluna {
    display: flex;
    flex-direction: column;
  }
  .linha {
    display: flex;
    flex-direction: row;
  }
  .cresce {
    flex-grow: 1;
  }
</style>

<script>
  import { ícones } from '../bancoDeDados.js'
  import AdicionarItem from './AdicionarItem.vue'

  export default {
    props: ['chave', 'valor'],
    emits: ['ver', 'modificar', 'deletar'],
    components: {
      AdicionarItem,
    },
    data() {
      return {
        ícones,
      }
    },
    methods: {
      adicionar(item) {
        this.valor.push(new window[item.tipo]().valueOf())
        this.$emit('modificar', JSON.parse(JSON.stringify(this.valor)))
      },
      modificar(i, valor) {
        this.valor[i] = valor
        this.$emit('modificar', JSON.parse(JSON.stringify(this.valor)))
      },
      deletar(i) {
        this.valor.splice(i, 1)
        this.$emit('modificar', JSON.parse(JSON.stringify(this.valor)))
      },
    },
  }
</script>
