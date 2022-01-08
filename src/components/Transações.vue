<template>
  <md-content style="max-width: 500px">
    <md-dialog :md-active.sync="abrir_diálogo_adicionar_transação">
      <md-dialog-title>{{ editando_transação ? "Editar" : "Adicionar" }} transação</md-dialog-title>
      <md-datepicker v-model="data"></md-datepicker>
      <md-field>
        <label>Descrição</label>
        <md-input v-model="descrição"></md-input>
      </md-field>
      <md-field>
        <label>Valor</label>
        <span class="md-prefix">R$</span>
        <md-input v-model="valor" type="number" step="0.01"></md-input>
      </md-field>
      <md-checkbox v-model="repetir_mensalmente">Repetir mensalmente</md-checkbox>
      <md-dialog-actions>
        <md-button class="md-primary" @click="abrir_diálogo_adicionar_transação = false">Cancelar</md-button>
        <md-button class="md-primary" @click="adicionar_transação()">Ok</md-button>
      </md-dialog-actions>
    </md-dialog>
    <md-toolbar>
      <md-menu>
        <md-button md-menu-trigger>{{ mês }}</md-button>
        <md-menu-content>
          <md-menu-item v-for="(possível_mês, i) in possíveis_meses" :key="i" @click="mês = possível_mês">
            <span>{{ possível_mês }}</span>
          </md-menu-item>
        </md-menu-content>
      </md-menu>
      <div class="md-toolbar-section-end">
        <md-button class="md-icon-button" @click="editando_transação = false; abrir_diálogo_adicionar_transação = true">
          <md-icon>add</md-icon>
        </md-button>
      </div>
    </md-toolbar>
    <md-list v-for="(dia, i) in dias" :key="i">
      <md-subheader style="background-color: lightgray">{{ dia.id }}</md-subheader>
      <md-list-item v-for="(transação, j) in dia.transações.filter(t => t.mês === mês)" :key="j">
        <md-checkbox style="display: none"></md-checkbox>
        <md-checkbox v-if="transação.data <= agora" class="confirmar_transação" v-model="transação.realizada" @change="atualizar_transação(transação)"></md-checkbox>
        <span class="md-list-item-text">{{ transação.descrição }}</span>
        <span :class="transação.valor < 0 ? 'valor_negativo' : ''">{{ brl(transação.valor) }}</span>
        <md-menu>
          <md-button class="md-icon-button md-list-action" md-menu-trigger>
            <md-icon>more_vert</md-icon>
          </md-button>
          <md-menu-content>
            <md-menu-item @click="editar_transação(transação)">
              <md-icon>edit</md-icon>
              <span>Editar</span>
            </md-menu-item>
            <md-menu-item @click="remover_transação(transação)">
              <md-icon>delete</md-icon>
              <span>Remover</span>
            </md-menu-item>
          </md-menu-content>
        </md-menu>
      </md-list-item>
      <md-list-item>
        <span class="md-list-item-text"></span>
        <span>{{ brl(saldo_dia(dia)) }}</span>
      </md-list-item>
    </md-list>
    <md-list>
      <md-subheader style="background-color: lightgray">Saldo</md-subheader>
      <md-list-item>
        <span>Atual</span>
        <span :class="saldo_atual < 0 ? 'valor_negativo' : ''">{{ brl(saldo_atual) }}</span>
      </md-list-item>
      <md-list-item>
        <span>Inicial</span>
        <span :class="saldo_inicial < 0 ? 'valor_negativo' : ''">{{ brl(saldo_inicial) }}</span>
      </md-list-item>
      <md-list-item>
        <span>Final</span>
        <span :class="saldo_final < 0 ? 'valor_negativo' : ''">{{ brl(saldo_final) }}</span>
      </md-list-item>
    </md-list>
    <md-list>
      <md-subheader style="background-color: lightgray">Alterações no mês</md-subheader>
      <md-list-item>
        <span>Receitas</span>
        <span :class="receitas < 0 ? 'valor_negativo' : ''">{{ brl(receitas) }}</span>
      </md-list-item>
      <md-list-item>
        <span>Despesas mensais</span>
        <span :class="despesas_mensais < 0 ? 'valor_negativo' : ''">{{ brl(despesas_mensais) }}</span>
      </md-list-item>
      <md-list-item>
        <span>Despesas esporádicas</span>
        <span :class="despesas_esporádicas < 0 ? 'valor_negativo' : ''">{{ brl(despesas_esporádicas) }}</span>
      </md-list-item>
      <md-list-item>
        <span>Variação do mês</span>
        <span :class="variação < 0 ? 'valor_negativo' : ''">{{ brl(variação) }}</span>
      </md-list-item>
    </md-list>
  </md-content>
</template>

