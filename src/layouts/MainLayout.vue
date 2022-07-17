<template>
  <q-layout view="lHh Lpr lFf">
    <q-header elevated>
      <q-toolbar>
        <q-btn flat @click="menu = !menu" round dense icon="menu" />
        <q-toolbar-title>
          Angenda
        </q-toolbar-title>
      </q-toolbar>
    </q-header>
    <q-drawer v-model="menu" elevated>
      <q-list>
        <q-item clickable v-ripple :active="página === 'início'" @click="página = 'início'">
          <q-item-section avatar>
            <q-icon name="home" />
          </q-item-section>
          <q-item-section>
            Início
          </q-item-section>
        </q-item>
        <q-item clickable v-ripple :active="página === 'classes'" @click="página = 'classes'">
          <q-item-section avatar>
            <q-icon name="class" />
          </q-item-section>
          <q-item-section>
            Classes
          </q-item-section>
        </q-item>
        <q-item clickable v-ripple :active="página === 'lixeira'" @click="página = 'lixeira'">
          <q-item-section avatar>
            <q-icon name="delete" />
          </q-item-section>
          <q-item-section>
            Lixeira
          </q-item-section>
        </q-item>
      </q-list>
    </q-drawer>
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
            <q-item clickable v-ripple v-for="(objeto, i) in objetos" :key="objeto.nome" @click="() => { if (objeto.classe === I_EMBUTIDOS.Lista || objeto.classe === I_EMBUTIDOS.Objeto) endereço.push(objeto) }">
              <q-item-section avatar>
                <q-icon :name="objeto.ícone" />
              </q-item-section>
              <q-item-section v-if="objeto.classe === I_EMBUTIDOS.Objeto">
                <q-item-label>{{ objeto.nome }}</q-item-label>
              </q-item-section>
              <q-item-section v-if="objeto.classe === I_EMBUTIDOS.Lista">
                <q-item-label>{{ objeto.nome }}</q-item-label>
              </q-item-section>
              <q-item-section v-if="objeto.classe === I_EMBUTIDOS.Texto">
                <q-input @click.stop v-model="objeto.valor" :label="objeto.nome" />
              </q-item-section>
              <q-item-section v-if="objeto.classe === I_EMBUTIDOS.Número">
                <q-input type="number" @click.stop v-model.number="objeto.valor" :label="objeto.nome" />
              </q-item-section>
              <q-item-section v-if="objeto.classe === I_EMBUTIDOS.Lógico">
                <q-toggle v-model="objeto.valor" :label="objeto.nome" />
              </q-item-section>
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
  <q-dialog v-model="diálogo_adicionar_objeto" @hide="nome_da_propriedade = ''">
    <q-card>
      <q-bar>
        <span v-if="objeto_atual_é(I_EMBUTIDOS.Lista)">Adicionar objeto</span>
        <span v-if="objeto_atual_é(I_EMBUTIDOS.Objeto)">Adicionar propriedade</span>
      </q-bar>
      <q-card-section class="q-gutter-md">
        <q-input v-if="objeto_atual_é(I_EMBUTIDOS.Objeto)" v-model="nome_da_propriedade" label="Nome" autofocus />
        <q-list bordered separator>
          <template v-for="(objeto, i) in EMBUTIDOS">
            <q-item clickable v-ripple v-if="objeto.classe === undefined" :active="classe === i" @click="classe = i">
              <q-item-section avatar>
                <q-icon :name="objeto.ícone" />
              </q-item-section>
              <q-item-section>{{ objeto.nome }}</q-item-section>
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
  import { defineComponent, ref, toRaw } from 'vue'
  import { setCssVar } from 'quasar'
  setCssVar('primary', '#cd0000')
  let EMBUTIDOS = [
    {
      ícone: "emoji_objects",
      nome: "Objeto",
      valor_padrão: {},
    },
    {
      ícone: "list",
      nome: "Lista",
      valor_padrão: [],
    },
    {
      ícone: "abc",
      nome: "Texto",
      valor_padrão: "",
    },
    {
      ícone: "123",
      nome: "Número",
      valor_padrão: 0,
    },
    {
      ícone: "toggle_on",
      nome: "Lógico",
      valor_padrão: false,
    },
  ]
  let I_EMBUTIDOS = Object.fromEntries(EMBUTIDOS.map((t, i) => [t.nome, i]))
  EMBUTIDOS.push(
    {
      classe: I_EMBUTIDOS.Lista,
      nome: "raiz",
      valor: [],
    },
    {
      classe: I_EMBUTIDOS.Lista,
      nome: "lixeira",
      valor: [],
    },
  )
  I_EMBUTIDOS = Object.fromEntries(EMBUTIDOS.map((t, i) => [t.nome, i]))
  export default defineComponent({
    data() {
      return {
        diálogo_adicionar_objeto: false,
        classe: I_EMBUTIDOS.Objeto,
        menu: false,
        página: "início",
        endereço: [],
        objetos: [],
        nome_da_propriedade: "",
      }
    },
    computed: {
      i_objeto_atual() {
        if (this.endereço.length === 0) return this.I_EMBUTIDOS.raiz
        return this.endereço.at(-1).id
      },
    },
    created() {
      this.EMBUTIDOS = EMBUTIDOS
      this.I_EMBUTIDOS = I_EMBUTIDOS
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
          classe: this.classe,
          valor: this.EMBUTIDOS[this.classe].valor_padrão,
        }).onsuccess = e => {
          const i_objeto = e.target.result
          objetos.get(this.i_objeto_atual).onsuccess = e => {
            if (this.objeto_atual_é(I_EMBUTIDOS.Lista)) {
              e.target.result.valor.push(i_objeto)
            }
            if (this.objeto_atual_é(I_EMBUTIDOS.Objeto)) {
              e.target.result.valor[this.nome_da_propriedade] = i_objeto
            }
            objetos.put(e.target.result, this.i_objeto_atual).onsuccess = e => {
              let nome
              if (this.objeto_atual_é(I_EMBUTIDOS.Lista)) {
                nome = this.EMBUTIDOS[this.classe].nome
              }
              if (this.objeto_atual_é(I_EMBUTIDOS.Objeto)) {
                nome = this.nome_da_propriedade
              }
              this.objetos.push({
                classe: this.classe,
                ícone: this.EMBUTIDOS[this.classe].ícone,
                nome,
                id: i_objeto,
                valor: this.EMBUTIDOS[this.classe].valor_padrão,
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
      objeto_atual_é(classe) {
        return this.objeto_é(this.endereço.at(-1) || this.EMBUTIDOS[this.I_EMBUTIDOS.raiz], classe)
      },
      objeto_é(objeto, classe) {
        return objeto.classe === classe
      },
    },
    watch: {
      endereço: {
        handler() {
          this.objetos = []
          const objetos = this.db.transaction(['objetos'], 'readonly').objectStore('objetos')
          objetos.get(this.i_objeto_atual).onsuccess = e => {
            if (this.objeto_atual_é(this.I_EMBUTIDOS.Lista)) {
              e.target.result.valor.forEach(i_objeto => {
                objetos.get(i_objeto).onsuccess = e => {
                  const objeto = e.target.result
                  objetos.get(objeto.classe).onsuccess = e => {
                    this.objetos.push({
                      classe: objeto.classe,
                      ícone: e.target.result.ícone,
                      nome: this.EMBUTIDOS[objeto.classe].nome,
                      id: i_objeto,
                      valor: objeto.valor,
                    })
                  }
                }
              })
            }
            if (this.objeto_atual_é(this.I_EMBUTIDOS.Objeto)) {
              Object.entries(e.target.result.valor).forEach(([nome, i_objeto]) => {
                objetos.get(i_objeto).onsuccess = e => {
                  const objeto = e.target.result
                  objetos.get(objeto.classe).onsuccess = e => {
                    this.objetos.push({
                      classe: objeto.classe,
                      ícone: e.target.result.ícone,
                      nome: nome,
                      id: i_objeto,
                      valor: objeto.valor,
                    })
                  }
                }
              })
            }
          }
        },
        deep: true,
      },
      objetos: {
        handler() {
          const objetos = this.db.transaction(['objetos'], 'readwrite').objectStore('objetos')
          this.objetos.forEach(objeto => {
            objetos.get(objeto.id).onsuccess = e => {
              e.target.result.valor = toRaw(objeto.valor)
              objetos.put(e.target.result, objeto.id)
            }
          })
        },
        deep: true,
      },
    },
  })
</script>
