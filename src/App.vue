<template>
  <md-content id="coluna">
    <transacoes ref="transações" style="display: none"></transacoes>
    <md-dialog :md-active.sync="mostre_diálogo_transações">
      <div style="overflow-y: scroll">
        <transacoes></transacoes>
      </div>
    </md-dialog>
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
      mostre_diálogo_transações: false,
    }),
    mounted () { this.m = true },
    computed: {
      saldo_atual () { return this.m ? this.$refs.transações.saldo_atual : 0 }
    },
    methods: {
      brl (valor) { return this.m ? this.$refs.transações.brl(valor) : "" },
    },
  }
</script>