<style>
  .valor_negativo {
    color: red;
  }
  .confirmar_transação {
    margin-right: 8px !important;
  }
</style>

<script>
  import db from "../angenda_db.js"
  const agora = new Date()
  const mês = agora.getFullYear() + "-" + (agora.getMonth() + 1).toString().padStart(2, 0)
  const brl = new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' })
  export default {
    data: () => ({
      agora,
      mês,
      abrir_diálogo_adicionar_transação: false,
      editando_transação: false,
      data: agora,
      descrição: "",
      valor: 0,
      repetir_mensalmente: false,
      transações: [],
      realizada: [],
    }),
    created: function () {
      db.ao_adicionar("transações", transação => this.transações.push(transação))
      db.ao_remover("transações", id => this.transações.find((transação, i) => {
        if (transação.id === id) {
          this.transações.splice(i, 1)
          return true
        }
      }))
    },
    computed: {
      possíveis_meses: function () {
        return Array.from(new Set(this.transações.map(t => t.mês))).sort()
      },
      dias: function () {
        return this.transações.reduce((dias, t) => {
          if (t.mês !== this.mês) return dias
          const id = t.data.getDate().toString().padStart(2, 0) + " - " + [
            "DOM", "SEG", "TER", "QUA", "QUI", "SEX", "SAB",
          ][t.data.getDay()]
          for (var i = 0; i < dias.length; i++) {
            if (dias[i].id > id) {
              dias.splice(i, 0, {
                id,
                transações: [t],
              })
              return dias
            }
            if (dias[i].id === id) {
              dias[i].transações.push(t)
              return dias
            }
          }
          dias.push({
            id,
            transações: [t],
          })
          return dias
        }, [])
      },
      saldo_atual: function () {
        return this.transações.filter(t => t.realizada).map(t => t.valor).reduce((a, b) => a + b, 0)
      },
      saldo_inicial: function () {
        return this.transações.filter(t => t.mês < this.mês).map(t => t.valor).reduce((a, b) => a + b, 0)
      },
      saldo_final: function () {
        return this.saldo_inicial + this.variação
      },
      receitas: function () {
        return this.transações.filter(t => t.mês === this.mês && t.valor > 0).map(t => t.valor).reduce((a, b) => a + b, 0)
      },
      despesas_mensais: function () {
        return this.transações.filter(t => t.mês === this.mês && t.valor < 0 && t.repetir_mensalmente).map(t => t.valor).reduce((a, b) => a + b, 0)
      },
      despesas_esporádicas: function () {
        return this.transações.filter(t => t.mês === this.mês && t.valor < 0 && ! t.repetir_mensalmente).map(t => t.valor).reduce((a, b) => a + b, 0)
      },
      variação: function () {
        return this.receitas + this.despesas_mensais + this.despesas_esporádicas
      },
    },
    methods: {
      adicionar_transação: function () {
        if (this.editando_transação) {
          this.editando_transação.data = this.data
          this.editando_transação.descrição = this.descrição
          this.editando_transação.valor = parseFloat(this.valor)
          this.editando_transação.repetir_mensalmente = this.repetir_mensalmente
          this.editando_transação.mês = this.data.getFullYear() + "-" + (this.data.getMonth() + 1).toString().padStart(2, 0)
          db.atualizar("transações", this.editando_transação)
        } else {
          db.adicionar("transações", {
            data: this.data,
            descrição: this.descrição,
            valor: parseFloat(this.valor),
            repetir_mensalmente: this.repetir_mensalmente,
            realizada: null,
            repetida: false,
            mês: this.data.getFullYear() + "-" + (this.data.getMonth() + 1).toString().padStart(2, 0),
          })
        }
        this.data = agora
        this.descrição = ""
        this.valor = 0
        this.repetir_mensalmente = false
        this.abrir_diálogo_adicionar_transação = false
      },
      editar_transação: function (transação) {
        this.editando_transação = transação
        this.data = new Date(transação.data)
        this.descrição = transação.descrição
        this.valor = transação.valor
        this.repetir_mensalmente = transação.repetir_mensalmente
        this.abrir_diálogo_adicionar_transação = true
      },
      remover_transação: transação => db.remover("transações", transação.id),
      atualizar_transação: function (transação) {
        if (transação.repetir_mensalmente && ! transação.repetida) {
          this.data = new Date(transação.data)
          this.data.setMonth(this.data.getMonth() + 1)
          this.descrição = transação.descrição
          this.valor = transação.valor
          this.repetir_mensalmente = true
          this.adicionar_transação()
          transação.repetida = true
        }
        db.atualizar("transações", transação)
      },
      brl: valor => brl.format(valor),
      saldo_dia: function (dia) { return this.transações.filter(t => t.data <= dia.transações[0].data).map(t => t.valor).reduce((a, b) => a + b, 0) },
    },
  }
</script>
