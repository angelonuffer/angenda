<template>
  <md-content id="coluna">
    <transacoes ref="transações" style="display: none"></transacoes>
    <md-dialog :md-active.sync="mostre_diálogo_versões">
      <div style="overflow-y: scroll">
        <md-dialog-title>Baixar dados de outra versão</md-dialog-title>
        <md-list>
          <md-list-item v-for="(versão, i) in versões" v-bind:key="i" @click="baixar_da_versão(versão)">
            <span class="md-list-item-text">{{ versão }}</span>
          </md-list-item>
        </md-list>
      </div>
    </md-dialog>
    <md-dialog :md-active.sync="mostre_diálogo_transações">
      <div style="overflow-y: scroll">
        <transacoes></transacoes>
      </div>
    </md-dialog>
    <md-card>
      <md-card-content>
        <md-list>
          <md-list-item @click="mostre_diálogo_versões = true">
            <span class="md-list-item-text">Versão</span>
            <span>{{ versão }}</span>
          </md-list-item>
        </md-list>
      </md-card-content>
    </md-card>
    <md-card>
      <md-card-content>
        <md-list>
          <md-list-item @click="mostre_diálogo_transações = true">
            <span class="md-list-item-text">Saldo atual</span>
            <span :class="saldo_atual < 0 ? 'valor_negativo' : ''">{{ brl(saldo_atual) }}</span>
          </md-list-item>
        </md-list>
      </md-card-content>
    </md-card>
  </md-content>
</template>

<style>
  #coluna {
    max-width: 500px;
    padding: 8px;
    display: flex;
    flex-direction: column;
    gap: 8px;
  }
</style>

<script>
  import Transacoes from "./components/Transações.vue"
  export default {
    components: {
      Transacoes,
    },
    data: () => ({
      m: false,
      mostre_diálogo_versões: false,
      mostre_diálogo_transações: false,
      versão: location.pathname.split("/").at(-1),
      versões: [],
    }),
    mounted () {
      this.m = true
      indexedDB.databases().then(dbs => this.versões = dbs.filter(db => db.name.startsWith("/angenda/") && db.name !== "/angenda/" + this.versão).map(db => db.name.split("/").at(-1)))
    },
    computed: {
      saldo_atual () { return this.m ? this.$refs.transações.saldo_atual : 0 }
    },
    methods: {
      brl (valor) { return this.m ? this.$refs.transações.brl(valor) : "" },
      baixar_da_versão (versão) {
        if (confirm("Baixar todos os dados da versão " + versão + " para a versão " + this.versão + "?")) {
          const outro_db = indexedDB.open("/angenda/" + versão, 1)
          outro_db.onsuccess = () => {
            const db = indexedDB.open(location.pathname, 1)
            db.onsuccess = () => {
              const coleções = [...db.result.objectStoreNames]
              for (var i = 0; i < coleções.length; i++) {
                outro_db.result.transaction([coleções[i]]).objectStore(coleções[i]).openCursor().onsuccess = function (i, evento) {
                  const cursor = evento.target.result
                  if (cursor) {
                    db.result.transaction([coleções[i]], "readwrite").objectStore(coleções[i]).add(cursor.value)
                    cursor.continue()
                  } else {
                    alert("Dados baixados com sucesso.")
                  }
                }.bind(this, i)
              }
            }
          }
        }
        this.mostre_diálogo_versões = false
      },
    },
  }
</script>
