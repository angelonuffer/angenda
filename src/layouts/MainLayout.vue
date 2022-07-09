<template>
  <q-layout view="lHh Lpr lFf">
    <q-header elevated>
      <q-toolbar>
        <q-toolbar-title>
          Angenda
        </q-toolbar-title>
      </q-toolbar>
    </q-header>
    <q-page-container>
      <q-page padding>
        <span>
          <q-btn icon="home" @click="endereço = []" />
          <template v-for="(objeto, i) in endereço">
            <q-icon name="arrow_right" />
            <q-btn :icon="objeto.ícone" no-caps @click="endereço.splice(i + 1)">{{ objeto.nome }}</q-btn>
          </template>
        </span>
        <span class="q-gutter-y-md">
          <q-list bordered separator class="rounded-borders">
            <q-item clickable v-ripple v-for="(objeto, i) in objetos" :key="objeto.nome" @click="endereço.push(objeto)">
              <q-item-section avatar>
                <q-icon :name="objeto.ícone" />
              </q-item-section>
              <q-item-section>{{ objeto.nome }}</q-item-section>
              <q-item-section side>
                <q-btn flat round icon="more_vert" @click.stop>
                  <q-menu>
                    <q-list>
                      <q-item clickable v-ripple @click="deletar(i)">
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
            </q-item>
          </q-list>
        </span>
        <q-page-sticky position="bottom-right" :offset="[18, 18]">
          <q-btn fab icon="add" color="primary" @click="diálogo_adicionar_objeto = true" />
        </q-page-sticky>
      </q-page>
    </q-page-container>
  </q-layout>
  <q-dialog v-model="diálogo_adicionar_objeto" @hide="nome_do_novo_objeto = ''">
    <q-card>
      <q-bar>
        <span>Adicionar objeto</span>
      </q-bar>
      <q-card-section>
        <q-input v-model="nome_do_novo_objeto" label="Nome" autofocus />
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
  import { defineComponent, ref } from 'vue'
  import { setCssVar } from 'quasar'
  setCssVar('primary', '#cd0000')
  export default defineComponent({
    data() {
      return {
        diálogo_adicionar_objeto: false,
        nome_do_novo_objeto: "",
        endereço: [],
        objetos: [],
      }
    },
    computed: {
      i_objeto_atual() {
        if (this.endereço.length === 0) return this.I_EMBUTIDOS.raiz
        return this.endereço.at(-1).id
      },
    },
    created() {
      this.EMBUTIDOS = [
        {
          ícone: "emoji_objects",
          nome: "Objeto",
        },
        {
          ícone: "list",
          nome: "Lista",
        },
      ]
      this.I_EMBUTIDOS = Object.fromEntries(this.EMBUTIDOS.map((t, i) => [t.nome, i]))
      this.EMBUTIDOS.push(
        {
          classe: this.I_EMBUTIDOS.Lista,
          nome: "raiz",
          valor: [],
        },
        {
          classe: this.I_EMBUTIDOS.Lista,
          nome: "lixeira",
          valor: [],
        },
      )
      this.I_EMBUTIDOS = Object.fromEntries(this.EMBUTIDOS.map((t, i) => [t.nome, i]))
      const r = indexedDB.open(location.pathname, 1)
      r.onupgradeneeded = e => {
        const db = e.target.result
        const objetos = db.createObjectStore('objetos', { autoIncrement: true })
        this.EMBUTIDOS.forEach((objeto, i) => objetos.add(objeto, i))
      }
      r.onsuccess = e => {
        this.db = e.target.result
        this.endereço = []
      }
    },
    methods: {
      adicionar() {
        const objetos = this.db.transaction(['objetos'], 'readwrite').objectStore('objetos')
        objetos.add({
          classe: this.I_EMBUTIDOS.Lista,
          nome: this.nome_do_novo_objeto,
          valor: [],
        }).onsuccess = e => {
          const i_objeto = e.target.result
          objetos.get(this.i_objeto_atual).onsuccess = e => {
            e.target.result.valor.push(i_objeto)
            objetos.put(e.target.result, this.i_objeto_atual).onsuccess = e => {
              this.objetos.push({
                ícone: this.EMBUTIDOS[this.I_EMBUTIDOS.Lista].ícone,
                nome: this.nome_do_novo_objeto,
                id: i_objeto,
              })
            }
          }
        }
      },
      deletar(i) {
        const objetos = this.db.transaction(['objetos'], 'readwrite').objectStore('objetos')
        objetos.get(this.I_EMBUTIDOS.lixeira).onsuccess = e => {
          e.target.result.valor.push({
            pai: this.i_objeto_atual,
            id: this.objetos[i].id,
          })
          objetos.put(e.target.result, this.I_EMBUTIDOS.lixeira).onsuccess = e => {
            objetos.get(this.i_objeto_atual).onsuccess = e => {
              e.target.result.valor.splice(i, 1)
              objetos.put(e.target.result, this.i_objeto_atual).onsuccess = e => {
                this.objetos.splice(i, 1)
              }
            }
          }
        }
      },
    },
    watch: {
      endereço: {
        handler(novo) {
        this.objetos = []
          const objetos = this.db.transaction(['objetos'], 'readonly').objectStore('objetos')
          objetos.get(this.i_objeto_atual).onsuccess = e => {
            e.target.result.valor.forEach(i_objeto => {
              objetos.get(i_objeto).onsuccess = e => {
                const objeto = e.target.result
                objetos.get(objeto.classe).onsuccess = e => {
                  this.objetos.push({
                    ícone: e.target.result.ícone,
                    nome: objeto.nome,
                    id: i_objeto,
                  })
                }
              }
            })
          }
        },
        deep: true,
      },
    },
  })
</script>
